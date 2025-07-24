# App Service Plan Module for Kheti Sahayak

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${var.name_prefix}-asp"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  # Worker count for scaling
  worker_count = var.worker_count

  # Per Site Scaling
  per_site_scaling_enabled = var.per_site_scaling_enabled

  # Zone redundancy
  zone_balancing_enabled = var.zone_balancing_enabled

  tags = var.tags
}

# Auto-scaling settings
resource "azurerm_monitor_autoscale_setting" "main" {
  count = var.enable_autoscaling ? 1 : 0

  name                = "${var.name_prefix}-autoscale"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_service_plan.main.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.autoscale_capacity.default
      minimum = var.autoscale_capacity.minimum
      maximum = var.autoscale_capacity.maximum
    }

    # Scale out rule - CPU percentage > 80%
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale in rule - CPU percentage < 30%
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale out rule - Memory percentage > 80%
    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.scale_out_memory_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale in rule - Memory percentage < 40%
    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.scale_in_memory_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = var.autoscale_notifications.send_to_subscription_administrator
      send_to_subscription_co_administrator = var.autoscale_notifications.send_to_subscription_co_administrator
      custom_emails                         = var.autoscale_notifications.custom_emails
    }

    dynamic "webhook" {
      for_each = var.autoscale_notifications.webhooks
      content {
        service_uri = webhook.value.service_uri
        properties  = webhook.value.properties
      }
    }
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "app_service_plan" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name_prefix}-asp-diag"
  target_resource_id         = azurerm_service_plan.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
