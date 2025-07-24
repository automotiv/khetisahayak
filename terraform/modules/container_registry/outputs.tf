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

output "container_registry_identity" {
  description = "Identity of the container registry"
  value = azurerm_container_registry.main.identity != null ? {
    type         = azurerm_container_registry.main.identity[0].type
    principal_id = azurerm_container_registry.main.identity[0].principal_id
    tenant_id    = azurerm_container_registry.main.identity[0].tenant_id
  } : null
}

output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.acr[0].id : null
}

output "private_endpoint_ip_address" {
  description = "Private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.acr[0].private_service_connection[0].private_ip_address : null
}

output "webhook_ids" {
  description = "Map of webhook names to their IDs"
  value       = { for k, v in azurerm_container_registry_webhook.webhooks : k => v.id }
}
