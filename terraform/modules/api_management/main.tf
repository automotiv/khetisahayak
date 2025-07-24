# API Management Module for Kheti Sahayak

# API Management Service
resource "azurerm_api_management" "main" {
  name                = "${var.name_prefix}-apim"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  # Public IP addresses (for Premium SKU)
  public_ip_address_id = var.public_ip_address_id

  # Virtual network configuration
  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_configuration != null ? [var.virtual_network_configuration] : []
    content {
      subnet_id = virtual_network_configuration.value.subnet_id
    }
  }

  # Additional locations
  dynamic "additional_location" {
    for_each = var.additional_locations
    content {
      location             = additional_location.value.location
      capacity             = additional_location.value.capacity
      zones                = additional_location.value.zones
      public_ip_address_id = additional_location.value.public_ip_address_id

      dynamic "virtual_network_configuration" {
        for_each = additional_location.value.virtual_network_configuration != null ? [additional_location.value.virtual_network_configuration] : []
        content {
          subnet_id = virtual_network_configuration.value.subnet_id
        }
      }
    }
  }

  # Security
  dynamic "security" {
    for_each = var.security != null ? [var.security] : []
    content {
      enable_backend_ssl30                                = security.value.enable_backend_ssl30
      enable_backend_tls10                                = security.value.enable_backend_tls10
      enable_backend_tls11                                = security.value.enable_backend_tls11
      enable_frontend_ssl30                               = security.value.enable_frontend_ssl30
      enable_frontend_tls10                               = security.value.enable_frontend_tls10
      enable_frontend_tls11                               = security.value.enable_frontend_tls11
      tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = security.value.tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled
      tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled = security.value.tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled
      tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled   = security.value.tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled
      tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled   = security.value.tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled
      tls_rsa_with_aes128_cbc_sha256_ciphers_enabled     = security.value.tls_rsa_with_aes128_cbc_sha256_ciphers_enabled
      tls_rsa_with_aes128_cbc_sha_ciphers_enabled        = security.value.tls_rsa_with_aes128_cbc_sha_ciphers_enabled
      tls_rsa_with_aes128_gcm_sha256_ciphers_enabled     = security.value.tls_rsa_with_aes128_gcm_sha256_ciphers_enabled
      tls_rsa_with_aes256_cbc_sha256_ciphers_enabled     = security.value.tls_rsa_with_aes256_cbc_sha256_ciphers_enabled
      tls_rsa_with_aes256_cbc_sha_ciphers_enabled        = security.value.tls_rsa_with_aes256_cbc_sha_ciphers_enabled
      tls_rsa_with_aes256_gcm_sha384_ciphers_enabled     = security.value.tls_rsa_with_aes256_gcm_sha384_ciphers_enabled
      triple_des_ciphers_enabled                          = security.value.triple_des_ciphers_enabled
    }
  }

  # Protocols
  dynamic "protocols" {
    for_each = var.protocols != null ? [var.protocols] : []
    content {
      enable_http2 = protocols.value.enable_http2
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

  # Hostname configuration
  dynamic "hostname_configuration" {
    for_each = var.hostname_configuration != null ? [var.hostname_configuration] : []
    content {
      dynamic "management" {
        for_each = hostname_configuration.value.management
        content {
          host_name                    = management.value.host_name
          key_vault_id                = management.value.key_vault_id
          certificate                 = management.value.certificate
          certificate_password        = management.value.certificate_password
          negotiate_client_certificate = management.value.negotiate_client_certificate
        }
      }

      dynamic "portal" {
        for_each = hostname_configuration.value.portal
        content {
          host_name                    = portal.value.host_name
          key_vault_id                = portal.value.key_vault_id
          certificate                 = portal.value.certificate
          certificate_password        = portal.value.certificate_password
          negotiate_client_certificate = portal.value.negotiate_client_certificate
        }
      }

      dynamic "developer_portal" {
        for_each = hostname_configuration.value.developer_portal
        content {
          host_name                    = developer_portal.value.host_name
          key_vault_id                = developer_portal.value.key_vault_id
          certificate                 = developer_portal.value.certificate
          certificate_password        = developer_portal.value.certificate_password
          negotiate_client_certificate = developer_portal.value.negotiate_client_certificate
        }
      }

      dynamic "proxy" {
        for_each = hostname_configuration.value.proxy
        content {
          default_ssl_binding          = proxy.value.default_ssl_binding
          host_name                    = proxy.value.host_name
          key_vault_id                = proxy.value.key_vault_id
          certificate                 = proxy.value.certificate
          certificate_password        = proxy.value.certificate_password
          negotiate_client_certificate = proxy.value.negotiate_client_certificate
        }
      }

      dynamic "scm" {
        for_each = hostname_configuration.value.scm
        content {
          host_name                    = scm.value.host_name
          key_vault_id                = scm.value.key_vault_id
          certificate                 = scm.value.certificate
          certificate_password        = scm.value.certificate_password
          negotiate_client_certificate = scm.value.negotiate_client_certificate
        }
      }
    }
  }

  tags = var.tags
}

# API Management APIs
resource "azurerm_api_management_api" "apis" {
  for_each = var.apis

  name                  = each.key
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.main.name
  revision              = each.value.revision
  display_name          = each.value.display_name
  path                  = each.value.path
  protocols             = each.value.protocols
  description           = each.value.description
  service_url           = each.value.service_url
  subscription_required = each.value.subscription_required
  version               = each.value.version
  version_set_id        = each.value.version_set_id

  dynamic "import" {
    for_each = each.value.import != null ? [each.value.import] : []
    content {
      content_format = import.value.content_format
      content_value  = import.value.content_value

      dynamic "wsdl_selector" {
        for_each = import.value.wsdl_selector != null ? [import.value.wsdl_selector] : []
        content {
          service_name  = wsdl_selector.value.service_name
          endpoint_name = wsdl_selector.value.endpoint_name
        }
      }
    }
  }

  dynamic "oauth2_authorization" {
    for_each = each.value.oauth2_authorization != null ? [each.value.oauth2_authorization] : []
    content {
      authorization_server_name = oauth2_authorization.value.authorization_server_name
      scope                     = oauth2_authorization.value.scope
    }
  }

  dynamic "openid_authentication" {
    for_each = each.value.openid_authentication != null ? [each.value.openid_authentication] : []
    content {
      openid_provider_name         = openid_authentication.value.openid_provider_name
      bearer_token_sending_methods = openid_authentication.value.bearer_token_sending_methods
    }
  }

  dynamic "subscription_key_parameter_names" {
    for_each = each.value.subscription_key_parameter_names != null ? [each.value.subscription_key_parameter_names] : []
    content {
      header = subscription_key_parameter_names.value.header
      query  = subscription_key_parameter_names.value.query
    }
  }
}

# API Management Products
resource "azurerm_api_management_product" "products" {
  for_each = var.products

  product_id            = each.key
  api_management_name   = azurerm_api_management.main.name
  resource_group_name   = var.resource_group_name
  display_name          = each.value.display_name
  subscription_required = each.value.subscription_required
  approval_required     = each.value.approval_required
  published             = each.value.published
  description           = each.value.description
  terms                 = each.value.terms
  subscriptions_limit   = each.value.subscriptions_limit
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "apim" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name_prefix}-apim-diag"
  target_resource_id         = azurerm_api_management.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "GatewayLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
