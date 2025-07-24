# Redis Cache Module for Kheti Sahayak

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.capacity
  family              = var.family
  sku_name            = var.sku_name
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  
  # VNet integration for Premium SKU
  subnet_id = var.sku_name == "Premium" ? var.subnet_id : null

  # Redis configuration
  redis_configuration {
    enable_authentication           = true
    maxmemory_reserved             = var.maxmemory_reserved
    maxmemory_delta                = var.maxmemory_delta
    maxmemory_policy               = var.maxmemory_policy
    maxfragmentationmemory_reserved = var.maxfragmentationmemory_reserved
    
    # Enable data persistence for Premium SKU
    rdb_backup_enabled            = var.sku_name == "Premium" ? var.enable_backup : false
    rdb_backup_frequency          = var.sku_name == "Premium" ? var.backup_frequency : null
    rdb_backup_max_snapshot_count = var.sku_name == "Premium" ? var.backup_max_snapshot_count : null
    rdb_storage_connection_string = var.sku_name == "Premium" && var.enable_backup ? azurerm_storage_account.backup[0].primary_blob_connection_string : null
  }

  # Patch schedule
  patch_schedule {
    day_of_week    = "Sunday"
    start_hour_utc = 2
  }

  tags = var.tags
}

# Storage account for Redis backup (Premium SKU only)
resource "azurerm_storage_account" "backup" {
  count = var.sku_name == "Premium" && var.enable_backup ? 1 : 0

  name                     = "sa${replace(var.name_prefix, "-", "")}redis"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

resource "azurerm_storage_container" "backup" {
  count = var.sku_name == "Premium" && var.enable_backup ? 1 : 0

  name                  = "redis-backups"
  storage_account_name  = azurerm_storage_account.backup[0].name
  container_access_type = "private"
}

# Firewall rules for Redis (if not using VNet integration)
resource "azurerm_redis_firewall_rule" "azure_services" {
  count = var.sku_name != "Premium" ? 1 : 0

  name                = "AllowAzureServices"
  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = var.resource_group_name
  start_ip            = "0.0.0.0"
  end_ip              = "0.0.0.0"
}

# Development firewall rules (only in dev environment)
resource "azurerm_redis_firewall_rule" "development" {
  count = var.environment == "dev" && var.sku_name != "Premium" && length(var.developer_ip_addresses) > 0 ? length(var.developer_ip_addresses) : 0

  name                = "DeveloperAccess-${count.index}"
  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = var.resource_group_name
  start_ip            = var.developer_ip_addresses[count.index]
  end_ip              = var.developer_ip_addresses[count.index]
}

# Diagnostic settings for monitoring
resource "azurerm_monitor_diagnostic_setting" "redis" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${var.name_prefix}-redis"
  target_resource_id         = azurerm_redis_cache.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ConnectedClientList"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Private endpoint for Premium Redis in VNet
resource "azurerm_private_endpoint" "redis" {
  count = var.sku_name == "Premium" && var.enable_private_endpoint ? 1 : 0

  name                = "pe-${var.name_prefix}-redis"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.name_prefix}-redis"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  tags = var.tags
}
