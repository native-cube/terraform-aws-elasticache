terraform {
  required_version = ">= 1.11.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.62.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "memcached" {
  source = "../.."

  name                        = var.name
  deployment_type             = "cluster"
  enforce_security_baseline   = true
  enforce_resilience_baseline = true
  engine                      = "memcached"
  engine_version              = var.engine_version
  node_type                   = var.node_type
  num_cache_nodes             = 2
  az_mode                     = "cross-az"
  port                        = 11211

  transit_encryption_enabled = true

  create_parameter_group = true
  parameter_group_family = var.parameter_group_family

  create_subnet_group = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  tags = var.tags
}
