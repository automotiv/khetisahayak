terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "kheti-sahayak-terraform-state"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "KhetiSahayak"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  name_prefix = "kheti-sahayak-${var.environment}"
  
  common_tags = {
    Project     = "KhetiSahayak"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

module "vpc" {
  source = "./modules/vpc"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  tags               = local.common_tags
}

module "security_groups" {
  source = "./modules/security_groups"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags
}

module "rds" {
  source = "./modules/rds"

  name_prefix          = local.name_prefix
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_id    = module.security_groups.rds_security_group_id
  db_name              = "kheti_sahayak"
  db_username          = "kheti_admin"
  db_password          = random_password.db_password.result
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  multi_az             = var.environment == "production"
  skip_final_snapshot  = var.environment != "production"
  tags                 = local.common_tags
}

module "elasticache" {
  source = "./modules/elasticache"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.redis_security_group_id
  node_type         = var.redis_node_type
  num_cache_nodes   = var.environment == "production" ? 2 : 1
  tags              = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "ecs" {
  source = "./modules/ecs"

  name_prefix          = local.name_prefix
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  ecs_security_group_id = module.security_groups.ecs_security_group_id
  alb_security_group_id = module.security_groups.alb_security_group_id
  ecr_repository_url   = module.ecr.repository_url
  
  container_cpu    = var.ecs_cpu
  container_memory = var.ecs_memory
  desired_count    = var.ecs_desired_count
  
  environment_variables = {
    NODE_ENV     = var.environment
    DATABASE_URL = "postgresql://${module.rds.db_username}:${random_password.db_password.result}@${module.rds.db_endpoint}/${module.rds.db_name}"
    REDIS_URL    = "redis://${module.elasticache.endpoint}:6379"
    JWT_SECRET   = random_password.jwt_secret.result
    PORT         = "3000"
  }
  
  tags = local.common_tags
}

module "s3" {
  source = "./modules/s3"

  name_prefix     = local.name_prefix
  environment     = var.environment
  allowed_origins = var.cors_allowed_origins
  tags            = local.common_tags
}

module "cloudfront" {
  source = "./modules/cloudfront"
  count  = var.enable_cdn ? 1 : 0

  name_prefix        = local.name_prefix
  s3_bucket_id       = module.s3.bucket_id
  s3_bucket_arn      = module.s3.bucket_arn
  s3_bucket_domain   = module.s3.bucket_regional_domain_name
  alb_domain_name    = module.ecs.alb_dns_name
  acm_certificate_arn = var.acm_certificate_arn
  domain_name        = var.domain_name
  tags               = local.common_tags
}

module "secrets" {
  source = "./modules/secrets"

  name_prefix = local.name_prefix
  secrets = {
    "db-password" = random_password.db_password.result
    "jwt-secret"  = random_password.jwt_secret.result
  }
  tags = local.common_tags
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix         = local.name_prefix
  ecs_cluster_name    = module.ecs.cluster_name
  ecs_service_name    = module.ecs.service_name
  alb_arn_suffix      = module.ecs.alb_arn_suffix
  rds_identifier      = module.rds.db_identifier
  alarm_email         = var.alarm_email
  tags                = local.common_tags
}
