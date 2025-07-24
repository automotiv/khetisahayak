# Redis Module Outputs

output "id" {
  description = "ID of the Redis cache"
  value       = azurerm_redis_cache.main.id
}

output "name" {
  description = "Name of the Redis cache"
  value       = azurerm_redis_cache.main.name
}

output "hostname" {
  description = "Hostname of the Redis cache"
  value       = azurerm_redis_cache.main.hostname
}

output "ssl_port" {
  description = "SSL port of the Redis cache"
  value       = azurerm_redis_cache.main.ssl_port
}

output "port" {
  description = "Non-SSL port of the Redis cache"
  value       = azurerm_redis_cache.main.port
}

output "primary_access_key" {
  description = "Primary access key for the Redis cache"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key for the Redis cache"
  value       = azurerm_redis_cache.main.secondary_access_key
  sensitive   = true
}

output "connection_string" {
  description = "Connection string for the Redis cache"
  value       = "rediss://:${azurerm_redis_cache.main.primary_access_key}@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}/0"
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string for the Redis cache"
  value       = azurerm_redis_cache.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary connection string for the Redis cache"
  value       = azurerm_redis_cache.main.secondary_connection_string
  sensitive   = true
}
