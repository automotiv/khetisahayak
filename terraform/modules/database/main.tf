# Database Module for Kheti Sahayak (PostgreSQL)

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.name_prefix}"
  resource_group_name    = var.resource_group_name
  location              = var.location
  version               = "14"
  delegated_subnet_id   = var.subnet_id
  private_dns_zone_id   = var.private_dns_zone_id
  administrator_login   = var.administrator_login
  administrator_password = var.administrator_login_password
  zone                  = "1"

  storage_mb = var.storage_mb
  sku_name   = var.sku_name

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # High availability configuration
  dynamic "high_availability" {
    for_each = var.enable_high_availability ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
    }
  }

  # Maintenance window
  maintenance_window {
    day_of_week  = 0
    start_hour   = 3
    start_minute = 0
  }

  tags = var.tags

  depends_on = [var.private_dns_zone_id]
}

# PostgreSQL Flexible Server Configuration
resource "azurerm_postgresql_flexible_server_configuration" "timezone" {
  name      = "timezone"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "Asia/Kolkata"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  name      = "log_statement"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "all"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_min_duration_statement" {
  name      = "log_min_duration_statement"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "1000"
}

# Main application database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "khetisahayak"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Test database (for development environment)
resource "azurerm_postgresql_flexible_server_database" "test" {
  count = var.environment == "dev" ? 1 : 0

  name      = "khetisahayak_test"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Firewall rule to allow Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Firewall rules for development access (only in dev environment)
resource "azurerm_postgresql_flexible_server_firewall_rule" "development" {
  count = var.environment == "dev" && length(var.developer_ip_addresses) > 0 ? length(var.developer_ip_addresses) : 0

  name             = "DeveloperAccess-${count.index}"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = var.developer_ip_addresses[count.index]
  end_ip_address   = var.developer_ip_addresses[count.index]
}

# Diagnostic settings for monitoring
resource "azurerm_monitor_diagnostic_setting" "postgres" {
  name                       = "diag-${var.name_prefix}-postgres"
  target_resource_id         = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Private endpoint for secure access (optional, already using VNet integration)
resource "azurerm_private_endpoint" "postgres" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "pe-${var.name_prefix}-postgres"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.name_prefix}-postgres"
    private_connection_resource_id = azurerm_postgresql_flexible_server.main.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Database backup configuration (additional backup to storage account)
resource "azurerm_storage_account" "backup" {
  count = var.enable_backup_storage ? 1 : 0

  name                     = "sa${replace(var.name_prefix, "-", "")}backup"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = var.tags
}

resource "azurerm_storage_container" "backup" {
  count = var.enable_backup_storage ? 1 : 0

  name                  = "database-backups"
  storage_account_name  = azurerm_storage_account.backup[0].name
  container_access_type = "private"
}
