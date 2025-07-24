# Development Environment Configuration

# Environment settings
environment = "dev"
location    = "East US"

# Networking
vnet_address_space = ["10.0.0.0/16"]
subnet_config = {
  app = {
    address_prefixes = ["10.0.1.0/24"]
  }
  database = {
    address_prefixes                          = ["10.0.2.0/24"]
    service_endpoints                         = ["Microsoft.Storage"]
    delegation_name                           = "postgres"
    delegation_service_delegation_name        = "Microsoft.DBforPostgreSQL/flexibleServers"
    delegation_service_delegation_actions     = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
  cache = {
    address_prefixes = ["10.0.3.0/24"]
  }
  gateway = {
    address_prefixes = ["10.0.4.0/24"]
  }
  private_endpoint = {
    address_prefixes = ["10.0.5.0/24"]
  }
}

# Database settings
postgres_version                     = "13"
postgres_admin_username              = "khetiadmin"
postgres_storage_mb                  = 32768
postgres_sku_name                   = "B_Standard_B1ms"
postgres_backup_retention_days       = 7
postgres_geo_redundant_backup_enabled = false
postgres_database_name              = "khetisahayak_dev"

# Redis settings
redis_capacity                            = 0
redis_family                             = "C"
redis_sku_name                          = "Basic"
redis_maxmemory_reserved                = 10
redis_maxmemory_delta                   = 2
redis_maxmemory_policy                  = "allkeys-lru"
redis_maxfragmentationmemory_reserved   = 12

# App Service settings
app_service_sku_name = "B1"

# Container Registry
acr_sku = "Basic"

# Static Web App
static_web_app_sku_tier = "Free"
static_web_app_sku_size = "Free"

# API Management
apim_sku_name = "Developer_1"

# Monitoring
log_analytics_sku              = "PerGB2018"
log_analytics_retention_days   = 30
application_insights_type      = "web"
application_insights_retention_days = 90

# Custom domains (empty for dev)
backend_custom_domain  = ""
frontend_custom_domain = ""
api_custom_domain     = ""

# Publisher info
api_publisher_name  = "Kheti Sahayak Dev Team"
api_publisher_email = "dev@khetisahayak.com"

# CORS settings
cors_allowed_origins = ["*"]

# Repository settings
repository_url    = "https://github.com/your-org/kheti-sahayak"
repository_branch = "develop"

# Log retention
log_retention_days = 30

# Action groups for monitoring
action_groups = {
  "dev-alerts" = {
    short_name = "dev-alerts"
    email_receivers = [
      {
        name          = "dev-team"
        email_address = "dev-team@khetisahayak.com"
      }
    ]
    sms_receivers             = []
    webhook_receivers         = []
    azure_function_receivers  = []
  }
}

# Metric alerts
metric_alerts = {
  "high-cpu" = {
    scopes      = ["PLACEHOLDER_APP_SERVICE_ID"]
    description = "High CPU usage alert"
    severity    = 2
    frequency   = "PT5M"
    window_size = "PT5M"
    enabled     = true
    action_group_ids = ["PLACEHOLDER_ACTION_GROUP_ID"]
    criteria = [
      {
        metric_namespace = "Microsoft.Web/sites"
        metric_name      = "CpuPercentage"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 80
        dimensions       = []
      }
    ]
  }
}

# Activity log alerts
activity_log_alerts = {}

# Tags
tags = {
  Environment = "Development"
  Project     = "Kheti Sahayak"
  Owner       = "Development Team"
  CostCenter  = "Engineering"
  Terraform   = "true"
}
