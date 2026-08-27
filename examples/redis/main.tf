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

module "redis" {
  source = "../.."

  name            = var.name
  deployment_type = "replication_group"
  description     = "Redis OSS replication group example"
  engine          = "redis"
  engine_version  = var.engine_version
  node_type       = var.node_type
  port            = 6379

  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  snapshot_retention_limit   = 7

  create_parameter_group = true
  parameter_group_family = var.parameter_group_family

  create_subnet_group = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  tags = var.tags
}
