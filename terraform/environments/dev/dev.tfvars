# Development Environment - Simplified Configuration

# Environment settings
environment = "dev"
location    = "East US"

# Database settings
postgres_admin_username              = "khetiadmin"
postgres_storage_mb                  = 32768
postgres_sku_name                   = "B_Standard_B1ms"
postgres_backup_retention_days       = 7
postgres_geo_redundant_backup_enabled = false
postgres_database_name              = "khetisahayak_dev"

# Redis settings
redis_capacity = 0
redis_family   = "C"
redis_sku_name = "Basic"

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
log_retention_days = 30

# Custom domains (empty for dev)
backend_custom_domain  = ""
frontend_custom_domain = ""
api_custom_domain     = ""

# Repository settings
repository_url    = "https://github.com/automotiv/khetisahayak"
repository_branch = "main"

# CORS settings
cors_allowed_origins = ["*"]
