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
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

module "primary" {
  source = "../.."

  providers = {
    aws = aws.primary
  }

  name            = "${var.name}-primary"
  deployment_type = "replication_group"
  description     = "Primary Redis OSS replication group"
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

  create_subnet_group = true
  subnet_ids          = var.primary_subnet_ids
  security_group_ids  = var.primary_security_group_ids

  create_global_replication_group      = true
  global_replication_group_id_suffix   = var.name
  global_replication_group_description = "Multi-Region Redis OSS global datastore"

  tags = var.tags
}

module "secondary" {
  source = "../.."

  providers = {
    aws = aws.secondary
  }

  name                        = "${var.name}-secondary"
  deployment_type             = "replication_group"
  description                 = "Secondary Redis OSS replication group"
  global_replication_group_id = module.primary.global_replication_group_id
  num_cache_clusters          = 2

  create_subnet_group = true
  subnet_ids          = var.secondary_subnet_ids
  security_group_ids  = var.secondary_security_group_ids

  tags = var.tags
}
