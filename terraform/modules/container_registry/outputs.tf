# Container Registry Module Outputs

output "container_registry_id" {
  description = "ID of the container registry"
  value       = azurerm_container_registry.main.id
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "The URL that can be used to log into the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "The Username associated with the Container Registry Admin account"
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_username : null
}

output "container_registry_admin_password" {
  description = "The Password associated with the Container Registry Admin account"
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_password : null
  sensitive   = true
}


