# App Service Plan Module Variables

variable "name_prefix" {
  description = "Name prefix for App Service Plan resources"
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

variable "os_type" {
  description = "The operating system type for the App Service Plan"
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows", "WindowsContainer"], var.os_type)
    error_message = "The os_type must be either 'Linux', 'Windows', or 'WindowsContainer'."
  }
}

variable "sku_name" {
  description = "The SKU for the App Service Plan"
  type        = string
  default     = "P1v3"
}

variable "worker_count" {
  description = "The number of workers to allocate"
  type        = number
  default     = 1
}

variable "per_site_scaling_enabled" {
  description = "Should per site scaling be enabled"
  type        = bool
  default     = false
}

variable "zone_balancing_enabled" {
  description = "Should zone balancing be enabled"
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling for the App Service Plan"
  type        = bool
  default     = true
}

variable "autoscale_capacity" {
  description = "Auto-scaling capacity settings"
  type = object({
    default = number
    minimum = number
    maximum = number
  })
  default = {
    default = 2
    minimum = 1
    maximum = 10
  }
}

variable "scale_out_cpu_threshold" {
  description = "CPU percentage threshold for scaling out"
  type        = number
  default     = 80
}

variable "scale_in_cpu_threshold" {
  description = "CPU percentage threshold for scaling in"
  type        = number
  default     = 30
}

variable "scale_out_memory_threshold" {
  description = "Memory percentage threshold for scaling out"
  type        = number
  default     = 80
}

variable "scale_in_memory_threshold" {
  description = "Memory percentage threshold for scaling in"
  type        = number
  default     = 40
}

variable "autoscale_notifications" {
  description = "Auto-scaling notification settings"
  type = object({
    send_to_subscription_administrator    = bool
    send_to_subscription_co_administrator = bool
    custom_emails                         = list(string)
    webhooks = list(object({
      service_uri = string
      properties  = map(string)
    }))
  })
  default = {
    send_to_subscription_administrator    = true
    send_to_subscription_co_administrator = false
    custom_emails                         = []
    webhooks                              = []
  }
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
