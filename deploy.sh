#!/bin/bash

# Kheti Sahayak Azure Deployment Script
# This script deploys the Kheti Sahayak platform to Azure using Terraform

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Kheti Sahayak Azure Deployment Script

Usage: $0 [OPTIONS] ENVIRONMENT

ENVIRONMENTS:
    dev         Deploy to development environment
    staging     Deploy to staging environment
    prod        Deploy to production environment

OPTIONS:
    -h, --help              Show this help message
    -p, --plan-only         Only run terraform plan, don't apply
    -d, --destroy           Destroy the infrastructure
    -f, --force-unlock      Force unlock terraform state
    -v, --verbose           Enable verbose output
    --skip-checks           Skip prerequisite checks
    --auto-approve          Auto approve terraform apply
    --backend-config FILE   Specify backend configuration file

EXAMPLES:
    $0 dev                          # Deploy to development
    $0 prod --plan-only             # Plan production deployment
    $0 staging --destroy            # Destroy staging environment
    $0 prod --backend-config prod.conf --auto-approve  # Production deployment with auto-approve

PREREQUISITES:
    - Azure CLI installed and logged in
    - Terraform >= 1.0 installed
    - Proper permissions on Azure subscription
    - Backend storage account created (if using remote state)

EOF
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check Terraform version
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_info "Using Terraform version: $TERRAFORM_VERSION"
    
    # Check if environment directory exists
    if [[ ! -d "$TERRAFORM_DIR/environments/$ENVIRONMENT" ]]; then
        log_error "Environment directory not found: $TERRAFORM_DIR/environments/$ENVIRONMENT"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    INIT_ARGS=""
    if [[ -n "$BACKEND_CONFIG" ]]; then
        INIT_ARGS="-backend-config=$BACKEND_CONFIG"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        terraform init $INIT_ARGS
    else
        terraform init $INIT_ARGS > /dev/null
    fi
    
    log_success "Terraform initialized"
}

# Plan deployment
plan_deployment() {
    log_info "Planning Terraform deployment for $ENVIRONMENT..."
    
    cd "$TERRAFORM_DIR"
    
    PLAN_ARGS="-var-file=environments/$ENVIRONMENT/terraform.tfvars"
    if [[ "$DESTROY" == "true" ]]; then
        PLAN_ARGS="$PLAN_ARGS -destroy"
    fi
    
    terraform plan $PLAN_ARGS -out="$ENVIRONMENT.tfplan"
    
    log_success "Terraform plan completed. Plan saved to $ENVIRONMENT.tfplan"
}

# Apply deployment
apply_deployment() {
    log_info "Applying Terraform deployment for $ENVIRONMENT..."
    
    cd "$TERRAFORM_DIR"
    
    APPLY_ARGS=""
    if [[ "$AUTO_APPROVE" == "true" ]]; then
        APPLY_ARGS="-auto-approve"
    fi
    
    if [[ "$DESTROY" == "true" ]]; then
        terraform destroy -var-file=environments/$ENVIRONMENT/terraform.tfvars $APPLY_ARGS
    else
        terraform apply "$ENVIRONMENT.tfplan"
    fi
    
    log_success "Terraform deployment completed"
}

# Force unlock state
force_unlock() {
    log_warning "Force unlocking Terraform state..."
    
    cd "$TERRAFORM_DIR"
    
    echo "Please enter the Lock ID to unlock:"
    read -r LOCK_ID
    
    terraform force-unlock "$LOCK_ID"
    
    log_success "Terraform state unlocked"
}

# Show deployment outputs
show_outputs() {
    log_info "Deployment outputs:"
    
    cd "$TERRAFORM_DIR"
    
    terraform output -json | jq -r '
        to_entries[] | 
        "\(.key): \(.value.value)"
    '
}

# Validate configuration
validate_config() {
    log_info "Validating Terraform configuration..."
    
    cd "$TERRAFORM_DIR"
    terraform validate
    
    log_success "Configuration is valid"
}

# Main deployment process
main() {
    log_info "Starting Kheti Sahayak deployment to $ENVIRONMENT environment"
    
    if [[ "$SKIP_CHECKS" != "true" ]]; then
        check_prerequisites
    fi
    
    if [[ "$FORCE_UNLOCK" == "true" ]]; then
        force_unlock
        exit 0
    fi
    
    init_terraform
    validate_config
    plan_deployment
    
    if [[ "$PLAN_ONLY" != "true" ]]; then
        apply_deployment
        
        if [[ "$DESTROY" != "true" ]]; then
            show_outputs
        fi
    fi
    
    log_success "Deployment process completed successfully!"
}

# Parse command line arguments
ENVIRONMENT=""
PLAN_ONLY="false"
DESTROY="false"
FORCE_UNLOCK="false"
VERBOSE="false"
SKIP_CHECKS="false"
AUTO_APPROVE="false"
BACKEND_CONFIG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--plan-only)
            PLAN_ONLY="true"
            shift
            ;;
        -d|--destroy)
            DESTROY="true"
            shift
            ;;
        -f|--force-unlock)
            FORCE_UNLOCK="true"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        --skip-checks)
            SKIP_CHECKS="true"
            shift
            ;;
        --auto-approve)
            AUTO_APPROVE="true"
            shift
            ;;
        --backend-config)
            BACKEND_CONFIG="$2"
            shift 2
            ;;
        dev|staging|prod)
            ENVIRONMENT="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate environment argument
if [[ -z "$ENVIRONMENT" ]]; then
    log_error "Environment argument is required"
    show_help
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod"
    exit 1
fi

# Run main function
main
