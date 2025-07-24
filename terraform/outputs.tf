# Simple outputs for initial deployment

# Resource Group
output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the main resource group"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure location of the deployment"
  value       = azurerm_resource_group.main.location
}

# Networking outputs that work
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

# Container Registry
output "container_registry_name" {
  description = "Name of the container registry"
  value       = module.container_registry.container_registry_name
}

output "container_registry_login_server" {
  description = "Login server of the container registry"
  value       = module.container_registry.container_registry_login_server
}

# Backend Container Instance
output "backend_container_ip" {
  description = "Public IP of the backend container"
  value       = module.backend_container_instance.ip_address
}

output "backend_container_url" {
  description = "URL of the backend container"
  value       = module.backend_container_instance.container_url
}

output "backend_container_id" {
  description = "ID of the backend container group"
  value       = module.backend_container_instance.container_group_id
}

# Frontend Container Instance
output "frontend_container_ip" {
  description = "Public IP of the frontend container"
  value       = module.frontend_container_instance.ip_address
}

output "frontend_container_url" {
  description = "URL of the frontend container"
  value       = module.frontend_container_instance.container_url
}

output "frontend_container_id" {
  description = "ID of the frontend container group"
  value       = module.frontend_container_instance.container_group_id
}
