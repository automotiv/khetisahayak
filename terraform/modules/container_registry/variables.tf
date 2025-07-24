# Container Registry Module Variables

variable "name_prefix" {
  description = "Name prefix for Container Registry resources"
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

variable "sku" {
  description = "The SKU name of the container registry"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The sku must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Specifies whether the admin user is enabled"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for the container registry"
  type        = bool
  default     = true
}

variable "network_rule_set" {
  description = "Network rule set for the container registry"
  type = object({
    default_action = string
    ip_rules = list(object({
      action   = string
      ip_range = string
    }))
    virtual_networks = list(object({
      action    = string
      subnet_id = string
    }))
  })
  default = null
}

variable "georeplications" {
  description = "List of georeplications for the container registry"
  type = list(object({
    location                  = string
    zone_redundancy_enabled   = bool
    regional_endpoint_enabled = bool
    tags                      = map(string)
  }))
  default = []
}

variable "retention_policy" {
  description = "Retention policy for the container registry"
  type = object({
    days    = number
    enabled = bool
  })
  default = null
}

variable "trust_policy" {
  description = "Trust policy for the container registry"
  type = object({
    enabled = bool
  })
  default = null
}

variable "quarantine_policy" {
  description = "Quarantine policy for the container registry"
  type = object({
    enabled = bool
  })
  default = null
}

variable "export_policy" {
  description = "Export policy for the container registry"
  type = object({
    enabled = bool
  })
  default = null
}

variable "identity" {
  description = "Managed identity for the container registry"
  type = object({
    type         = string
    identity_ids = list(string)
  })
  default = null
}

variable "encryption" {
  description = "Encryption configuration for the container registry"
  type = object({
    enabled            = bool
    key_vault_key_id   = string
    identity_client_id = string
  })
  default = null
}

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the container registry"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs"
  type        = list(string)
  default     = []
}

variable "acr_pull_role_assignments" {
  description = "Map of principal IDs that should be assigned AcrPull role"
  type        = map(string)
  default     = {}
}

variable "acr_push_role_assignments" {
  description = "Map of principal IDs that should be assigned AcrPush role"
  type        = map(string)
  default     = {}
}

variable "webhooks" {
  description = "Map of webhooks to create"
  type = map(object({
    service_uri    = string
    status         = string
    scope          = string
    actions        = list(string)
    custom_headers = map(string)
  }))
  default = {}
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
