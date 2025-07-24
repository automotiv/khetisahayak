# Key Vault Module Variables

variable "name_prefix" {
  description = "Name prefix for Key Vault resources"
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

variable "sku_name" {
  description = "The Name of the SKU used for this Key Vault"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The sku_name must be either 'standard' or 'premium'."
  }
}

variable "enabled_for_disk_encryption" {
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys"
  type        = bool
  default     = true
}

variable "enabled_for_deployment" {
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault"
  type        = bool
  default     = true
}

variable "enabled_for_template_deployment" {
  description = "Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault"
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions"
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault?"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted"
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "The soft_delete_retention_days must be between 7 and 90 days."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this Key Vault"
  type        = bool
  default     = true
}

variable "default_network_action" {
  description = "The Default Action to use when no rules match from ip_rules / virtual_network_subnet_ids"
  type        = string
  default     = "Allow"
  validation {
    condition     = contains(["Allow", "Deny"], var.default_network_action)
    error_message = "The default_network_action must be either 'Allow' or 'Deny'."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for network rules"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges"
  type        = list(string)
  default     = []
}

variable "access_policies" {
  description = "Map of access policies for the Key Vault"
  type = map(object({
    tenant_id               = string
    object_id               = string
    certificate_permissions = list(string)
    key_permissions        = list(string)
    secret_permissions     = list(string)
    storage_permissions    = list(string)
  }))
  default = {}
}

variable "secrets" {
  description = "Map of secrets to create in the Key Vault"
  type = map(object({
    value        = string
    content_type = string
    tags         = map(string)
  }))
  default   = {}
  sensitive = true
}

variable "keys" {
  description = "Map of keys to create in the Key Vault"
  type = map(object({
    key_type = string
    key_size = number
    key_opts = list(string)
    tags     = map(string)
  }))
  default = {}
}

variable "certificates" {
  description = "Map of certificates to create in the Key Vault"
  type = map(object({
    issuer_name                = string
    exportable                 = bool
    key_size                   = number
    key_type                   = string
    reuse_key                  = bool
    lifetime_action_type       = string
    days_before_expiry         = number
    lifetime_percentage        = number
    content_type               = string
    key_usage                  = list(string)
    subject                    = string
    validity_in_months         = number
    subject_alternative_names  = object({
      dns_names = list(string)
      emails    = list(string)
      upns      = list(string)
    })
    tags = map(string)
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
