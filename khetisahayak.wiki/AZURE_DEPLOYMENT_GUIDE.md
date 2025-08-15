# Azure Deployment Guide for Kheti Sahayak

## 🚀 Overview

This guide provides step-by-step instructions for deploying the Kheti Sahayak platform to Microsoft Azure using Terraform. The deployment creates a complete, production-ready infrastructure with all necessary Azure services.

## 📋 Prerequisites

### 1. Required Tools

Install the following tools on your local machine:

#### Azure CLI
```bash
# macOS
brew install azure-cli

# Windows (using Chocolatey)
choco install azure-cli

# Windows (using MSI)
# Download from: https://aka.ms/installazurecliwindows

# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### Terraform
```bash
# macOS
brew install terraform

# Windows (using Chocolatey)
choco install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### Additional Tools (Optional)
```bash
# jq for JSON processing
brew install jq  # macOS
sudo apt-get install jq  # Linux

# Git for version control
# Usually pre-installed or available through package managers
```

### 2. Azure Account Setup

#### Login to Azure
```bash
az login
```

#### Set Default Subscription
```bash
# List available subscriptions
az account list --output table

# Set default subscription
az account set --subscription "Your Subscription Name or ID"

# Verify current subscription
az account show
```

#### Create Service Principal (For CI/CD)
```bash
# Create service principal with Contributor role
az ad sp create-for-rbac --name "kheti-sahayak-terraform" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Save the output - you'll need these values:
# {
#   "appId": "client-id",
#   "displayName": "kheti-sahayak-terraform",
#   "password": "client-secret",
#   "tenant": "tenant-id"
# }
```

## 🏗️ Infrastructure Setup

### 1. Clone Repository
```bash
git clone <your-repository-url>
cd kheti-sahayak
```

### 2. Environment Configuration

#### Set Environment Variables
Create a `.env` file or set environment variables:

```bash
# Required for Terraform
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# For CI/CD with service principal
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"

# Database password (generate a secure password)
export TF_VAR_postgres_admin_password="YourSecurePassword123!"

# Custom domains (for production)
export TF_VAR_backend_custom_domain="api.yourdomain.com"
export TF_VAR_frontend_custom_domain="app.yourdomain.com"
export TF_VAR_api_custom_domain="gateway.yourdomain.com"

# API Management publisher details
export TF_VAR_api_publisher_name="Your Organization"
export TF_VAR_api_publisher_email="admin@yourdomain.com"
```

#### Load Environment Variables
```bash
# On Linux/macOS
source .env

# On Windows (PowerShell)
Get-Content .env | ForEach-Object { $name, $value = $_.split('='); Set-Variable -Name $name -Value $value }
```

### 3. Backend State Configuration (Recommended)

#### Create Storage Account for Terraform State
```bash
# Variables
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="terraformstate$(date +%s)"
CONTAINER_NAME="tfstate"
LOCATION="East US"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION"

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME
```

#### Create Backend Configuration
Create `terraform/backend.conf`:
```hcl
resource_group_name  = "terraform-state-rg"
storage_account_name = "your-storage-account-name"
container_name       = "tfstate"
key                  = "kheti-sahayak.tfstate"
```

## 🚀 Deployment Process

### 1. Development Environment Deployment

#### Initialize Terraform
```bash
cd terraform

# Without remote backend
terraform init

# With remote backend
terraform init -backend-config=backend.conf
```

#### Plan Deployment
```bash
# Using deployment script (recommended)
../deploy.sh dev --plan-only

# Using Terraform directly
terraform plan -var-file=environments/dev/terraform.tfvars -out=dev.tfplan
```

#### Apply Deployment
```bash
# Using deployment script
../deploy.sh dev

# Using Terraform directly
terraform apply dev.tfplan
```

#### Verify Deployment
```bash
# Get outputs
terraform output

# Check resource group
az group show --name "kheti-sahayak-dev-rg"

# List all resources
az resource list --resource-group "kheti-sahayak-dev-rg" --output table
```

### 2. Production Environment Deployment

#### Update Production Configuration
Edit `terraform/environments/prod/terraform.tfvars`:
- Set appropriate resource sizes
- Configure custom domains
- Set up monitoring and alerting
- Enable security features

#### Deploy to Production
```bash
# Plan production deployment
../deploy.sh prod --plan-only

# Review plan carefully
# Deploy to production
../deploy.sh prod --auto-approve
```

## 🔧 Post-Deployment Configuration

### 1. Database Setup

#### Connect to Database
```bash
# Get database connection details
PGHOST=$(terraform output -raw database_server_fqdn)
PGUSER="khetiadmin"
PGDATABASE="khetisahayak_dev"

# Connect using psql
psql "sslmode=require host=$PGHOST dbname=$PGDATABASE user=$PGUSER"
```

#### Run Migrations
```bash
# Navigate to backend directory
cd ../kheti_sahayak_backend

# Install dependencies
npm install

# Run database migrations
npm run migrate

# Seed initial data
npm run seed
```

### 2. Application Deployment

#### Build and Push Docker Images
```bash
# Get container registry details
ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server)
ACR_USERNAME=$(terraform output -raw container_registry_admin_username)

# Login to container registry
az acr login --name $(echo $ACR_LOGIN_SERVER | cut -d'.' -f1)

# Build and push backend image
cd ../kheti_sahayak_backend
docker build -t $ACR_LOGIN_SERVER/khetisahayak-backend:latest .
docker push $ACR_LOGIN_SERVER/khetisahayak-backend:latest
```

#### Deploy Frontend
```bash
# Navigate to frontend directory
cd ../kheti_sahayak_app

# Build Flutter web app
flutter build web

# Deploy to Static Web App using Azure CLI
STATIC_WEB_APP_NAME=$(terraform output -raw static_web_app_name)
az staticwebapp create \
  --name $STATIC_WEB_APP_NAME \
  --source ./build/web \
  --location "East US2"
```

### 3. Configure Custom Domains (Production)

#### Add Custom Domain to App Service
```bash
# Get App Service name
APP_SERVICE_NAME=$(terraform output -raw backend_app_service_name)

# Add custom domain
az webapp config hostname add \
  --webapp-name $APP_SERVICE_NAME \
  --resource-group "kheti-sahayak-prod-rg" \
  --hostname "api.yourdomain.com"

# Enable SSL
az webapp config ssl bind \
  --name $APP_SERVICE_NAME \
  --resource-group "kheti-sahayak-prod-rg" \
  --certificate-thumbprint "certificate-thumbprint" \
  --ssl-type SNI
```

#### Configure DNS Records
Add the following DNS records to your domain:
```
api.yourdomain.com      CNAME   your-app-service.azurewebsites.net
app.yourdomain.com      CNAME   your-static-web-app.azurestaticapps.net
gateway.yourdomain.com  CNAME   your-api-management.azure-api.net
```

### 4. Security Configuration

#### Configure Key Vault Access
```bash
# Get Key Vault URI
KEY_VAULT_URI=$(terraform output -raw key_vault_uri)

# Add secrets
az keyvault secret set --vault-name "your-key-vault" --name "jwt-secret" --value "your-jwt-secret"
az keyvault secret set --vault-name "your-key-vault" --name "api-key" --value "your-api-key"
```

#### Configure Network Security
```bash
# Update Network Security Group rules if needed
az network nsg rule create \
  --resource-group "kheti-sahayak-prod-rg" \
  --nsg-name "kheti-sahayak-prod-nsg" \
  --name "AllowHTTPS" \
  --protocol Tcp \
  --priority 100 \
  --destination-port-range 443 \
  --source-address-prefixes '*' \
  --destination-address-prefixes '*' \
  --access Allow \
  --direction Inbound
```

## 📊 Monitoring and Alerting

### 1. Configure Application Insights
```bash
# Get Application Insights connection string
APP_INSIGHTS_CONNECTION_STRING=$(terraform output -raw application_insights_connection_string)

# Update application configuration with connection string
# This will be automatically set through Key Vault integration
```

### 2. Set Up Alerts
```bash
# Create action group
az monitor action-group create \
  --name "kheti-sahayak-alerts" \
  --resource-group "kheti-sahayak-prod-rg" \
  --short-name "KhetiAlerts" \
  --email admin admin@yourdomain.com

# Create metric alert for high CPU
az monitor metrics alert create \
  --name "HighCPUAlert" \
  --resource-group "kheti-sahayak-prod-rg" \
  --scopes $(terraform output -raw backend_app_service_id) \
  --condition "avg CpuPercentage > 80" \
  --description "High CPU usage alert" \
  --severity 2 \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action kheti-sahayak-alerts
```

## 🔍 Validation and Testing

### 1. Health Checks
```bash
# Test backend API
BACKEND_URL=$(terraform output -raw backend_url)
curl -f "$BACKEND_URL/api/health"

# Test frontend
FRONTEND_URL=$(terraform output -raw frontend_url)
curl -f "$FRONTEND_URL"

# Test API Management
API_GATEWAY_URL=$(terraform output -raw api_management_gateway_url)
curl -f "$API_GATEWAY_URL/health"
```

### 2. Database Connectivity
```bash
# Test database connection
psql "$(terraform output -raw database_connection_string)" -c "SELECT version();"
```

### 3. Redis Connectivity
```bash
# Test Redis connection (requires redis-cli)
redis-cli -h $(terraform output -raw redis_hostname) -p 6380 -a "$(terraform output -raw redis_primary_access_key)" --tls ping
```

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### 1. Authentication Issues
```bash
# Clear Azure CLI cache
az account clear
az login

# Re-authenticate Terraform
rm -rf .terraform
terraform init
```

#### 2. Resource Naming Conflicts
```bash
# Check existing resources
az resource list --name "*kheti*" --output table

# Use different name prefix in variables
export TF_VAR_name_prefix="kheti-sahayak-$(date +%s)"
```

#### 3. State Lock Issues
```bash
# Force unlock (use carefully)
terraform force-unlock <lock-id>

# Or use deployment script
../deploy.sh dev --force-unlock
```

#### 4. Network Connectivity Issues
```bash
# Check NSG rules
az network nsg show --resource-group "kheti-sahayak-dev-rg" --name "kheti-sahayak-dev-nsg"

# Test network connectivity
az network watcher test-connectivity \
  --source-resource $(terraform output -raw backend_app_service_id) \
  --dest-address $(terraform output -raw database_server_fqdn) \
  --dest-port 5432
```

### Debug Mode
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run Terraform with debug logging
terraform plan -var-file=environments/dev/terraform.tfvars
```

## 🔄 Maintenance and Updates

### 1. Regular Updates
```bash
# Update Terraform providers
terraform init -upgrade

# Plan and apply updates
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply
```

### 2. Backup and Recovery
```bash
# Export Terraform state
terraform state pull > terraform-state-backup.json

# Backup Key Vault secrets
az keyvault secret backup --vault-name "your-key-vault" --name "jwt-secret" --file jwt-secret.backup
```

### 3. Scaling
```bash
# Scale App Service Plan
az appservice plan update \
  --name "kheti-sahayak-prod-asp" \
  --resource-group "kheti-sahayak-prod-rg" \
  --sku P2v3

# Scale database
az postgres flexible-server update \
  --resource-group "kheti-sahayak-prod-rg" \
  --name "kheti-sahayak-prod-psql" \
  --sku-name GP_Standard_D4s_v3
```

## 📞 Support and Resources

### Getting Help
- Review logs in Azure Portal
- Check Application Insights for application errors
- Review Terraform documentation
- Contact the development team

### Useful Resources
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)

## 📝 Next Steps

After successful deployment:
1. Set up CI/CD pipelines
2. Configure monitoring dashboards
3. Implement backup strategies
4. Set up disaster recovery
5. Conduct security reviews
6. Performance optimization
7. Cost optimization review
