# Static Web App Module Outputs

output "static_site_id" {
  description = "ID of the Static Web App"
  value       = azurerm_static_site.main.id
}

output "static_site_name" {
  description = "Name of the Static Web App"
  value       = azurerm_static_site.main.name
}

output "static_site_default_host_name" {
  description = "Default hostname of the Static Web App"
  value       = azurerm_static_site.main.default_host_name
}

output "static_site_url" {
  description = "URL of the Static Web App"
  value       = "https://${azurerm_static_site.main.default_host_name}"
}

output "static_site_api_key" {
  description = "API key for the Static Web App"
  value       = azurerm_static_site.main.api_key
  sensitive   = true
}

output "static_site_identity" {
  description = "Identity of the Static Web App"
  value = azurerm_static_site.main.identity != null ? {
    type         = azurerm_static_site.main.identity[0].type
    principal_id = azurerm_static_site.main.identity[0].principal_id
    tenant_id    = azurerm_static_site.main.identity[0].tenant_id
  } : null
}

output "custom_domain_validation_tokens" {
  description = "Map of custom domains to their validation tokens"
  value       = { for k, v in azurerm_static_site_custom_domain.custom_domains : k => v.validation_token }
  sensitive   = true
}
