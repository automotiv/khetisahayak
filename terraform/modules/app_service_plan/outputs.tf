# App Service Plan Module Outputs

output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.main.id
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.main.name
}

output "app_service_plan_os_type" {
  description = "OS type of the App Service Plan"
  value       = azurerm_service_plan.main.os_type
}

output "app_service_plan_sku_name" {
  description = "SKU name of the App Service Plan"
  value       = azurerm_service_plan.main.sku_name
}

output "app_service_plan_worker_count" {
  description = "Worker count of the App Service Plan"
  value       = azurerm_service_plan.main.worker_count
}

output "autoscale_setting_id" {
  description = "ID of the auto-scale setting"
  value       = var.enable_autoscaling ? azurerm_monitor_autoscale_setting.main[0].id : null
}
