# Monitoring Module Variables

variable "name_prefix" {
  description = "Name prefix for monitoring resources"
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

variable "log_analytics_sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Retention period for Log Analytics Workspace"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily quota for Log Analytics Workspace in GB"
  type        = number
  default     = -1
}

variable "application_insights_type" {
  description = "Application type for Application Insights"
  type        = string
  default     = "web"
}

variable "application_insights_retention_days" {
  description = "Retention period for Application Insights"
  type        = number
  default     = 90
}

variable "sampling_percentage" {
  description = "Sampling percentage for Application Insights"
  type        = number
  default     = 100
}

variable "daily_data_cap_gb" {
  description = "Daily data cap for Application Insights in GB"
  type        = number
  default     = 100
}

variable "daily_data_cap_notifications_disabled" {
  description = "Whether daily data cap notifications are disabled"
  type        = bool
  default     = false
}

variable "action_groups" {
  description = "Map of action groups to create"
  type = map(object({
    short_name = string
    email_receivers = list(object({
      name          = string
      email_address = string
    }))
    sms_receivers = list(object({
      name         = string
      country_code = string
      phone_number = string
    }))
    webhook_receivers = list(object({
      name        = string
      service_uri = string
    }))
    azure_function_receivers = list(object({
      name                     = string
      function_app_resource_id = string
      function_name            = string
      http_trigger_url         = string
    }))
  }))
  default = {}
}

variable "metric_alerts" {
  description = "Map of metric alerts to create"
  type = map(object({
    scopes         = list(string)
    description    = string
    severity       = number
    frequency      = string
    window_size    = string
    enabled        = bool
    action_group_ids = list(string)
    criteria = list(object({
      metric_namespace = string
      metric_name      = string
      aggregation      = string
      operator         = string
      threshold        = number
      dimensions = list(object({
        name     = string
        operator = string
        values   = list(string)
      }))
    }))
  }))
  default = {}
}

variable "activity_log_alerts" {
  description = "Map of activity log alerts to create"
  type = map(object({
    scopes           = list(string)
    description      = string
    enabled          = bool
    operation_name   = string
    category         = string
    level            = string
    status           = string
    sub_status       = string
    action_group_ids = list(string)
    resource_health = object({
      current  = list(string)
      previous = list(string)
      reason   = list(string)
    })
    service_health = object({
      events    = list(string)
      locations = list(string)
      services  = list(string)
    })
  }))
  default = {}
}

variable "dashboards" {
  description = "Map of dashboards to create"
  type = map(object({
    dashboard_parts    = list(any)
    filtered_part_ids  = list(string)
    tags               = map(string)
  }))
  default = {}
}

variable "workbooks" {
  description = "Map of workbooks to create"
  type = map(object({
    display_name   = string
    workbook_data  = any
    tags           = map(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
