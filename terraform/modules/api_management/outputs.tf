# API Management Module Outputs

output "api_management_id" {
  description = "ID of the API Management service"
  value       = azurerm_api_management.main.id
}

output "api_management_name" {
  description = "Name of the API Management service"
  value       = azurerm_api_management.main.name
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management service"
  value       = azurerm_api_management.main.gateway_url
}

output "api_management_gateway_regional_url" {
  description = "Regional Gateway URL of the API Management service"
  value       = azurerm_api_management.main.gateway_regional_url
}

output "api_management_management_api_url" {
  description = "Management API URL of the API Management service"
  value       = azurerm_api_management.main.management_api_url
}

output "api_management_portal_url" {
  description = "Portal URL of the API Management service"
  value       = azurerm_api_management.main.portal_url
}

output "api_management_developer_portal_url" {
  description = "Developer Portal URL of the API Management service"
  value       = azurerm_api_management.main.developer_portal_url
}

output "api_management_scm_url" {
  description = "SCM URL of the API Management service"
  value       = azurerm_api_management.main.scm_url
}

output "api_management_public_ip_addresses" {
  description = "Public IP addresses of the API Management service"
  value       = azurerm_api_management.main.public_ip_addresses
}

output "api_management_private_ip_addresses" {
  description = "Private IP addresses of the API Management service"
  value       = azurerm_api_management.main.private_ip_addresses
}

output "api_management_identity" {
  description = "Identity of the API Management service"
  value = azurerm_api_management.main.identity != null ? {
    type         = azurerm_api_management.main.identity[0].type
    principal_id = azurerm_api_management.main.identity[0].principal_id
    tenant_id    = azurerm_api_management.main.identity[0].tenant_id
  } : null
}

output "api_ids" {
  description = "Map of API names to their IDs"
  value       = { for k, v in azurerm_api_management_api.apis : k => v.id }
}

output "product_ids" {
  description = "Map of product names to their IDs"
  value       = { for k, v in azurerm_api_management_product.products : k => v.id }
}
