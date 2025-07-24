# Static Web App Module for Kheti Sahayak Flutter Frontend

# Static Web App
resource "azurerm_static_site" "main" {
  name                = "${var.name_prefix}-swa"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_tier            = var.sku_tier
  sku_size            = var.sku_size

  # App settings
  app_settings = var.app_settings

  # Identity
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  tags = var.tags
}

# Custom domain
resource "azurerm_static_site_custom_domain" "custom_domains" {
  for_each = toset(var.custom_domains)

  static_site_id  = azurerm_static_site.main.id
  domain_name     = each.value
  validation_type = "cname-delegation"
}

# Function app (for API endpoints if needed)
resource "azurerm_static_site_function_app_registration" "api" {
  count = var.function_app_id != null ? 1 : 0

  static_site_id  = azurerm_static_site.main.id
  function_app_id = var.function_app_id
}

# Basic auth
resource "azurerm_static_site_basic_auth" "main" {
  count = var.basic_auth != null ? 1 : 0

  static_site_id = azurerm_static_site.main.id
  password       = var.basic_auth.password
  environments   = var.basic_auth.environments
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "static_site" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name_prefix}-swa-diag"
  target_resource_id         = azurerm_static_site.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SWAFunctionExecutionLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
