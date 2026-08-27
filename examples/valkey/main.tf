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

module "valkey" {
  source = "../.."

  name                 = var.name
  deployment_type      = "serverless"
  description          = "Valkey serverless cache example"
  engine               = "valkey"
  major_engine_version = var.major_engine_version

  subnet_ids               = var.subnet_ids
  security_group_ids       = var.security_group_ids
  snapshot_retention_limit = 7

  cache_usage_limits = {
    data_storage = {
      minimum = 1
      maximum = 10
    }
    ecpu_per_second = {
      minimum = 1000
      maximum = 5000
    }
  }

  tags = var.tags
}
