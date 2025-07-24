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

  # Backend configuration for state management (commented out for initial deployment)
  # backend "azurerm" {
  #   resource_group_name  = "rg-khetisahayak-tfstate"
  #   storage_account_name = "sakhetisahayaktfstate"
  #   container_name       = "tfstate"
  #   key                  = "terraform.tfstate"
  # }
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
  
  # Application settings - simplified for initial deployment
  app_settings = {
    NODE_ENV                    = var.environment
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

# Key Vault Module - Commented out for initial deployment
# module "key_vault" {
#   source = "./modules/key_vault"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = local.name_prefix
#   tags               = local.common_tags
# }

# Storage Module - Commented out for initial deployment
# module "storage" {
#   source = "./modules/storage"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = local.name_prefix
#   tags               = local.common_tags

#   cors_allowed_origins = var.cors_allowed_origins
# }

# Database Module (PostgreSQL) - Commented out for initial deployment
# module "database" {
#   source = "./modules/database"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = local.name_prefix
#   tags               = local.common_tags

#   subnet_id                    = module.networking.database_subnet_id
#   private_dns_zone_id          = module.networking.private_dns_zone_id
#   administrator_login          = var.db_admin_username
#   administrator_login_password = var.db_admin_password
#   sku_name                    = var.db_sku_name
#   storage_mb                  = var.db_storage_mb
#   backup_retention_days       = var.db_backup_retention_days
#   geo_redundant_backup_enabled = var.db_geo_redundant_backup_enabled
# }

# Redis Cache Module - Commented out for initial deployment
# module "redis" {
#   source = "./modules/redis"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = local.name_prefix
#   tags               = local.common_tags

#   subnet_id = module.networking.cache_subnet_id
#   sku_name  = var.redis_sku_name
#   family    = var.redis_family
#   capacity  = var.redis_capacity
# }

# Container Registry Module
module "container_registry" {
  source = "./modules/container_registry"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = local.name_prefix
  tags               = local.common_tags

  sku           = var.acr_sku
  admin_enabled = true
}

# App Service Plan Module - Commented out due to quota restrictions
# module "app_service_plan" {
#   source = "./modules/app_service_plan"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = local.name_prefix
#   tags               = local.common_tags

#   sku_name          = var.app_service_sku_name
#   enable_autoscaling = var.app_service_sku_name != "F1" # Disable autoscaling for F1 (Free) tier
# }

# Backend App Service Module - Commented out due to quota restrictions
# module "backend_app_service" {
#   source = "./modules/app_service"

#   resource_group_name   = azurerm_resource_group.main.name
#   location             = azurerm_resource_group.main.location
#   name_prefix          = "${local.name_prefix}-backend"
#   tags                 = local.common_tags

#   app_service_plan_id  = module.app_service_plan.app_service_plan_id
#   app_settings        = local.app_settings
#   always_on           = var.app_service_sku_name != "F1" # Disable always_on for F1 (Free) tier
# }

# Backend Container Instance - Alternative to App Service
module "backend_container_instance" {
  source = "./modules/container_instance"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = "${local.name_prefix}-backend"
  tags               = local.common_tags

  docker_image       = "${module.container_registry.container_registry_login_server}/kheti-sahayak-backend-demo:latest"
  cpu_cores         = 1.0
  memory_gb         = 2.0
  container_port    = 3000
  
  registry_server   = module.container_registry.container_registry_login_server
  registry_username = module.container_registry.container_registry_admin_username
  registry_password = module.container_registry.container_registry_admin_password
  
  environment_variables = {
    NODE_ENV = "dev"
    PORT     = "3000"
  }

  depends_on = [module.container_registry]
}

# Frontend Container Instance
module "frontend_container_instance" {
  source = "./modules/container_instance"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  name_prefix        = "${local.name_prefix}-frontend"
  tags               = local.common_tags

  docker_image       = "${module.container_registry.container_registry_login_server}/kheti-sahayak-frontend:latest"
  cpu_cores         = 0.5
  memory_gb         = 1.0
  container_port    = 80
  
  registry_server   = module.container_registry.container_registry_login_server
  registry_username = module.container_registry.container_registry_admin_username
  registry_password = module.container_registry.container_registry_admin_password
  
  environment_variables = {
    ENVIRONMENT = "dev"
  }

  depends_on = [module.container_registry]
}

# Frontend Static Web App Module - Commented out for initial deployment
# module "frontend_static_web_app" {
#   source = "./modules/static_web_app"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = "${local.name_prefix}-frontend"
#   tags               = local.common_tags
# }

# API Management Module - Commented out for initial deployment
# module "api_management" {
#   source = "./modules/api_management"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = local.name_prefix
#   tags               = local.common_tags

#   publisher_name  = var.api_publisher_name
#   publisher_email = var.api_publisher_email
#   sku_name       = var.apim_sku_name
# }

# Monitoring Module (Application Insights + Log Analytics) - Commented out for initial deployment
# module "monitoring" {
#   source = "./modules/monitoring"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = local.name_prefix
#   tags               = local.common_tags
# }

# Security Module (Security Center, Defender) - Commented out for initial deployment
# module "security" {
#   source = "./modules/security"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = local.name_prefix
#   tags               = local.common_tags
# }

# CDN Module - Commented out for initial deployment
# module "cdn" {
#   source = "./modules/cdn"

#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   name_prefix        = local.name_prefix
#   tags               = local.common_tags
# }

# Secrets stored in Key Vault - Commented out for initial deployment
# resource "azurerm_key_vault_secret" "jwt_secret" {
#   name         = "jwt-secret"
#   value        = random_password.jwt_secret.result
#   key_vault_id = module.key_vault.id
  
#   depends_on = [module.key_vault]
# }

# resource "azurerm_key_vault_secret" "storage_account_key" {
#   name         = "storage-account-key"
#   value        = module.storage.primary_access_key
#   key_vault_id = module.key_vault.id
  
#   depends_on = [module.key_vault, module.storage]
# }

# Generate random passwords and secrets - Commented out for initial deployment
# resource "random_password" "jwt_secret" {
#   length  = 32
#   special = true
# }

# Note: All outputs are defined in outputs.tf to avoid duplication
