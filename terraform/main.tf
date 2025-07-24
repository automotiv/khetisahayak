# Kheti Sahayak - Azure Infrastructure Deployment
# This Terraform configuration deploys the complete Kheti Sahayak platform on Azure

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend configuration for state management
  backend "azurerm" {
    resource_group_name  = "rg-khetisahayak-tfstate"
    storage_account_name = "sakhetisahayaktfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Configure the Azure Active Directory Provider
provider "azuread" {}

# Data sources
data "azurerm_client_config" "current" {}

# Local variables
locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    CreatedBy   = "Terraform"
    CreatedOn   = formatdate("YYYY-MM-DD", timestamp())
  }

  # Resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Application settings
  app_settings = {
    NODE_ENV                    = var.environment
    DATABASE_URL               = module.database.connection_string
    REDIS_URL                  = module.redis.connection_string
    JWT_SECRET                 = "@Microsoft.KeyVault(VaultName=${module.key_vault.name};SecretName=jwt-secret)"
    STORAGE_ACCOUNT_NAME       = module.storage.account_name
    STORAGE_ACCOUNT_KEY        = "@Microsoft.KeyVault(VaultName=${module.key_vault.name};SecretName=storage-account-key)"
    APPLICATION_INSIGHTS_KEY   = module.monitoring.instrumentation_key
    WEATHER_API_KEY           = "@Microsoft.KeyVault(VaultName=${module.key_vault.name};SecretName=weather-api-key)"
    SMS_API_KEY               = "@Microsoft.KeyVault(VaultName=${module.key_vault.name};SecretName=sms-api-key)"
    PAYMENT_GATEWAY_KEY       = "@Microsoft.KeyVault(VaultName=${module.key_vault.name};SecretName=payment-gateway-key)"
    WEBSITE_NODE_DEFAULT_VERSION = "18-lts"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

# Virtual Network Module
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  vnet_address_space     = var.vnet_address_space
  subnet_address_spaces  = var.subnet_address_spaces
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key_vault"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  cors_allowed_origins = var.cors_allowed_origins
}

# Database Module (PostgreSQL)
module "database" {
  source = "./modules/database"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  subnet_id                    = module.networking.database_subnet_id
  administrator_login          = var.db_admin_username
  administrator_login_password = var.db_admin_password
  sku_name                    = var.db_sku_name
  storage_mb                  = var.db_storage_mb
  backup_retention_days       = var.db_backup_retention_days
  geo_redundant_backup_enabled = var.db_geo_redundant_backup_enabled
}

# Redis Cache Module
module "redis" {
  source = "./modules/redis"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  subnet_id = module.networking.cache_subnet_id
  sku_name  = var.redis_sku_name
  family    = var.redis_family
  capacity  = var.redis_capacity
}

# Container Registry Module
module "container_registry" {
  source = "./modules/container_registry"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  sku = var.acr_sku
}

# App Service Plan Module
module "app_service_plan" {
  source = "./modules/app_service_plan"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  sku_name = var.app_service_sku_name
}

# Backend App Service Module
module "backend_app_service" {
  source = "./modules/app_service"

  resource_group_name   = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  name_prefix          = "${local.name_prefix}-backend"
  tags                 = local.common_tags

  service_plan_id      = module.app_service_plan.id
  subnet_id           = module.networking.app_subnet_id
  app_settings        = local.app_settings
  
  # Custom domains and SSL
  custom_domain       = var.backend_custom_domain
  
  # Docker configuration
  docker_image        = "${module.container_registry.login_server}/khetisahayak-backend:latest"
  docker_registry_url = "https://${module.container_registry.login_server}"
  
  # Health check
  health_check_path   = "/api/health"
  
  # Scaling
  always_on          = true
  
  depends_on = [
    module.database,
    module.redis,
    module.key_vault
  ]
}

# Frontend Static Web App Module
module "frontend_static_web_app" {
  source = "./modules/static_web_app"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = "${local.name_prefix}-frontend"
  tags               = local.common_tags

  sku_tier = var.static_web_app_sku_tier
  sku_size = var.static_web_app_sku_size
  
  # Repository configuration
  repository_url    = var.repository_url
  repository_branch = var.repository_branch
  
  # Build configuration
  app_location    = "/kheti_sahayak_app"
  api_location    = ""
  output_location = "/build/web"
}

# API Management Module
module "api_management" {
  source = "./modules/api_management"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  publisher_name  = var.api_publisher_name
  publisher_email = var.api_publisher_email
  sku_name       = var.apim_sku_name

  backend_url = "https://${module.backend_app_service.default_hostname}"
  
  # Custom domain
  gateway_custom_domain = var.api_custom_domain
}

# Monitoring Module (Application Insights + Log Analytics)
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  retention_in_days = var.log_retention_days
}

# Security Module (Security Center, Defender)
module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  key_vault_id = module.key_vault.id
}

# CDN Module
module "cdn" {
  source = "./modules/cdn"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  origin_host_name = module.frontend_static_web_app.default_hostname
  custom_domain    = var.frontend_custom_domain
}

# Secrets stored in Key Vault
resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = random_password.jwt_secret.result
  key_vault_id = module.key_vault.id
  
  depends_on = [module.key_vault]
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = module.storage.primary_access_key
  key_vault_id = module.key_vault.id
  
  depends_on = [module.key_vault, module.storage]
}

# Generate random passwords and secrets
resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "backend_url" {
  description = "Backend application URL"
  value       = "https://${module.backend_app_service.default_hostname}"
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = "https://${module.frontend_static_web_app.default_hostname}"
}

output "api_management_url" {
  description = "API Management gateway URL"
  value       = module.api_management.gateway_url
}

output "database_server_fqdn" {
  description = "Database server FQDN"
  value       = module.database.server_fqdn
}

output "container_registry_login_server" {
  description = "Container registry login server"
  value       = module.container_registry.login_server
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.vault_uri
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.instrumentation_key
  sensitive   = true
}
