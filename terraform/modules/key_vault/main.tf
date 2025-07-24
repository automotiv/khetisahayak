# Key Vault Module for Kheti Sahayak

# Get current client configuration
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "${var.name_prefix}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # Security settings
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  # Network Access
  public_network_access_enabled = var.public_network_access_enabled

  # Network ACLs
  network_acls {
    bypass                     = "AzureServices"
    default_action             = var.default_network_action
    virtual_network_subnet_ids = var.subnet_ids
    ip_rules                   = var.allowed_ip_ranges
  }

  tags = var.tags
}

# Access Policy for current service principal/user
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers",
    "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers",
    "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]

  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import",
    "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update",
    "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
  ]

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]

  storage_permissions = [
    "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS",
    "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
  ]
}

# Additional access policies
resource "azurerm_key_vault_access_policy" "additional" {
  for_each = var.access_policies

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = each.value.tenant_id
  object_id    = each.value.object_id

  certificate_permissions = each.value.certificate_permissions
  key_permissions        = each.value.key_permissions
  secret_permissions     = each.value.secret_permissions
  storage_permissions    = each.value.storage_permissions
}

# Secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.main.id
  content_type = each.value.content_type

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_key_vault_access_policy.current]
}

# Keys
resource "azurerm_key_vault_key" "keys" {
  for_each = var.keys

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  key_opts     = each.value.key_opts

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_key_vault_access_policy.current]
}

# Certificates
resource "azurerm_key_vault_certificate" "certificates" {
  for_each = var.certificates

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id

  certificate_policy {
    issuer_parameters {
      name = each.value.issuer_name
    }

    key_properties {
      exportable = each.value.exportable
      key_size   = each.value.key_size
      key_type   = each.value.key_type
      reuse_key  = each.value.reuse_key
    }

    lifetime_action {
      action {
        action_type = each.value.lifetime_action_type
      }

      trigger {
        days_before_expiry  = each.value.days_before_expiry
        lifetime_percentage = each.value.lifetime_percentage
      }
    }

    secret_properties {
      content_type = each.value.content_type
    }

    x509_certificate_properties {
      key_usage = each.value.key_usage

      subject            = each.value.subject
      validity_in_months = each.value.validity_in_months

      dynamic "subject_alternative_names" {
        for_each = each.value.subject_alternative_names != null ? [each.value.subject_alternative_names] : []
        content {
          dns_names = subject_alternative_names.value.dns_names
          emails    = subject_alternative_names.value.emails
          upns      = subject_alternative_names.value.upns
        }
      }
    }
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_key_vault_access_policy.current]
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name_prefix}-kv-diag"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
