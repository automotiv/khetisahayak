# Monitoring Module for Kheti Sahayak

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days

  # Daily quota
  daily_quota_gb = var.daily_quota_gb

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.name_prefix}-ai"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = var.application_insights_type

  # Retention
  retention_in_days = var.application_insights_retention_days

  # Sampling
  sampling_percentage = var.sampling_percentage

  # Daily data cap
  daily_data_cap_in_gb                  = var.daily_data_cap_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled

  tags = var.tags
}

# Action Groups
resource "azurerm_monitor_action_group" "main" {
  for_each = var.action_groups

  name                = each.key
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name

  # Email receivers
  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }

  # SMS receivers
  dynamic "sms_receiver" {
    for_each = each.value.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  # Webhook receivers
  dynamic "webhook_receiver" {
    for_each = each.value.webhook_receivers
    content {
      name        = webhook_receiver.value.name
      service_uri = webhook_receiver.value.service_uri
    }
  }

  # Azure Function receivers
  dynamic "azure_function_receiver" {
    for_each = each.value.azure_function_receivers
    content {
      name                     = azure_function_receiver.value.name
      function_app_resource_id = azure_function_receiver.value.function_app_resource_id
      function_name            = azure_function_receiver.value.function_name
      http_trigger_url         = azure_function_receiver.value.http_trigger_url
    }
  }

  tags = var.tags
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "alerts" {
  for_each = var.metric_alerts

  name                = each.key
  resource_group_name = var.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  enabled             = each.value.enabled

  # Criteria
  dynamic "criteria" {
    for_each = each.value.criteria
    content {
      metric_namespace = criteria.value.metric_namespace
      metric_name      = criteria.value.metric_name
      aggregation      = criteria.value.aggregation
      operator         = criteria.value.operator
      threshold        = criteria.value.threshold

      dynamic "dimension" {
        for_each = criteria.value.dimensions
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  # Action
  dynamic "action" {
    for_each = each.value.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Activity Log Alerts
resource "azurerm_monitor_activity_log_alert" "alerts" {
  for_each = var.activity_log_alerts

  name                = each.key
  resource_group_name = var.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  enabled             = each.value.enabled

  criteria {
    operation_name = each.value.operation_name
    category       = each.value.category
    level          = each.value.level
    status         = each.value.status
    sub_status     = each.value.sub_status

    dynamic "resource_health" {
      for_each = each.value.resource_health != null ? [each.value.resource_health] : []
      content {
        current  = resource_health.value.current
        previous = resource_health.value.previous
        reason   = resource_health.value.reason
      }
    }

    dynamic "service_health" {
      for_each = each.value.service_health != null ? [each.value.service_health] : []
      content {
        events    = service_health.value.events
        locations = service_health.value.locations
        services  = service_health.value.services
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Dashboards
resource "azurerm_dashboard" "main" {
  for_each = var.dashboards

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge(var.tags, each.value.tags)
  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = each.value.dashboard_parts
      }
    }
    metadata = {
      model = {
        timeRange = {
          value = {
            relative = {
              duration = 24
              timeUnit = 1
            }
          }
          type = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        }
        filterLocale = {
          value = "en-us"
        }
        filters = {
          value = {
            MsPortalFx_TimeRange = {
              model = {
                format        = "utc"
                granularity   = "auto"
                relative      = "24h"
              }
              displayCache = {
                name  = "UTC Time"
                value = "Past 24 hours"
              }
              filteredPartIds = each.value.filtered_part_ids
            }
          }
        }
      }
    }
  })
}

# Workbooks
resource "azurerm_application_insights_workbook" "workbooks" {
  for_each = var.workbooks

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = each.value.display_name
  data_json           = jsonencode(each.value.workbook_data)
  source_id           = azurerm_application_insights.main.id

  tags = merge(var.tags, each.value.tags)
}
