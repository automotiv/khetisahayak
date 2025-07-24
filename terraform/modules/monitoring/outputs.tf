# Monitoring Module Outputs

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_workspace_id" {
  description = "Workspace ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_analytics_workspace_primary_shared_key" {
  description = "Primary shared key of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "application_insights_id" {
  description = "ID of Application Insights"
  value       = azurerm_application_insights.main.id
}

output "application_insights_app_id" {
  description = "App ID of Application Insights"
  value       = azurerm_application_insights.main.app_id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string of Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "action_group_ids" {
  description = "Map of action group names to their IDs"
  value       = { for k, v in azurerm_monitor_action_group.main : k => v.id }
}

output "metric_alert_ids" {
  description = "Map of metric alert names to their IDs"
  value       = { for k, v in azurerm_monitor_metric_alert.alerts : k => v.id }
}

output "activity_log_alert_ids" {
  description = "Map of activity log alert names to their IDs"
  value       = { for k, v in azurerm_monitor_activity_log_alert.alerts : k => v.id }
}

output "dashboard_ids" {
  description = "Map of dashboard names to their IDs"
  value       = { for k, v in azurerm_dashboard.main : k => v.id }
}

output "workbook_ids" {
  description = "Map of workbook names to their IDs"
  value       = { for k, v in azurerm_application_insights_workbook.workbooks : k => v.id }
}
