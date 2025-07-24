# Container Instance Module Outputs

output "container_group_id" {
  description = "ID of the container group"
  value       = azurerm_container_group.main.id
}

output "ip_address" {
  description = "Public IP address of the container group"
  value       = azurerm_container_group.main.ip_address
}

output "fqdn" {
  description = "FQDN of the container group"
  value       = azurerm_container_group.main.fqdn
}

output "container_url" {
  description = "URL to access the container"
  value       = "http://${azurerm_container_group.main.ip_address}:${var.container_port}"
}
