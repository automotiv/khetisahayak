# Storage Module Variables

variable "name_prefix" {
  description = "Name prefix for storage resources"
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

variable "replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "delete_retention_days" {
  description = "Number of days to retain deleted blobs"
  type        = number
  default     = 7
}

variable "container_delete_retention_days" {
  description = "Number of days to retain deleted containers"
  type        = number
  default     = 7
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
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

variable "containers" {
  description = "List of storage containers to create"
  type = list(object({
    name        = string
    access_type = string
  }))
  default = [
    {
      name        = "images"
      access_type = "private"
    },
    {
      name        = "documents"
      access_type = "private"
    },
    {
      name        = "backups"
      access_type = "private"
    }
  ]
}

variable "file_shares" {
  description = "List of file shares to create"
  type = list(object({
    name  = string
    quota = number
  }))
  default = [
    {
      name  = "app-data"
      quota = 100
    }
  ]
}

variable "queues" {
  description = "List of storage queues to create"
  type        = list(string)
  default     = ["notifications", "email-queue", "image-processing"]
}

variable "tables" {
  description = "List of storage tables to create"
  type        = list(string)
  default     = ["logs", "sessions"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
