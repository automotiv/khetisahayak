# Variables for Kheti Sahayak Azure Infrastructure

# General Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "khetisahayak"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "KhetiSahayak Team"
}

# Networking Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_spaces" {
  description = "Address spaces for subnets"
  type = object({
    app_subnet      = list(string)
    database_subnet = list(string)
    cache_subnet    = list(string)
    gateway_subnet  = list(string)
  })
  default = {
    app_subnet      = ["10.0.1.0/24"]
    database_subnet = ["10.0.2.0/24"]
    cache_subnet    = ["10.0.3.0/24"]
    gateway_subnet  = ["10.0.4.0/24"]
  }
}

# Database Configuration
variable "db_admin_username" {
  description = "Administrator username for PostgreSQL server"
  type        = string
  default     = "khetisahayak_admin"
  sensitive   = true
}

variable "db_admin_password" {
  description = "Administrator password for PostgreSQL server"
  type        = string
  sensitive   = true
}

variable "db_sku_name" {
  description = "SKU name for PostgreSQL server"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "db_storage_mb" {
  description = "Storage size in MB for PostgreSQL server"
  type        = number
  default     = 32768
}

variable "db_backup_retention_days" {
  description = "Backup retention days for PostgreSQL server"
  type        = number
  default     = 7
}

variable "db_geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup for PostgreSQL server"
  type        = bool
  default     = false
}

# Redis Configuration
variable "redis_sku_name" {
  description = "SKU name for Redis cache"
  type        = string
  default     = "Standard"
}

variable "redis_family" {
  description = "Redis family"
  type        = string
  default     = "C"
}

variable "redis_capacity" {
  description = "Redis capacity"
  type        = number
  default     = 1
}

# Container Registry Configuration
variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Standard"
}

# App Service Configuration
variable "app_service_sku_name" {
  description = "SKU name for App Service Plan"
  type        = string
  default     = "P1v3"
}

# Static Web App Configuration
variable "static_web_app_sku_tier" {
  description = "SKU tier for Static Web App"
  type        = string
  default     = "Standard"
}

variable "static_web_app_sku_size" {
  description = "SKU size for Static Web App"
  type        = string
  default     = "Standard"
}

# Repository Configuration
variable "repository_url" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/your-username/khetisahayak"
}

variable "repository_branch" {
  description = "Repository branch for deployment"
  type        = string
  default     = "main"
}

# API Management Configuration
variable "apim_sku_name" {
  description = "SKU name for API Management"
  type        = string
  default     = "Developer_1"
}

variable "api_publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "Kheti Sahayak"
}

variable "api_publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "admin@khetisahayak.com"
}

# Custom Domains
variable "backend_custom_domain" {
  description = "Custom domain for backend API"
  type        = string
  default     = ""
}

variable "frontend_custom_domain" {
  description = "Custom domain for frontend"
  type        = string
  default     = ""
}

variable "api_custom_domain" {
  description = "Custom domain for API Management"
  type        = string
  default     = ""
}

# CORS Configuration
variable "cors_allowed_origins" {
  description = "CORS allowed origins for storage account"
  type        = list(string)
  default     = ["https://localhost:3000", "https://khetisahayak.com"]
}

# Monitoring Configuration
variable "log_retention_days" {
  description = "Log retention days for Application Insights"
  type        = number
  default     = 90
}

# Security Configuration
variable "enable_ddos_protection" {
  description = "Enable DDoS protection for virtual network"
  type        = bool
  default     = false
}

variable "enable_network_security_group" {
  description = "Enable Network Security Group"
  type        = bool
  default     = true
}

# Scaling Configuration
variable "app_service_min_instances" {
  description = "Minimum number of App Service instances"
  type        = number
  default     = 1
}

variable "app_service_max_instances" {
  description = "Maximum number of App Service instances"
  type        = number
  default     = 10
}

# Feature Flags
variable "enable_application_gateway" {
  description = "Enable Application Gateway"
  type        = bool
  default     = false
}

variable "enable_cdn" {
  description = "Enable CDN for frontend"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable backup for App Services"
  type        = bool
  default     = true
}

variable "enable_ssl_certificate" {
  description = "Enable managed SSL certificate"
  type        = bool
  default     = true
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Cost Management
variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 500
}

variable "budget_notifications" {
  description = "Budget notification email addresses"
  type        = list(string)
  default     = ["admin@khetisahayak.com"]
}

# Development Environment Specific
variable "enable_debug_mode" {
  description = "Enable debug mode for development environment"
  type        = bool
  default     = false
}

variable "developer_ip_addresses" {
  description = "IP addresses allowed for development access"
  type        = list(string)
  default     = []
}
