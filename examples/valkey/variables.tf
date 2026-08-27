variable "region" {
  description = "AWS Region in which to create the Valkey serverless cache."
  type        = string
  default     = "eu-west-2"
}

variable "name" {
  description = "Valkey serverless cache name."
  type        = string
  default     = "example-valkey"
}

variable "major_engine_version" {
  description = "Valkey major engine version available for serverless caches in the selected Region."
  type        = string
}

variable "subnet_ids" {
  description = "Existing private subnet IDs used directly by the serverless cache endpoint."
  type        = set(string)
}

variable "security_group_ids" {
  description = "Existing security group IDs that permit Valkey client traffic."
  type        = set(string)
}

variable "tags" {
  description = "Tags applied to example resources."
  type        = map(string)
  default = {
    Environment = "example"
    Engine      = "Valkey"
  }
}
