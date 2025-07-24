# Kheti Sahayak Azure Infrastructure Deployment

This directory contains the complete Terraform infrastructure-as-code (IaC) configuration for deploying the Kheti Sahayak platform on Microsoft Azure.

## 🏗️ Architecture Overview

The infrastructure is designed with the following Azure services:

### Core Services
- **Resource Group**: Central container for all resources
- **Virtual Network**: Secure network foundation with multiple subnets
- **App Service Plan**: Managed compute for the backend API
- **App Service**: Node.js backend application hosting
- **Static Web App**: Flutter web frontend hosting
- **PostgreSQL Flexible Server**: Primary database
- **Redis Cache**: Session storage and caching
- **Container Registry**: Docker image storage
- **Storage Account**: File and blob storage

### Security & Monitoring
- **Key Vault**: Secrets and certificate management
- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging
- **Network Security Groups**: Network traffic filtering
- **Private Endpoints**: Secure service communication
- **API Management**: API gateway and management

### Optional Services
- **CDN**: Content delivery network
- **DDoS Protection**: Advanced threat protection
- **Web Application Firewall**: Application layer security
- **Azure Firewall**: Network layer security

## 📁 Directory Structure

```
terraform/
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Variable definitions
├── outputs.tf                  # Output definitions
├── providers.tf                # Provider configurations
├── modules/                    # Reusable Terraform modules
│   ├── networking/             # VNet, subnets, NSGs
│   ├── database/               # PostgreSQL configuration
│   ├── redis/                  # Redis cache configuration
│   ├── storage/                # Storage account configuration
│   ├── key_vault/              # Key Vault configuration
│   ├── app_service_plan/       # App Service Plan configuration
│   ├── app_service/            # App Service configuration
│   ├── container_registry/     # ACR configuration
│   ├── static_web_app/         # Static Web App configuration
│   ├── api_management/         # API Management configuration
│   ├── monitoring/             # Application Insights & Log Analytics
│   ├── security/               # Security services
│   └── cdn/                    # CDN configuration
└── environments/               # Environment-specific configurations
    ├── dev/
    ├── staging/
    └── prod/
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** installed and configured:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Terraform** >= 1.0 installed:
   ```bash
   # macOS
   brew install terraform
   
   # Windows
   choco install terraform
   
   # Linux
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   sudo apt-get update && sudo apt-get install terraform
   ```

3. **Required Azure permissions**:
   - Contributor or Owner role on the subscription
   - Ability to create service principals (for CI/CD)

### Basic Deployment

1. **Clone and navigate to the project**:
   ```bash
   git clone <repository-url>
   cd kheti-sahayak/terraform
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Deploy to development environment**:
   ```bash
   # Using the deployment script (recommended)
   ../deploy.sh dev
   
   # Or using Terraform directly
   terraform plan -var-file=environments/dev/terraform.tfvars
   terraform apply -var-file=environments/dev/terraform.tfvars
   ```

### Using the Deployment Script

The `deploy.sh` script provides a convenient wrapper around Terraform:

```bash
# Plan development deployment
./deploy.sh dev --plan-only

# Deploy to development
./deploy.sh dev

# Deploy to production with auto-approve
./deploy.sh prod --auto-approve

# Destroy staging environment
./deploy.sh staging --destroy

# Force unlock state
./deploy.sh dev --force-unlock
```

## 🔧 Configuration

### Environment Variables

Set these environment variables or create a `.env` file:

```bash
# Required
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# For service principal authentication (CI/CD)
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"

# Database credentials
export TF_VAR_postgres_admin_password="secure-password"

# Custom domains (production)
export TF_VAR_backend_custom_domain="api.khetisahayak.com"
export TF_VAR_frontend_custom_domain="app.khetisahayak.com"
```

### Backend Configuration

For remote state storage, create a backend configuration file:

```hcl
# backend.conf
resource_group_name  = "terraform-state-rg"
storage_account_name = "terraformstate12345"
container_name       = "tfstate"
key                  = "kheti-sahayak/terraform.tfstate"
```

Then initialize with the backend:

```bash
terraform init -backend-config=backend.conf
```

## 🌍 Environments

### Development Environment
- **Purpose**: Development and testing
- **Resources**: Minimal, cost-optimized
- **Database**: Basic tier PostgreSQL
- **App Service**: B1 plan
- **Monitoring**: Basic alerts

### Staging Environment
- **Purpose**: Pre-production testing
- **Resources**: Production-like but smaller
- **Database**: General Purpose tier
- **App Service**: S1 plan
- **Monitoring**: Full monitoring setup

### Production Environment
- **Purpose**: Live application
- **Resources**: High availability, scalable
- **Database**: General Purpose with geo-backup
- **App Service**: P1v3 plan with auto-scaling
- **Monitoring**: Comprehensive monitoring and alerting
- **Security**: Enhanced security features enabled

## 🔐 Security Considerations

### Network Security
- All resources deployed in a virtual network
- Private endpoints for database and cache
- Network Security Groups with restrictive rules
- Optional Azure Firewall for advanced protection

### Data Protection
- TLS 1.2+ enforced for all connections
- Secrets stored in Azure Key Vault
- Database encrypted at rest and in transit
- Regular automated backups

### Access Control
- Managed identities used where possible
- Role-based access control (RBAC)
- Principle of least privilege
- Audit logging enabled

### Compliance
- Data residency controls
- Retention policies configured
- Security Center recommendations followed

## 📊 Monitoring and Alerting

### Application Insights
- Application performance monitoring
- Custom telemetry and metrics
- Availability tests
- Performance counters

### Log Analytics
- Centralized log collection
- Custom queries and dashboards
- Integration with Azure Monitor

### Alerting
- Metric alerts for performance thresholds
- Activity log alerts for infrastructure changes
- Action groups for notification routing
- Escalation policies

## 💰 Cost Optimization

### Development Environment
- Basic/Standard tiers for most services
- Minimal compute resources
- Shorter retention periods
- Manual scaling

### Production Environment
- Reserved instances where applicable
- Auto-scaling based on demand
- Cost alerts and budgets
- Regular cost reviews

### Cost Monitoring
- Azure Cost Management integration
- Resource tagging for cost allocation
- Budget alerts
- Spending forecasts

## 🔄 CI/CD Integration

### Azure DevOps
```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop

variables:
  - group: terraform-secrets

stages:
- stage: Plan
  jobs:
  - job: TerraformPlan
    steps:
    - task: TerraformInstaller@0
    - task: TerraformTaskV3@3
      inputs:
        provider: 'azurerm'
        command: 'init'
        backendServiceArm: 'azure-connection'
        backendAzureRmResourceGroupName: 'terraform-state-rg'
        backendAzureRmStorageAccountName: 'terraformstate12345'
        backendAzureRmContainerName: 'tfstate'
        backendAzureRmKey: 'kheti-sahayak.tfstate'
    - task: TerraformTaskV3@3
      inputs:
        provider: 'azurerm'
        command: 'plan'
        commandOptions: '-var-file=environments/$(environment)/terraform.tfvars'
        environmentServiceNameAzureRM: 'azure-connection'
```

### GitHub Actions
```yaml
# .github/workflows/terraform.yml
name: 'Terraform'

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    
    - name: Terraform Init
      run: terraform init
      env:
        ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
    
    - name: Terraform Plan
      run: terraform plan -var-file=environments/dev/terraform.tfvars
```

## 🛠️ Troubleshooting

### Common Issues

1. **Authentication Errors**:
   ```bash
   # Re-login to Azure
   az login --tenant your-tenant-id
   
   # Clear Terraform cache
   rm -rf .terraform
   terraform init
   ```

2. **State Lock Issues**:
   ```bash
   # List locks
   terraform force-unlock <lock-id>
   
   # Or use the deployment script
   ./deploy.sh dev --force-unlock
   ```

3. **Resource Naming Conflicts**:
   - Ensure unique name_prefix in variables
   - Check for existing resources with the same name
   - Review naming conventions

4. **Network Connectivity Issues**:
   - Verify subnet configurations
   - Check Network Security Group rules
   - Confirm private endpoint configurations

### Debug Mode
Enable verbose logging:
```bash
export TF_LOG=DEBUG
terraform plan -var-file=environments/dev/terraform.tfvars
```

### Validation
```bash
# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Security scan
checkov -f main.tf
```

## 📝 Best Practices

### Code Organization
- Use modules for reusable components
- Separate environments with different variable files
- Follow consistent naming conventions
- Use tags for resource organization

### State Management
- Use remote state storage
- Enable state locking
- Regular state backups
- Separate state files per environment

### Security
- Store secrets in Key Vault
- Use managed identities
- Enable audit logging
- Regular security reviews

### Monitoring
- Set up comprehensive alerting
- Use structured logging
- Monitor costs and usage
- Regular performance reviews

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request
5. Ensure all checks pass

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Contact the development team
- Review the troubleshooting guide
- Check Azure documentation

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
