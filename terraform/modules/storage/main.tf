# Storage Module for Kheti Sahayak

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "sa${replace(var.name_prefix, "-", "")}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  
  # Enable HTTPS traffic only
  enable_https_traffic_only = true

  # Blob properties
  blob_properties {
    # Enable versioning
    versioning_enabled = true
    
    # Change feed
    change_feed_enabled = true
    
    # Delete retention policy
    delete_retention_policy {
      days = var.delete_retention_days
    }
    
    # Container delete retention policy
    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }

    # CORS settings
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "POST", "PUT", "DELETE"]
      allowed_origins    = var.cors_allowed_origins
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  # Network rules
  network_rules {
    default_action             = length(var.subnet_ids) > 0 || length(var.allowed_ip_ranges) > 0 ? "Deny" : "Allow"
    virtual_network_subnet_ids = var.subnet_ids
    ip_rules                   = var.allowed_ip_ranges
    bypass                     = ["AzureServices"]
  }

  tags = var.tags
}

# Storage Containers
resource "azurerm_storage_container" "containers" {
  for_each = {
    for container in var.containers : container.name => container
  }

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.access_type
}

# File Shares
resource "azurerm_storage_share" "shares" {
  for_each = {
    for share in var.file_shares : share.name => share
  }

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.main.name
  quota                = each.value.quota
}

# Storage Queues
resource "azurerm_storage_queue" "queues" {
  for_each = toset(var.queues)

  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

# Storage Tables
resource "azurerm_storage_table" "tables" {
  for_each = toset(var.tables)

  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

# Storage Management Policy
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "default_lifecycle_rule"
    enabled = true
    filters {
      prefix_match = ["container1/prefix1"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
      version {
        delete_after_days_since_creation = 30
      }
    }
  }

  tags = var.tags
}

# Storage containers
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "images" {
  name                  = "images"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = var.public_access_enabled ? "blob" : "private"
}

resource "azurerm_storage_container" "documents" {
  name                  = "documents"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "videos" {
  name                  = "videos"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = var.public_access_enabled ? "blob" : "private"
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Queue for background processing
resource "azurerm_storage_queue" "image_processing" {
  name                 = "image-processing"
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_storage_queue" "notifications" {
  name                 = "notifications"
  storage_account_name = azurerm_storage_account.main.name
}

# Table for metadata storage
resource "azurerm_storage_table" "metadata" {
  name                 = "metadata"
  storage_account_name = azurerm_storage_account.main.name
}

# Private endpoint for storage account (optional)
resource "azurerm_private_endpoint" "storage" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "pe-${var.name_prefix}-storage"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.name_prefix}-storage"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Diagnostic settings for monitoring
resource "azurerm_monitor_diagnostic_setting" "storage" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${var.name_prefix}-storage"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
