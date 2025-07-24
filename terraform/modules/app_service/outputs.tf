# App Service Module Outputs

output "app_service_id" {
  description = "ID of the App Service"
  value       = azurerm_linux_web_app.backend.id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.backend.name
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.backend.default_hostname
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "app_service_outbound_ip_addresses" {
  description = "Outbound IP addresses of the App Service"
  value       = azurerm_linux_web_app.backend.outbound_ip_addresses
}

output "app_service_possible_outbound_ip_addresses" {
  description = "Possible outbound IP addresses of the App Service"
  value       = azurerm_linux_web_app.backend.possible_outbound_ip_addresses
}

output "deployment_slot_names" {
  description = "Names of deployment slots"
  value       = [for slot in azurerm_linux_web_app_slot.slots : slot.name]
}

output "deployment_slot_default_hostnames" {
  description = "Default hostnames of deployment slots"
  value       = { for k, slot in azurerm_linux_web_app_slot.slots : k => slot.default_hostname }
}

output "custom_domain_bindings" {
  description = "Custom domain bindings"
  value       = { for k, binding in azurerm_app_service_custom_hostname_binding.custom_domains : k => binding.hostname }
}

output "app_service_identity" {
  description = "Identity of the App Service"
  value = length(azurerm_linux_web_app.backend.identity) > 0 ? {
    type         = azurerm_linux_web_app.backend.identity[0].type
    principal_id = azurerm_linux_web_app.backend.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.backend.identity[0].tenant_id
  } : null
}
