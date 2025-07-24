# App Service Module Variables

variable "name_prefix" {
  description = "Name prefix for App Service resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location for resources"
  type        = string
}

variable "app_service_plan_id" {
  description = "ID of the App Service Plan"
  type        = string
}

variable "public_network_access_enabled" {
  description = "Should public network access be enabled"
  type        = bool
  default     = true
}

variable "app_settings" {
  description = "Map of app settings"
  type        = map(string)
  default     = {}
}

variable "container_registry_url" {
  description = "URL of the container registry"
  type        = string
  default     = null
}

variable "container_registry_username" {
  description = "Username for the container registry"
  type        = string
  default     = null
  sensitive   = true
}

variable "container_registry_password" {
  description = "Password for the container registry"
  type        = string
  default     = null
  sensitive   = true
}

variable "app_port" {
  description = "Port that the application listens on"
  type        = string
  default     = "3000"
}

variable "always_on" {
  description = "Should the app be loaded at all times"
  type        = bool
  default     = true
}

variable "use_managed_identity_for_registry" {
  description = "Use managed identity for container registry access"
  type        = bool
  default     = true
}

variable "websockets_enabled" {
  description = "Should websockets be enabled"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "health_check_eviction_time" {
  description = "Time in minutes after which unhealthy instances are removed"
  type        = number
  default     = 10
}

variable "docker_image" {
  description = "Docker image name"
  type        = string
  default     = "nginx"
}

variable "docker_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "cors_settings" {
  description = "CORS settings"
  type = object({
    allowed_origins     = list(string)
    support_credentials = bool
  })
  default = null
}

variable "ip_restrictions" {
  description = "List of IP restrictions"
  type = list(object({
    ip_address                = string
    service_tag               = string
    virtual_network_subnet_id = string
    name                      = string
    priority                  = number
    action                    = string
    headers                   = list(map(string))
  }))
  default = []
}

variable "connection_strings" {
  description = "List of connection strings"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default   = []
  sensitive = true
}

variable "auth_settings" {
  description = "Authentication settings"
  type = object({
    auth_enabled                = bool
    runtime_version             = string
    config_file_path            = string
    require_authentication      = bool
    unauthenticated_action      = string
    default_provider            = string
    excluded_paths              = list(string)
    require_https               = bool
    http_route_api_prefix       = string
    login = object({
      logout_endpoint                   = string
      token_store_enabled               = bool
      token_refresh_extension_time      = number
      token_store_path                  = string
      token_store_sas_setting_name      = string
      preserve_url_fragments_for_logins = bool
      allowed_external_redirect_urls    = list(string)
      cookie_expiration_convention      = string
      cookie_expiration_time            = string
      validate_nonce                    = bool
      nonce_expiration_time             = string
    })
  })
  default = null
}

variable "identity" {
  description = "Managed identity settings"
  type = object({
    type         = string
    identity_ids = list(string)
  })
  default = null
}

variable "detailed_error_messages" {
  description = "Should detailed error messages be enabled"
  type        = bool
  default     = false
}

variable "failed_request_tracing" {
  description = "Should failed request tracing be enabled"
  type        = bool
  default     = false
}

variable "application_logs" {
  description = "Application logs settings"
  type = object({
    file_system_level = string
    azure_blob_storage = object({
      level             = string
      sas_url           = string
      retention_in_days = number
    })
  })
  default = null
}

variable "http_logs" {
  description = "HTTP logs settings"
  type = object({
    azure_blob_storage = object({
      sas_url           = string
      retention_in_days = number
    })
    file_system = object({
      retention_in_days = number
      retention_in_mb   = number
    })
  })
  default = null
}

variable "backup_settings" {
  description = "Backup settings"
  type = object({
    name                = string
    storage_account_url = string
    schedule = object({
      frequency_interval       = number
      frequency_unit           = string
      keep_at_least_one_backup = bool
      retention_period_days    = number
      start_time               = string
    })
  })
  default = null
}

variable "deployment_slots" {
  description = "Map of deployment slots to create"
  type = map(object({
    app_settings       = map(string)
    docker_image       = string
    docker_image_tag   = string
  }))
  default = {}
}

variable "custom_domains" {
  description = "List of custom domains"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
