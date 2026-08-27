variable "primary_region" {
  description = "AWS Region for the writable primary replication group and global replication group resource."
  type        = string
  default     = "eu-west-2"
}

variable "secondary_region" {
  description = "Different AWS Region for the read-only secondary replication group."
  type        = string
  default     = "eu-west-1"
}

variable "name" {
  description = "Name prefix and global replication group ID suffix. Keep this at 30 characters or fewer so member names remain valid."
  type        = string
  default     = "example-global-redis"

  validation {
    condition = (
      can(regex("^[a-z][a-z0-9-]{0,29}$", var.name)) &&
      !endswith(var.name, "-") &&
      !strcontains(var.name, "--")
    )
    error_message = "name must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, not end with or contain consecutive hyphens, and be at most 30 characters."
  }
}

variable "engine_version" {
  description = "Redis OSS engine version available in both selected Regions."
  type        = string
}

variable "node_type" {
  description = "Redis OSS cache node type available in both selected Regions."
  type        = string
  default     = "cache.r7g.large"
}

variable "primary_subnet_ids" {
  description = "Existing private subnet IDs in primary_region."
  type        = set(string)
}

variable "secondary_subnet_ids" {
  description = "Existing private subnet IDs in secondary_region."
  type        = set(string)
}

variable "primary_security_group_ids" {
  description = "Existing security group IDs in primary_region that permit Redis OSS client traffic."
  type        = set(string)
}

variable "secondary_security_group_ids" {
  description = "Existing security group IDs in secondary_region that permit Redis OSS client traffic."
  type        = set(string)
}

variable "tags" {
  description = "Tags applied to example resources that support tagging."
  type        = map(string)
  default = {
    Environment = "example"
    Topology    = "global"
  }
}
