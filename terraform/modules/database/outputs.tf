# Database Module Outputs

output "server_id" {
  description = "ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_name" {
  description = "Name of the main database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "connection_string" {
  description = "Connection string for the database"
  value       = "postgresql://${var.administrator_login}:${var.administrator_login_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
  sensitive   = true
}

output "administrator_login" {
  description = "Administrator login for the PostgreSQL server"
  value       = var.administrator_login
  sensitive   = true
}

output "backup_storage_account_name" {
  description = "Name of the backup storage account"
  value       = var.enable_backup_storage ? azurerm_storage_account.backup[0].name : null
}

output "backup_container_name" {
  description = "Name of the backup container"
  value       = var.enable_backup_storage ? azurerm_storage_container.backup[0].name : null
}
