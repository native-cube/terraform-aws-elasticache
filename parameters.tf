resource "aws_elasticache_parameter_group" "main" {
  count = local.create_parameter_group ? 1 : 0

  name        = coalesce(var.parameter_group_name, "${var.name}-parameters")
  region      = var.region
  family      = var.parameter_group_family
  description = var.parameter_group_description
  tags        = merge(local.common_tags, var.parameter_group_tags)

  dynamic "parameter" {
    for_each = var.parameters

    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  lifecycle {
    precondition {
      condition     = var.parameter_group_family != null && trimspace(var.parameter_group_family) != ""
      error_message = "parameter_group_family is required when create_parameter_group is true."
    }
  }
}
