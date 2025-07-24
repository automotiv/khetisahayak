# Production Environment Configuration

# Environment settings
environment = "prod"
location    = "East US"

# Networking
vnet_address_space = ["10.1.0.0/16"]
subnet_config = {
  app = {
    address_prefixes = ["10.1.1.0/24"]
  }
  database = {
    address_prefixes                          = ["10.1.2.0/24"]
    service_endpoints                         = ["Microsoft.Storage"]
    delegation_name                           = "postgres"
    delegation_service_delegation_name        = "Microsoft.DBforPostgreSQL/flexibleServers"
    delegation_service_delegation_actions     = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
  cache = {
    address_prefixes = ["10.1.3.0/24"]
  }
  gateway = {
    address_prefixes = ["10.1.4.0/24"]
  }
  private_endpoint = {
    address_prefixes = ["10.1.5.0/24"]
  }
  firewall = {
    address_prefixes = ["10.1.6.0/26"]
  }
}

# Database settings
postgres_version                     = "14"
postgres_admin_username              = "khetiadmin"
postgres_storage_mb                  = 131072
postgres_sku_name                   = "GP_Standard_D2s_v3"
postgres_backup_retention_days       = 35
postgres_geo_redundant_backup_enabled = true
postgres_database_name              = "khetisahayak_prod"

# Redis settings
redis_capacity                            = 1
redis_family                             = "C"
redis_sku_name                          = "Standard"
redis_maxmemory_reserved                = 125
redis_maxmemory_delta                   = 125
redis_maxmemory_policy                  = "allkeys-lru"
redis_maxfragmentationmemory_reserved   = 125

# App Service settings
app_service_sku_name = "P1v3"

# Container Registry
acr_sku = "Premium"

# Static Web App
static_web_app_sku_tier = "Standard"
static_web_app_sku_size = "Standard"

# API Management
apim_sku_name = "Standard_1"

# Monitoring
log_analytics_sku              = "PerGB2018"
log_analytics_retention_days   = 90
application_insights_type      = "web"
application_insights_retention_days = 365

# Custom domains
backend_custom_domain  = "api.khetisahayak.com"
frontend_custom_domain = "app.khetisahayak.com"
api_custom_domain     = "gateway.khetisahayak.com"

# Publisher info
api_publisher_name  = "Kheti Sahayak"
api_publisher_email = "admin@khetisahayak.com"

# CORS settings
cors_allowed_origins = [
  "https://app.khetisahayak.com",
  "https://khetisahayak.com"
]

# Repository settings
repository_url    = "https://github.com/your-org/kheti-sahayak"
repository_branch = "main"

# Log retention
log_retention_days = 365

# Action groups for monitoring
action_groups = {
  "critical-alerts" = {
    short_name = "critical"
    email_receivers = [
      {
        name          = "ops-team"
        email_address = "ops@khetisahayak.com"
      },
      {
        name          = "dev-lead"
        email_address = "dev-lead@khetisahayak.com"
      }
    ]
    sms_receivers = [
      {
        name         = "on-call"
        country_code = "1"
        phone_number = "1234567890"
      }
    ]
    webhook_receivers         = []
    azure_function_receivers  = []
  },
  "warning-alerts" = {
    short_name = "warning"
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
  "critical-cpu" = {
    scopes      = ["PLACEHOLDER_APP_SERVICE_ID"]
    description = "Critical CPU usage alert"
    severity    = 0
    frequency   = "PT1M"
    window_size = "PT5M"
    enabled     = true
    action_group_ids = ["PLACEHOLDER_CRITICAL_ACTION_GROUP_ID"]
    criteria = [
      {
        metric_namespace = "Microsoft.Web/sites"
        metric_name      = "CpuPercentage"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 90
        dimensions       = []
      }
    ]
  },
  "high-cpu" = {
    scopes      = ["PLACEHOLDER_APP_SERVICE_ID"]
    description = "High CPU usage alert"
    severity    = 2
    frequency   = "PT5M"
    window_size = "PT15M"
    enabled     = true
    action_group_ids = ["PLACEHOLDER_WARNING_ACTION_GROUP_ID"]
    criteria = [
      {
        metric_namespace = "Microsoft.Web/sites"
        metric_name      = "CpuPercentage"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 75
        dimensions       = []
      }
    ]
  },
  "high-memory" = {
    scopes      = ["PLACEHOLDER_APP_SERVICE_ID"]
    description = "High memory usage alert"
    severity    = 2
    frequency   = "PT5M"
    window_size = "PT15M"
    enabled     = true
    action_group_ids = ["PLACEHOLDER_WARNING_ACTION_GROUP_ID"]
    criteria = [
      {
        metric_namespace = "Microsoft.Web/sites"
        metric_name      = "MemoryPercentage"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 85
        dimensions       = []
      }
    ]
  },
  "response-time" = {
    scopes      = ["PLACEHOLDER_APP_SERVICE_ID"]
    description = "High response time alert"
    severity    = 2
    frequency   = "PT5M"
    window_size = "PT15M"
    enabled     = true
    action_group_ids = ["PLACEHOLDER_WARNING_ACTION_GROUP_ID"]
    criteria = [
      {
        metric_namespace = "Microsoft.Web/sites"
        metric_name      = "AverageResponseTime"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 5
        dimensions       = []
      }
    ]
  },
  "database-cpu" = {
    scopes      = ["PLACEHOLDER_DATABASE_ID"]
    description = "Database high CPU usage"
    severity    = 1
    frequency   = "PT5M"
    window_size = "PT15M"
    enabled     = true
    action_group_ids = ["PLACEHOLDER_CRITICAL_ACTION_GROUP_ID"]
    criteria = [
      {
        metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
        metric_name      = "cpu_percent"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 80
        dimensions       = []
      }
    ]
  }
}

# Activity log alerts
activity_log_alerts = {
  "resource-health" = {
    scopes           = ["/subscriptions/PLACEHOLDER_SUBSCRIPTION_ID"]
    description      = "Resource health degraded"
    enabled          = true
    operation_name   = "Microsoft.ResourceHealth/healthevent/Activated/action"
    category         = "ResourceHealth"
    level            = "Error"
    status           = "Active"
    sub_status       = ""
    action_group_ids = ["PLACEHOLDER_CRITICAL_ACTION_GROUP_ID"]
    resource_health = {
      current  = ["Degraded", "Unavailable"]
      previous = ["Available"]
      reason   = []
    }
    service_health = null
  }
}

# Security settings
enable_ddos_protection = true

# Tags
tags = {
  Environment = "Production"
  Project     = "Kheti Sahayak"
  Owner       = "Operations Team"
  CostCenter  = "Production"
  Terraform   = "true"
  Backup      = "true"
  Monitoring  = "critical"
}
