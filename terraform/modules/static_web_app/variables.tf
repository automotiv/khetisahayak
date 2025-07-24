# Static Web App Module Variables

variable "name_prefix" {
  description = "Name prefix for Static Web App resources"
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

variable "sku_tier" {
  description = "The SKU tier of the Static Web App"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "The sku_tier must be either 'Free' or 'Standard'."
  }
}

variable "sku_size" {
  description = "The SKU size of the Static Web App"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku_size)
    error_message = "The sku_size must be either 'Free' or 'Standard'."
  }
}

variable "app_settings" {
  description = "Map of app settings for the Static Web App"
  type        = map(string)
  default     = {}
}

variable "identity" {
  description = "Managed identity for the Static Web App"
  type = object({
    type         = string
    identity_ids = list(string)
  })
  default = null
}

variable "custom_domains" {
  description = "List of custom domains to associate with the Static Web App"
  type        = list(string)
  default     = []
}

variable "function_app_id" {
  description = "ID of the Function App to register with the Static Web App"
  type        = string
  default     = null
}

variable "basic_auth" {
  description = "Basic authentication settings"
  type = object({
    password     = string
    environments = string
  })
  default   = null
  sensitive = true
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
