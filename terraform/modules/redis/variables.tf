# Redis Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "sku_name" {
  description = "SKU name for Redis cache"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "SKU name must be one of: Basic, Standard, Premium."
  }
}

variable "family" {
  description = "Redis family"
  type        = string
  default     = "C"
}

variable "capacity" {
  description = "Redis capacity"
  type        = number
  default     = 1
}

variable "subnet_id" {
  description = "ID of the subnet for Redis cache (Premium SKU only)"
  type        = string
  default     = null
}

variable "enable_backup" {
  description = "Enable Redis backup (Premium SKU only)"
  type        = bool
  default     = true
}

variable "backup_frequency" {
  description = "Backup frequency in minutes (Premium SKU only)"
  type        = number
  default     = 60
}

variable "backup_max_snapshot_count" {
  description = "Maximum number of backup snapshots (Premium SKU only)"
  type        = number
  default     = 1
}

variable "maxmemory_reserved" {
  description = "Memory reserved for non-cache usage"
  type        = number
  default     = 10
}

variable "maxmemory_delta" {
  description = "Memory reserved for non-cache usage per shard"
  type        = number
  default     = 10
}

variable "maxmemory_policy" {
  description = "Policy for key eviction when memory limit is reached"
  type        = string
  default     = "allkeys-lru"
}

variable "maxfragmentationmemory_reserved" {
  description = "Memory reserved for fragmentation per shard"
  type        = number
  default     = 10
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "developer_ip_addresses" {
  description = "IP addresses allowed for development access"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for Redis cache (Premium SKU only)"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}
