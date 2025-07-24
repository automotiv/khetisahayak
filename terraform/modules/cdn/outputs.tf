# CDN Module Outputs

output "cdn_profile_id" {
  description = "ID of the CDN Profile"
  value       = azurerm_cdn_profile.main.id
}

output "cdn_profile_name" {
  description = "Name of the CDN Profile"
  value       = azurerm_cdn_profile.main.name
}

output "cdn_endpoint_ids" {
  description = "Map of endpoint names to their IDs"
  value       = { for k, v in azurerm_cdn_endpoint.endpoints : k => v.id }
}

output "cdn_endpoint_host_names" {
  description = "Map of endpoint names to their host names"
  value       = { for k, v in azurerm_cdn_endpoint.endpoints : k => v.host_name }
}

output "cdn_endpoint_fqdns" {
  description = "Map of endpoint names to their FQDNs"
  value       = { for k, v in azurerm_cdn_endpoint.endpoints : k => v.fqdn }
}

output "custom_domain_ids" {
  description = "Map of custom domain names to their IDs"
  value       = { for k, v in azurerm_cdn_endpoint_custom_domain.custom_domains : k => v.id }
}
