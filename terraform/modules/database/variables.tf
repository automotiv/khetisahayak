# Database Module Variables

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

variable "subnet_id" {
  description = "ID of the subnet for PostgreSQL server"
  type        = string
}

variable "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  type        = string
}

variable "administrator_login" {
  description = "Administrator username for PostgreSQL server"
  type        = string
  sensitive   = true
}

variable "administrator_login_password" {
  description = "Administrator password for PostgreSQL server"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name for PostgreSQL server"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "storage_mb" {
  description = "Storage size in MB for PostgreSQL server"
  type        = number
  default     = 32768
}

variable "backup_retention_days" {
  description = "Backup retention days for PostgreSQL server"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup for PostgreSQL server"
  type        = bool
  default     = false
}

variable "enable_high_availability" {
  description = "Enable high availability for PostgreSQL server"
  type        = bool
  default     = false
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
  description = "Enable private endpoint for PostgreSQL server"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "enable_backup_storage" {
  description = "Enable additional backup storage account"
  type        = bool
  default     = false
}
