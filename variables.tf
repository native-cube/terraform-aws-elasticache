variable "name" {
  description = "ElastiCache deployment identifier and prefix for module-created supporting resources."
  type        = string

  validation {
    condition = (
      can(regex("^[a-z][a-z0-9-]{0,49}$", var.name)) &&
      (var.deployment_type == "cluster" || length(var.name) <= 40) &&
      !endswith(var.name, "-") &&
      !strcontains(var.name, "--")
    )
    error_message = "name must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, not end with or contain consecutive hyphens, and be at most 50 characters for clusters or 40 for replication groups and serverless caches."
  }
}

variable "deployment_type" {
  description = "ElastiCache deployment to create: cluster, replication_group, or serverless. Use separate module calls for multiple independent deployments."
  type        = string

  validation {
    condition     = contains(["cluster", "replication_group", "serverless"], var.deployment_type)
    error_message = "deployment_type must be cluster, replication_group, or serverless."
  }
}

variable "create" {
  description = "Whether to create the selected ElastiCache deployment and module-managed supporting resources."
  type        = bool
  default     = true
}

variable "enforce_security_baseline" {
  description = "Whether to reject deployments without explicit VPC networking, encryption, and supported authentication controls. Global secondaries may inherit encryption and authentication from the primary."
  type        = bool
  default     = false
}

variable "enforce_resilience_baseline" {
  description = "Whether to require resilient topology and backups appropriate to the selected deployment type."
  type        = bool
  default     = false
}

variable "region" {
  description = "Optional AWS Region for module-managed resources. Null uses the Region configured on the AWS provider."
  type        = string
  default     = null
}

variable "engine" {
  description = "Cache engine. Clusters support memcached or redis, replication groups support redis or valkey, and serverless supports all three. May be omitted for inherited replication-group resources."
  type        = string
  default     = null

  validation {
    condition     = var.engine == null || contains(["memcached", "redis", "valkey"], lower(var.engine))
    error_message = "engine must be memcached, redis, valkey, or null for an inherited deployment."
  }
}

variable "engine_version" {
  description = "Engine version for a provisioned cluster or replication group. Specify explicitly in production so upgrades are deliberate."
  type        = string
  default     = null
}

variable "major_engine_version" {
  description = "Major engine version for a serverless cache."
  type        = string
  default     = null
}

variable "description" {
  description = "Description for a replication group or serverless cache."
  type        = string
  default     = "Managed by Terraform"

  validation {
    condition     = var.description != null && trimspace(var.description) != ""
    error_message = "description must not be empty."
  }
}

variable "node_type" {
  description = "Cache node type for a provisioned cluster or replication group."
  type        = string
  default     = null
}

variable "port" {
  description = "Port on which provisioned cache nodes accept connections. AWS defaults to 11211 for Memcached and 6379 for Redis OSS or Valkey."
  type        = number
  default     = null

  validation {
    condition     = var.port == null || (floor(var.port) == var.port && var.port >= 1 && var.port <= 65535)
    error_message = "port must be an integer from 1 to 65535."
  }
}

variable "apply_immediately" {
  description = "Whether provisioned cache modifications are applied immediately instead of during the next maintenance window."
  type        = bool
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Whether eligible minor engine upgrades are applied automatically to provisioned cache nodes."
  type        = bool
  default     = null
}

variable "maintenance_window" {
  description = "Weekly maintenance window for a provisioned cluster or replication group, in UTC ddd:hh24:mi-ddd:hh24:mi format."
  type        = string
  default     = null

  validation {
    condition = var.maintenance_window == null || can(regex(
      "^(mon|tue|wed|thu|fri|sat|sun):([01][0-9]|2[0-3]):[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):([01][0-9]|2[0-3]):[0-5][0-9]$",
      var.maintenance_window
    ))
    error_message = "maintenance_window must use the UTC format ddd:hh:mm-ddd:hh:mm."
  }
}

variable "network_type" {
  description = "IP protocol type for cache connections: ipv4, ipv6, or dual_stack."
  type        = string
  default     = null

  validation {
    condition     = var.network_type == null || contains(["ipv4", "ipv6", "dual_stack"], var.network_type)
    error_message = "network_type must be ipv4, ipv6, dual_stack, or null."
  }
}

variable "ip_discovery" {
  description = "IP version advertised in the discovery protocol for a provisioned cluster or replication group: ipv4 or ipv6."
  type        = string
  default     = null

  validation {
    condition     = var.ip_discovery == null || contains(["ipv4", "ipv6"], var.ip_discovery)
    error_message = "ip_discovery must be ipv4, ipv6, or null."
  }
}

variable "security_group_ids" {
  description = "VPC security group IDs associated with the selected cache deployment."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for security_group_id in var.security_group_ids : security_group_id != null && trimspace(security_group_id) != ""])
    error_message = "security_group_ids must contain only non-empty security group IDs."
  }
}

variable "security_group_names" {
  description = "Legacy cache security group names associated with a replication group. Prefer security_group_ids for VPC deployments."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for security_group_name in var.security_group_names : security_group_name != null && trimspace(security_group_name) != ""])
    error_message = "security_group_names must contain only non-empty security group names."
  }
}

variable "notification_topic_arn" {
  description = "SNS topic ARN that receives notifications from a provisioned cluster or replication group."
  type        = string
  default     = null
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier for a Redis OSS cluster or Redis OSS/Valkey replication group. Null skips a final snapshot."
  type        = string
  default     = null

  validation {
    condition     = var.final_snapshot_identifier == null || trimspace(var.final_snapshot_identifier) != ""
    error_message = "final_snapshot_identifier must be null or a non-empty identifier."
  }
}

variable "snapshot_arns" {
  description = "Redis RDB snapshot ARNs used to restore a provisioned cluster or replication group. Clusters accept one ARN."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for snapshot_arn in var.snapshot_arns : snapshot_arn != null && trimspace(snapshot_arn) != ""])
    error_message = "snapshot_arns must contain only non-empty ARNs."
  }
}

variable "snapshot_name" {
  description = "Snapshot name from which to restore a provisioned cluster or replication group."
  type        = string
  default     = null

  validation {
    condition     = var.snapshot_name == null || trimspace(var.snapshot_name) != ""
    error_message = "snapshot_name must be null or a non-empty name."
  }
}

variable "snapshot_retention_limit" {
  description = "Number of automatic snapshots retained for the selected deployment. Zero disables provisioned-cache backups."
  type        = number
  default     = null

  validation {
    condition     = var.snapshot_retention_limit == null || (floor(var.snapshot_retention_limit) == var.snapshot_retention_limit && var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35)
    error_message = "snapshot_retention_limit must be an integer from 0 to 35 or null."
  }
}

variable "snapshot_window" {
  description = "Daily UTC snapshot window for a provisioned cluster or replication group."
  type        = string
  default     = null

  validation {
    condition = var.snapshot_window == null || can(regex(
      "^([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]$",
      var.snapshot_window
    ))
    error_message = "snapshot_window must use the UTC format hh:mm-hh:mm."
  }
}

variable "log_delivery_configuration" {
  description = "Log delivery configurations for a Redis OSS cluster or Redis OSS/Valkey replication group. A maximum of one engine log and one slow log is supported."
  type = set(object({
    destination      = string
    destination_type = string
    log_format       = string
    log_type         = string
  }))
  default = []

  validation {
    condition = (
      length(var.log_delivery_configuration) <= 2 &&
      length(distinct([for configuration in var.log_delivery_configuration : configuration.log_type])) == length(var.log_delivery_configuration) &&
      alltrue([
        for configuration in var.log_delivery_configuration :
        configuration.destination != null && trimspace(configuration.destination) != "" &&
        contains(["cloudwatch-logs", "kinesis-firehose"], configuration.destination_type) &&
        contains(["json", "text"], configuration.log_format) &&
        contains(["engine-log", "slow-log"], configuration.log_type)
      ])
    )
    error_message = "log_delivery_configuration supports at most one engine-log and one slow-log using cloudwatch-logs or kinesis-firehose and json or text format."
  }
}

variable "num_cache_nodes" {
  description = "Number of nodes in a standalone cluster. Redis OSS requires one; Memcached supports 1-40."
  type        = number
  default     = null

  validation {
    condition     = var.num_cache_nodes == null || (floor(var.num_cache_nodes) == var.num_cache_nodes && var.num_cache_nodes >= 1)
    error_message = "num_cache_nodes must be a positive integer or null."
  }
}

variable "availability_zone" {
  description = "Availability Zone for a provisioned cluster. Conflicts with preferred_availability_zones."
  type        = string
  default     = null
}

variable "az_mode" {
  description = "Memcached cluster Availability Zone mode: single-az or cross-az."
  type        = string
  default     = null

  validation {
    condition     = var.az_mode == null || contains(["single-az", "cross-az"], var.az_mode)
    error_message = "az_mode must be single-az, cross-az, or null."
  }
}

variable "preferred_availability_zones" {
  description = "Ordered Availability Zones for Memcached cluster nodes. The list length must equal num_cache_nodes."
  type        = list(string)
  default     = null
}

variable "outpost_mode" {
  description = "Outpost mode for a Memcached cluster: single-outpost or cross-outpost."
  type        = string
  default     = null

  validation {
    condition     = var.outpost_mode == null || contains(["single-outpost", "cross-outpost"], var.outpost_mode)
    error_message = "outpost_mode must be single-outpost, cross-outpost, or null."
  }
}

variable "preferred_outpost_arn" {
  description = "Preferred Outpost ARN for a Memcached cluster. Required when outpost_mode is set."
  type        = string
  default     = null
}

variable "cluster_replication_group_id" {
  description = "Existing replication group ID to which a deployment_type = cluster resource is attached as a read replica. Standalone cluster settings are inherited when this is set."
  type        = string
  default     = null
}

variable "transit_encryption_enabled" {
  description = "Whether in-transit encryption is enabled. For standalone clusters the AWS provider supports this only for eligible Memcached versions."
  type        = bool
  default     = null
}

variable "at_rest_encryption_enabled" {
  description = "Whether encryption at rest is enabled for a replication group."
  type        = bool
  default     = null
}

variable "kms_key_id" {
  description = "Customer-managed KMS key ARN for replication-group or serverless-cache encryption at rest."
  type        = string
  default     = null
}

variable "auth_token" {
  description = "Legacy Redis OSS/Valkey AUTH token. This sensitive value is stored in Terraform state; prefer auth_token_wo."
  type        = string
  default     = null
  sensitive   = true
}

variable "auth_token_update_strategy" {
  description = "Strategy used when changing a replication-group AUTH token: SET, ROTATE, or DELETE."
  type        = string
  default     = null

  validation {
    condition     = var.auth_token_update_strategy == null || contains(["DELETE", "ROTATE", "SET"], upper(var.auth_token_update_strategy))
    error_message = "auth_token_update_strategy must be SET, ROTATE, DELETE, or null."
  }
}

variable "auth_token_wo" {
  description = "Write-only Redis OSS/Valkey AUTH token. This sensitive ephemeral value is not stored in Terraform plan or state."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "auth_token_wo_version" {
  description = "Version that triggers updates to auth_token_wo. Increment whenever the write-only token changes."
  type        = number
  default     = null

  validation {
    condition     = var.auth_token_wo_version == null || (floor(var.auth_token_wo_version) == var.auth_token_wo_version && var.auth_token_wo_version >= 1)
    error_message = "auth_token_wo_version must be a positive integer or null."
  }
}

variable "automatic_failover_enabled" {
  description = "Whether a replication-group read replica is automatically promoted when the primary fails."
  type        = bool
  default     = null
}

variable "multi_az_enabled" {
  description = "Whether Multi-AZ support is enabled for a replication group. Requires automatic failover."
  type        = bool
  default     = null
}

variable "cluster_mode" {
  description = "Replication-group cluster mode migration state: disabled, compatible, or enabled."
  type        = string
  default     = null

  validation {
    condition     = var.cluster_mode == null || contains(["compatible", "disabled", "enabled"], var.cluster_mode)
    error_message = "cluster_mode must be disabled, compatible, enabled, or null."
  }
}

variable "data_tiering_enabled" {
  description = "Whether data tiering is enabled for an eligible replication-group node type."
  type        = bool
  default     = null
}

variable "durability" {
  description = "Valkey replication-group durability mode: default, async, sync, or disabled. Requires cluster mode and a supported Valkey version."
  type        = string
  default     = null

  validation {
    condition     = var.durability == null || contains(["async", "default", "disabled", "sync"], var.durability)
    error_message = "durability must be default, async, sync, disabled, or null."
  }
}

variable "global_replication_group_id" {
  description = "Global replication group ID to join as a secondary replication group. Engine and node settings are inherited when set."
  type        = string
  default     = null

  validation {
    condition     = var.global_replication_group_id == null || trimspace(var.global_replication_group_id) != ""
    error_message = "global_replication_group_id must be null or a non-empty ID."
  }
}

variable "create_global_replication_group" {
  description = "Whether to create an ElastiCache global replication group from this module's primary replication group. Use another module call with global_replication_group_id for each secondary Region."
  type        = bool
  default     = false

  validation {
    condition = !var.create_global_replication_group || (
      var.deployment_type == "replication_group" &&
      var.global_replication_group_id == null
    )
    error_message = "create_global_replication_group requires deployment_type = replication_group and conflicts with global_replication_group_id."
  }
}

variable "global_replication_group_id_suffix" {
  description = "Identifier suffix for a module-created global replication group. Null uses name."
  type        = string
  default     = null

  validation {
    condition = var.global_replication_group_id_suffix == null || (
      can(regex("^[a-z][a-z0-9-]{0,39}$", var.global_replication_group_id_suffix)) &&
      !endswith(var.global_replication_group_id_suffix, "-") &&
      !strcontains(var.global_replication_group_id_suffix, "--")
    )
    error_message = "global_replication_group_id_suffix must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, not end with or contain consecutive hyphens, and be at most 40 characters."
  }
}

variable "global_replication_group_description" {
  description = "Description for the module-created global replication group."
  type        = string
  default     = null

  validation {
    condition     = var.global_replication_group_description == null || trimspace(var.global_replication_group_description) != ""
    error_message = "global_replication_group_description must be null or non-empty."
  }
}

variable "global_automatic_failover_enabled" {
  description = "Intra-Region automatic failover setting applied to global datastore members. Null inherits automatic_failover_enabled. This does not provide automatic cross-Region failover."
  type        = bool
  default     = null
}

variable "global_cache_node_type" {
  description = "Cache node type applied across the global replication group. Null inherits node_type from the primary replication group."
  type        = string
  default     = null
}

variable "global_engine" {
  description = "Engine applied across the global replication group: redis or valkey. Null inherits engine from the primary replication group."
  type        = string
  default     = null

  validation {
    condition     = var.global_engine == null || contains(["redis", "valkey"], lower(var.global_engine))
    error_message = "global_engine must be redis, valkey, or null."
  }
}

variable "global_engine_version" {
  description = "Engine version applied across the global replication group. Null inherits engine_version from the primary replication group."
  type        = string
  default     = null
}

variable "global_num_node_groups" {
  description = "Number of node groups or shards applied across the global replication group. Null inherits num_node_groups from the primary replication group."
  type        = number
  default     = null

  validation {
    condition     = var.global_num_node_groups == null || (floor(var.global_num_node_groups) == var.global_num_node_groups && var.global_num_node_groups >= 1)
    error_message = "global_num_node_groups must be a positive integer or null."
  }
}

variable "global_parameter_group_name" {
  description = "Parameter group applied across the global replication group. Null uses the created or existing primary parameter group when configured."
  type        = string
  default     = null
}

variable "global_replication_group_timeouts" {
  description = "Optional create, update, and delete timeouts for the module-created global replication group."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null

  validation {
    condition = var.global_replication_group_timeouts == null || alltrue([
      for timeout in values(var.global_replication_group_timeouts) :
      timeout == null || can(regex("^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$", timeout))
    ])
    error_message = "global_replication_group_timeouts values must be valid Terraform duration strings such as 30m or 1h30m."
  }
}

variable "num_cache_clusters" {
  description = "Total primary and replica cache clusters in a cluster-mode-disabled replication group. Conflicts with sharded topology arguments."
  type        = number
  default     = null

  validation {
    condition     = var.num_cache_clusters == null || (floor(var.num_cache_clusters) == var.num_cache_clusters && var.num_cache_clusters >= 1)
    error_message = "num_cache_clusters must be a positive integer or null."
  }
}

variable "num_node_groups" {
  description = "Number of node groups or shards in a cluster-mode-enabled replication group."
  type        = number
  default     = null

  validation {
    condition     = var.num_node_groups == null || (floor(var.num_node_groups) == var.num_node_groups && var.num_node_groups >= 1)
    error_message = "num_node_groups must be a positive integer or null."
  }
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes in each replication-group shard. Requires num_node_groups."
  type        = number
  default     = null

  validation {
    condition     = var.replicas_per_node_group == null || (floor(var.replicas_per_node_group) == var.replicas_per_node_group && var.replicas_per_node_group >= 0)
    error_message = "replicas_per_node_group must be a non-negative integer or null."
  }
}

variable "preferred_cache_cluster_azs" {
  description = "Ordered Availability Zones for cache clusters in a cluster-mode-disabled replication group."
  type        = list(string)
  default     = null
}

variable "node_group_configuration" {
  description = "Explicit replication-group shard configurations. Requires num_node_groups and conflicts with preferred_cache_cluster_azs."
  type = set(object({
    node_group_id              = optional(string)
    primary_availability_zone  = optional(string)
    primary_outpost_arn        = optional(string)
    replica_availability_zones = optional(list(string))
    replica_count              = optional(number)
    replica_outpost_arns       = optional(list(string))
    slots                      = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for group in var.node_group_configuration :
      group.replica_count == null || (floor(group.replica_count) == group.replica_count && group.replica_count >= 0)
    ])
    error_message = "Each node_group_configuration replica_count must be a non-negative integer or null."
  }
}

variable "transit_encryption_mode" {
  description = "Replication-group in-transit encryption migration mode: preferred or required."
  type        = string
  default     = null

  validation {
    condition     = var.transit_encryption_mode == null || contains(["preferred", "required"], var.transit_encryption_mode)
    error_message = "transit_encryption_mode must be preferred, required, or null."
  }
}

variable "user_group_ids" {
  description = "Redis OSS/Valkey user group IDs associated with a replication group. AWS currently permits at most one."
  type        = set(string)
  default     = []

  validation {
    condition     = length(var.user_group_ids) <= 1 && alltrue([for user_group_id in var.user_group_ids : user_group_id != null && trimspace(user_group_id) != ""])
    error_message = "user_group_ids supports at most one non-empty user group ID."
  }
}

variable "cache_usage_limits" {
  description = "Storage and ECPU limits for a serverless cache."
  type = object({
    data_storage = optional(object({
      minimum = optional(number)
      maximum = optional(number)
      unit    = optional(string, "GB")
    }))
    ecpu_per_second = optional(object({
      minimum = optional(number)
      maximum = optional(number)
    }))
  })
  default = null

  validation {
    condition = var.cache_usage_limits == null || (
      var.cache_usage_limits.data_storage == null || (
        var.cache_usage_limits.data_storage.unit == "GB" &&
        (var.cache_usage_limits.data_storage.minimum == null || (var.cache_usage_limits.data_storage.minimum >= 1 && var.cache_usage_limits.data_storage.minimum <= 5000)) &&
        (var.cache_usage_limits.data_storage.maximum == null || (var.cache_usage_limits.data_storage.maximum >= 1 && var.cache_usage_limits.data_storage.maximum <= 5000)) &&
        (var.cache_usage_limits.data_storage.minimum == null || var.cache_usage_limits.data_storage.maximum == null || var.cache_usage_limits.data_storage.minimum <= var.cache_usage_limits.data_storage.maximum)
      )
    )
    error_message = "Serverless data storage minimum and maximum must be 1-5000 GB, with minimum not exceeding maximum."
  }

  validation {
    condition = var.cache_usage_limits == null || (
      var.cache_usage_limits.ecpu_per_second == null || (
        (var.cache_usage_limits.ecpu_per_second.minimum == null || (var.cache_usage_limits.ecpu_per_second.minimum >= 1000 && var.cache_usage_limits.ecpu_per_second.minimum <= 15000000)) &&
        (var.cache_usage_limits.ecpu_per_second.maximum == null || (var.cache_usage_limits.ecpu_per_second.maximum >= 1000 && var.cache_usage_limits.ecpu_per_second.maximum <= 15000000)) &&
        (var.cache_usage_limits.ecpu_per_second.minimum == null || var.cache_usage_limits.ecpu_per_second.maximum == null || var.cache_usage_limits.ecpu_per_second.minimum <= var.cache_usage_limits.ecpu_per_second.maximum)
      )
    )
    error_message = "Serverless ECPU minimum and maximum must be 1000-15000000, with minimum not exceeding maximum."
  }
}

variable "daily_snapshot_time" {
  description = "Daily UTC snapshot time for a Redis OSS or Valkey serverless cache."
  type        = string
  default     = null

  validation {
    condition     = var.daily_snapshot_time == null || can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.daily_snapshot_time))
    error_message = "daily_snapshot_time must use the UTC format hh:mm."
  }
}

variable "snapshot_arns_to_restore" {
  description = "Snapshot ARNs from which to restore a Redis OSS or Valkey serverless cache."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for snapshot_arn in var.snapshot_arns_to_restore : snapshot_arn != null && trimspace(snapshot_arn) != ""])
    error_message = "snapshot_arns_to_restore must contain only non-empty ARNs."
  }
}

variable "user_group_id" {
  description = "Redis OSS/Valkey user group ID associated with a serverless cache."
  type        = string
  default     = null

  validation {
    condition     = var.user_group_id == null || trimspace(var.user_group_id) != ""
    error_message = "user_group_id must be null or a non-empty ID."
  }
}

variable "create_parameter_group" {
  description = "Whether to create and associate an ElastiCache parameter group. Serverless caches do not use parameter groups."
  type        = bool
  default     = false
}

variable "parameter_group_name" {
  description = "Existing parameter group name, or name override for the module-created parameter group."
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "Engine family for a module-created parameter group, such as memcached1.6, redis7, valkey8, or valkey9."
  type        = string
  default     = null
}

variable "parameter_group_description" {
  description = "Description for the module-created parameter group."
  type        = string
  default     = "Managed by Terraform"
}

variable "parameters" {
  description = "Parameters applied to the module-created parameter group."
  type = set(object({
    name  = string
    value = string
  }))
  default = []

  validation {
    condition     = alltrue([for parameter in var.parameters : trimspace(parameter.name) != ""])
    error_message = "Every parameter name must be non-empty."
  }
}

variable "parameter_group_tags" {
  description = "Additional tags for the module-created parameter group."
  type        = map(string)
  default     = {}
}

variable "create_subnet_group" {
  description = "Whether to create and associate an ElastiCache subnet group for a provisioned deployment."
  type        = bool
  default     = false
}

variable "subnet_group_name" {
  description = "Existing subnet group name, or name override for the module-created subnet group."
  type        = string
  default     = null
}

variable "subnet_group_description" {
  description = "Description for the module-created subnet group."
  type        = string
  default     = "Managed by Terraform"
}

variable "subnet_ids" {
  description = "Subnet IDs for a module-created subnet group or directly for a serverless cache."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for subnet_id in var.subnet_ids : subnet_id != null && trimspace(subnet_id) != ""])
    error_message = "subnet_ids must contain only non-empty subnet IDs."
  }
}

variable "subnet_group_tags" {
  description = "Additional tags for the module-created subnet group."
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Optional create, update, and delete timeouts for the selected primary ElastiCache resource."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null

  validation {
    condition = var.timeouts == null || alltrue([
      for timeout in values(var.timeouts) :
      timeout == null || can(regex("^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$", timeout))
    ])
    error_message = "timeouts values must be valid Terraform duration strings such as 30m or 1h30m."
  }
}

variable "tags" {
  description = "Tags applied to module-created resources."
  type        = map(string)
  default     = {}
}
