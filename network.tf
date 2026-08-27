resource "aws_elasticache_subnet_group" "main" {
  count = local.create_subnet_group ? 1 : 0

  name        = coalesce(var.subnet_group_name, "${var.name}-subnets")
  region      = var.region
  description = var.subnet_group_description
  subnet_ids  = var.subnet_ids
  tags        = merge(local.common_tags, var.subnet_group_tags)

  lifecycle {
    precondition {
      condition     = length(var.subnet_ids) > 0
      error_message = "subnet_ids must contain at least one subnet when create_subnet_group is true."
    }
  }
}
