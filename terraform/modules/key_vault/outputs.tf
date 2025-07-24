# Key Vault Module Outputs

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_tenant_id" {
  description = "Tenant ID of the Key Vault"
  value       = azurerm_key_vault.main.tenant_id
}

output "secret_ids" {
  description = "Map of secret names to their IDs"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_versions" {
  description = "Map of secret names to their current versions"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.version }
}

output "key_ids" {
  description = "Map of key names to their IDs"
  value       = { for k, v in azurerm_key_vault_key.keys : k => v.id }
}

output "key_versions" {
  description = "Map of key names to their current versions"
  value       = { for k, v in azurerm_key_vault_key.keys : k => v.version }
}

output "certificate_ids" {
  description = "Map of certificate names to their IDs"
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.id }
}

output "certificate_thumbprints" {
  description = "Map of certificate names to their thumbprints"
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.thumbprint }
}
