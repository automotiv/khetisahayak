# App Service Module for Kheti Sahayak

# App Service (Backend API)
resource "azurerm_linux_web_app" "backend" {
  name                = "${var.name_prefix}-backend"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id

  # Basic settings
  https_only                    = true
  public_network_access_enabled = var.public_network_access_enabled

  # App settings
  app_settings = merge(var.app_settings, {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = var.container_registry_url
    "DOCKER_REGISTRY_SERVER_USERNAME"     = var.container_registry_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = var.container_registry_password
    "WEBSITES_PORT"                       = var.app_port
  })

  # Site configuration
  site_config {
    always_on                         = var.always_on
    container_registry_use_managed_identity = var.use_managed_identity_for_registry
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    use_32_bit_worker                 = false
    websockets_enabled                = var.websockets_enabled
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time

    # Application stack
    application_stack {
      docker_image     = var.docker_image
      docker_image_tag = var.docker_image_tag
    }

    # CORS settings
    dynamic "cors" {
      for_each = var.cors_settings != null ? [var.cors_settings] : []
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    # IP restrictions
    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        ip_address                = ip_restriction.value.ip_address
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        action                    = ip_restriction.value.action
        headers                   = ip_restriction.value.headers
      }
    }
  }

  # Connection strings
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Authentication
  dynamic "auth_settings_v2" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []
    content {
      auth_enabled                            = auth_settings_v2.value.auth_enabled
      runtime_version                         = auth_settings_v2.value.runtime_version
      config_file_path                        = auth_settings_v2.value.config_file_path
      require_authentication                  = auth_settings_v2.value.require_authentication
      unauthenticated_action                  = auth_settings_v2.value.unauthenticated_action
      default_provider                        = auth_settings_v2.value.default_provider
      excluded_paths                          = auth_settings_v2.value.excluded_paths
      require_https                           = auth_settings_v2.value.require_https
      http_route_api_prefix                   = auth_settings_v2.value.http_route_api_prefix

      dynamic "login" {
        for_each = auth_settings_v2.value.login != null ? [auth_settings_v2.value.login] : []
        content {
          logout_endpoint                   = login.value.logout_endpoint
          token_store_enabled               = login.value.token_store_enabled
          token_refresh_extension_time      = login.value.token_refresh_extension_time
          token_store_path                  = login.value.token_store_path
          token_store_sas_setting_name      = login.value.token_store_sas_setting_name
          preserve_url_fragments_for_logins = login.value.preserve_url_fragments_for_logins
          allowed_external_redirect_urls    = login.value.allowed_external_redirect_urls
          cookie_expiration_convention      = login.value.cookie_expiration_convention
          cookie_expiration_time            = login.value.cookie_expiration_time
          validate_nonce                    = login.value.validate_nonce
          nonce_expiration_time             = login.value.nonce_expiration_time
        }
      }
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  # Logs
  logs {
    detailed_error_messages = var.detailed_error_messages
    failed_request_tracing  = var.failed_request_tracing

    dynamic "application_logs" {
      for_each = var.application_logs != null ? [var.application_logs] : []
      content {
        file_system_level = application_logs.value.file_system_level

        dynamic "azure_blob_storage" {
          for_each = application_logs.value.azure_blob_storage != null ? [application_logs.value.azure_blob_storage] : []
          content {
            level             = azure_blob_storage.value.level
            sas_url           = azure_blob_storage.value.sas_url
            retention_in_days = azure_blob_storage.value.retention_in_days
          }
        }
      }
    }

    dynamic "http_logs" {
      for_each = var.http_logs != null ? [var.http_logs] : []
      content {
        dynamic "azure_blob_storage" {
          for_each = http_logs.value.azure_blob_storage != null ? [http_logs.value.azure_blob_storage] : []
          content {
            sas_url           = azure_blob_storage.value.sas_url
            retention_in_days = azure_blob_storage.value.retention_in_days
          }
        }

        dynamic "file_system" {
          for_each = http_logs.value.file_system != null ? [http_logs.value.file_system] : []
          content {
            retention_in_days = file_system.value.retention_in_days
            retention_in_mb   = file_system.value.retention_in_mb
          }
        }
      }
    }
  }

  # Backup
  dynamic "backup" {
    for_each = var.backup_settings != null ? [var.backup_settings] : []
    content {
      name                = backup.value.name
      storage_account_url = backup.value.storage_account_url

      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit           = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = backup.value.schedule.keep_at_least_one_backup
        retention_period_days    = backup.value.schedule.retention_period_days
        start_time               = backup.value.schedule.start_time
      }
    }
  }

  tags = var.tags
}

# Deployment slots
resource "azurerm_linux_web_app_slot" "slots" {
  for_each = var.deployment_slots

  name           = each.key
  app_service_id = azurerm_linux_web_app.backend.id

  app_settings = merge(var.app_settings, each.value.app_settings, {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = var.container_registry_url
    "DOCKER_REGISTRY_SERVER_USERNAME"     = var.container_registry_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = var.container_registry_password
    "WEBSITES_PORT"                       = var.app_port
  })

  site_config {
    always_on                         = var.always_on
    container_registry_use_managed_identity = var.use_managed_identity_for_registry
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    use_32_bit_worker                 = false
    websockets_enabled                = var.websockets_enabled
    health_check_path                 = var.health_check_path

    application_stack {
      docker_image     = each.value.docker_image != null ? each.value.docker_image : var.docker_image
      docker_image_tag = each.value.docker_image_tag != null ? each.value.docker_image_tag : var.docker_image_tag
    }
  }

  tags = var.tags
}

# Custom domain
resource "azurerm_app_service_custom_hostname_binding" "custom_domains" {
  for_each = toset(var.custom_domains)

  hostname            = each.value
  app_service_name    = azurerm_linux_web_app.backend.name
  resource_group_name = var.resource_group_name
}

# SSL certificates
resource "azurerm_app_service_managed_certificate" "certificates" {
  for_each = toset(var.custom_domains)

  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.custom_domains[each.value].id
}

resource "azurerm_app_service_certificate_binding" "certificate_bindings" {
  for_each = toset(var.custom_domains)

  hostname_binding_id = azurerm_app_service_custom_hostname_binding.custom_domains[each.value].id
  certificate_id      = azurerm_app_service_managed_certificate.certificates[each.value].id
  ssl_state           = "SniEnabled"
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "app_service" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name_prefix}-backend-diag"
  target_resource_id         = azurerm_linux_web_app.backend.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
