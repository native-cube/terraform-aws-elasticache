variable "region" {
  description = "AWS Region in which to create the Memcached cluster."
  type        = string
  default     = "eu-west-2"
}

variable "name" {
  description = "Memcached cluster name."
  type        = string
  default     = "example-memcached"
}

variable "engine_version" {
  description = "Memcached engine version available in the selected Region."
  type        = string
}

variable "parameter_group_family" {
  description = "Parameter group family compatible with engine_version."
  type        = string
  default     = "memcached1.6"
}

variable "node_type" {
  description = "Memcached cache node type."
  type        = string
  default     = "cache.t4g.small"
}

variable "subnet_ids" {
  description = "Existing private subnet IDs for the cache subnet group."
  type        = set(string)
}

variable "security_group_ids" {
  description = "Existing security group IDs that permit Memcached client traffic."
  type        = set(string)
}

variable "tags" {
  description = "Tags applied to example resources."
  type        = map(string)
  default = {
    Environment = "example"
    Engine      = "Memcached"
  }
}
