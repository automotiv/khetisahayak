# Main Terraform Configuration Outputs

# Resource Group
output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the main resource group"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure location of the deployment"
  value       = azurerm_resource_group.main.location
}

# Networking
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = module.networking.subnet_ids
}

# Database
output "database_server_id" {
  description = "ID of the database server"
  value       = module.database.server_id
}

output "database_server_fqdn" {
  description = "FQDN of the database server"
  value       = module.database.server_fqdn
}

output "database_connection_string" {
  description = "Database connection string"
  value       = module.database.connection_string
  sensitive   = true
}

# Redis
output "redis_id" {
  description = "ID of the Redis cache"
  value       = module.redis.redis_id
}

output "redis_hostname" {
  description = "Hostname of the Redis cache"
  value       = module.redis.hostname
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = module.redis.primary_connection_string
  sensitive   = true
}

# Storage
output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage.storage_account_id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = module.storage.primary_blob_endpoint
}

# Key Vault
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.key_vault.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.key_vault_uri
}

# Container Registry
output "container_registry_id" {
  description = "ID of the Container Registry"
  value       = module.container_registry.container_registry_id
}

output "container_registry_login_server" {
  description = "Login server URL of the Container Registry"
  value       = module.container_registry.container_registry_login_server
}

output "container_registry_admin_username" {
  description = "Admin username for the Container Registry"
  value       = module.container_registry.container_registry_admin_username
}

# App Service Plan
output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = module.app_service_plan.app_service_plan_id
}

# Backend App Service
output "backend_app_service_id" {
  description = "ID of the backend App Service"
  value       = module.backend_app_service.app_service_id
}

output "backend_app_service_name" {
  description = "Name of the backend App Service"
  value       = module.backend_app_service.app_service_name
}

output "backend_app_service_default_hostname" {
  description = "Default hostname of the backend App Service"
  value       = module.backend_app_service.app_service_default_hostname
}

output "backend_url" {
  description = "URL of the backend application"
  value       = module.backend_app_service.app_service_url
}

# Static Web App
output "static_web_app_id" {
  description = "ID of the Static Web App"
  value       = module.frontend_static_web_app.static_site_id
}

output "static_web_app_default_hostname" {
  description = "Default hostname of the Static Web App"
  value       = module.frontend_static_web_app.static_site_default_host_name
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = module.frontend_static_web_app.static_site_url
}

# API Management
output "api_management_id" {
  description = "ID of the API Management instance"
  value       = module.api_management.api_management_id
}

output "api_management_gateway_url" {
  description = "Gateway URL of API Management"
  value       = module.api_management.api_management_gateway_url
}

output "api_management_portal_url" {
  description = "Developer portal URL of API Management"
  value       = module.api_management.api_management_developer_portal_url
}

# Monitoring
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_id" {
  description = "ID of Application Insights"
  value       = module.monitoring.application_insights_id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

# CDN
output "cdn_profile_id" {
  description = "ID of the CDN Profile"
  value       = module.cdn.cdn_profile_id
}

output "cdn_endpoint_hostnames" {
  description = "Hostnames of CDN endpoints"
  value       = module.cdn.cdn_endpoint_host_names
}

# Deployment Information
output "deployment_timestamp" {
  description = "Timestamp of the deployment"
  value       = timestamp()
}

output "terraform_version" {
  description = "Version of Terraform used for deployment"
  value       = "~> 1.0"
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "name_prefix" {
  description = "Name prefix used for resources"
  value       = local.name_prefix
}

# Application Configuration
output "app_configuration" {
  description = "Application configuration for deployment"
  value = {
    backend_url     = module.backend_app_service.app_service_url
    frontend_url    = module.frontend_static_web_app.static_site_url
    api_gateway_url = module.api_management.api_management_gateway_url
    database_host   = module.database.server_fqdn
    redis_host     = module.redis.hostname
    storage_account = module.storage.storage_account_name
    key_vault_uri  = module.key_vault.key_vault_uri
  }
  sensitive = false
}

# Connection Strings (for application configuration)
output "connection_strings" {
  description = "Connection strings for application services"
  value = {
    database = module.database.connection_string
    redis    = module.redis.primary_connection_string
    storage  = module.storage.storage_account_primary_connection_string
    app_insights = module.monitoring.application_insights_connection_string
  }
  sensitive = true
}

# Resource Tags
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
