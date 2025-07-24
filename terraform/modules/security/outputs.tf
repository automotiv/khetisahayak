# Security Module Outputs

output "network_security_group_ids" {
  description = "Map of Network Security Group names to their IDs"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}

output "ddos_protection_plan_id" {
  description = "ID of the DDoS Protection Plan"
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.main[0].id : null
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone names to their IDs"
  value       = { for k, v in azurerm_private_dns_zone.dns_zones : k => v.id }
}

output "waf_policy_id" {
  description = "ID of the Web Application Firewall policy"
  value       = var.waf_policy != null ? azurerm_web_application_firewall_policy.waf[0].id : null
}

output "firewall_id" {
  description = "ID of the Azure Firewall"
  value       = var.firewall_config != null ? azurerm_firewall.main[0].id : null
}

output "firewall_ip_configuration" {
  description = "IP configuration of the Azure Firewall"
  value = var.firewall_config != null ? {
    for config in azurerm_firewall.main[0].ip_configuration : config.name => {
      private_ip_address = config.private_ip_address
      public_ip_address_id = config.public_ip_address_id
    }
  } : null
}
