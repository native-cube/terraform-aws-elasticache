# Terraform AWS ElastiCache Module

[![Terraform Checks](https://github.com/native-cube/terraform-aws-elasticache/actions/workflows/terraform-pr.yml/badge.svg)](https://github.com/native-cube/terraform-aws-elasticache/actions/workflows/terraform-pr.yml)

Reusable Terraform module for one Amazon ElastiCache deployment per module call. It follows the same conventions as the sibling Amazon MQ and S3 modules: flat documented inputs, a selected singleton primary resource named `main`, optional module-managed supporting resources, common tags, singular composition outputs, native tests, separate examples, and generated documentation.

## Deployment types

| `deployment_type` | Terraform resource | Supported engines |
| --- | --- | --- |
| `cluster` | `aws_elasticache_cluster.main` | Memcached; standalone single-node Redis OSS; or a read replica attached to an existing replication group |
| `replication_group` | `aws_elasticache_replication_group.main` | Redis OSS and Valkey |
| `serverless` | `aws_elasticache_serverless_cache.main` | Memcached, Redis OSS, and Valkey |

Use a separate module call for each independent deployment. This keeps resource addresses and outputs predictable while allowing applications to compose any number of caches.

Provisioned Valkey uses `deployment_type = "replication_group"`; the AWS provider does not support Valkey as a standalone `aws_elasticache_cluster`. Serverless caches receive `subnet_ids` directly because the serverless API does not accept an ElastiCache subnet-group name.

For a Redis OSS or Valkey global datastore, set `create_global_replication_group = true` on the primary replication-group module call. In each secondary Region, use another module call with `global_replication_group_id = module.primary.global_replication_group_id`. The global resource is owned by the primary call; regional subnet groups and security groups remain separate.

## Usage

```hcl
module "cache" {
  source  = "native-cube/elasticache/aws"
  version = "~> 1.0"

  name            = "orders-valkey"
  deployment_type = "replication_group"
  description     = "Orders application cache"
  engine          = "valkey"
  engine_version  = "8.0"
  node_type       = "cache.r7g.large"
  port            = 6379

  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  snapshot_retention_limit   = 7

  create_parameter_group = true
  parameter_group_family = "valkey8"
  parameters = [{
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }]

  create_subnet_group = true
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.cache_security_group_ids

  tags = {
    Environment = "production"
    Service     = "orders"
  }
}
```

## Compatibility and versioning

Version 1.x requires Terraform 1.11.4 or newer and HashiCorp AWS provider 6.62 or newer within major version 6. The minimum and latest supported combinations are exercised separately in CI.

This module follows Semantic Versioning and uses unprefixed release tags such as `1.0.0`. Pin a compatible module version in production and review [CHANGELOG.md](CHANGELOG.md) before upgrading. Major releases may contain breaking changes; minor and patch releases preserve the documented 1.x interface.

The module adds `terraform-module = "elasticache"` and `elasticache-cache = var.name` to module-created resources. Caller tags with those keys are intentionally replaced so module ownership remains identifiable. Parameter-group and subnet-group-specific tags are merged on top.

## Parameter and subnet groups

Set `create_parameter_group = true`, supply `parameter_group_family`, and optionally declare `parameters`. The group is automatically associated with a provisioned cluster or replication group. Otherwise, set `parameter_group_name` to use an existing group.

Set `create_subnet_group = true` with existing `subnet_ids` to create and associate a subnet group with a provisioned deployment. Otherwise, set `subnet_group_name` to use an existing group. Serverless deployments use `subnet_ids` directly and reject subnet-group creation.

The module does not create VPCs, subnets, security groups, KMS keys, CloudWatch log groups, Firehose streams, SNS topics, user groups, or provider configuration. Callers create those resources and pass their IDs, names, or ARNs.

## Credentials and encryption

For Redis OSS or Valkey AUTH, prefer `auth_token_wo`. It is a sensitive ephemeral input backed by the provider's write-only argument, so the token is not persisted in Terraform plan or state. Set `auth_token_wo_version` and increment it whenever the token changes. The legacy `auth_token` input remains available but is stored in state.

AUTH requires in-transit encryption and conflicts with `user_group_ids`. A customer-managed replication-group KMS key requires at-rest encryption. The module validates these relationships before apply.

Prefer ElastiCache RBAC over a shared AUTH token when applications need separate identities or least-privilege access strings. Pass one existing user group through `user_group_ids` for a provisioned replication group or `user_group_id` for a serverless cache. ElastiCache IAM authentication can be configured on users in that external group; the caller remains responsible for IAM policies, short-lived connection tokens, and client support.

## Opt-in hardening profiles

The module preserves compatibility by default. Enable either profile to turn common production controls into plan-time requirements:

| Input | Enforced controls |
| --- | --- |
| `enforce_security_baseline = true` | Explicit engine versions and VPC networking; TLS for provisioned caches; at-rest encryption plus AUTH or RBAC for replication-group primaries; RBAC for Redis OSS/Valkey serverless caches. |
| `enforce_resilience_baseline = true` | Cross-AZ Memcached nodes; replication-group replicas, automatic failover, Multi-AZ, automatic snapshot retention, and a final snapshot; retained snapshots for Redis OSS/Valkey serverless caches. |

Read-replica clusters and global datastore secondaries inherit some controls from their source. The profiles account for those inherited settings but still require regional networking and, for secondaries, explicit snapshot protection. Serverless encryption at rest and in transit and Multi-AZ placement are service-managed.

The module also rejects invalid global-datastore combinations even when profiles are disabled: IPv6/dual-stack networking, Valkey durability, and automatic minor-version upgrades. A global datastore improves cross-Region recovery but does not perform automatic cross-Region failover; `global_automatic_failover_enabled` controls failover within member Regions.

## Production operations

- Use private subnets and security groups scoped to known application security groups or CIDRs. Do not expose cache ports broadly.
- Send engine and slow logs to pre-created CloudWatch Logs or Firehose destinations where the selected engine supports them. Add CloudWatch alarms for CPU/ECPU, memory pressure, evictions, replication lag, connection saturation, swap, and error events; alarm ownership remains outside this module.
- Set maintenance and snapshot windows deliberately, subscribe an SNS topic for ElastiCache events, and review service updates before maintenance deadlines.
- Treat snapshots as recovery controls, not availability controls. Test restores regularly, set retention to match recovery requirements, and use a customer-managed KMS key where key ownership is required. Final snapshots and manually created test snapshots are not tracked by Terraform after resource deletion.
- Exercise regional failover and, for global datastores, document the separate cross-Region promotion and application DNS/configuration procedure. Confirm engine versions, node types, quotas, and parameter groups are available in every target Region before rollout.
- Rotate write-only AUTH tokens by changing `auth_token_wo`, incrementing `auth_token_wo_version`, and choosing the intended `auth_token_update_strategy`. Never output tokens or commit them to variable files.
- Use `prevent_destroy` in a caller wrapper or policy-as-code when accidental deletion protection is required. This module does not set it because doing so would make reusable module teardown impossible without a stateful lifecycle override.

## Provider argument coverage

Every configurable argument and nested block in AWS provider 6.62.0 is wired for:

- `aws_elasticache_cluster`
- `aws_elasticache_replication_group`, including write-only AUTH, Valkey durability, explicit shard placement, log delivery, and custom timeouts
- `aws_elasticache_global_replication_group`, including topology-wide engine, version, node type, failover, shard count, parameter group, and custom timeouts
- `aws_elasticache_serverless_cache`, including minimum and maximum storage and ECPU limits
- `aws_elasticache_parameter_group`
- `aws_elasticache_subnet_group`

`make schema-check` recursively compares the initialized provider schema with all six resource definitions and fails if a configurable argument or nested-block field is missing.

## Examples

- `examples/memcached` - encrypted two-node provisioned Memcached cluster.
- `examples/redis` - encrypted Redis OSS replication group with automatic failover and Multi-AZ.
- `examples/valkey` - Valkey serverless cache with bounded storage and ECPU usage.
- `examples/global-replication-group` - encrypted Redis OSS global datastore spanning primary and secondary Regions.

Examples require existing private subnet and security group IDs. The Redis OSS and Valkey examples also require existing RBAC user groups, and the global example requires an ephemeral write-only AUTH token. Engine versions are required inputs so upgrades and regional availability are reviewed rather than silently assumed. Every example enables both hardening profiles.

## Development

Run `make check` to verify formatting, generated documentation, initialization, native mocked plans, provider argument coverage, and every example. Run `make docs` after changing resources, inputs, outputs, or version constraints. `make release-check` additionally runs TFLint, actionlint, ShellCheck, and the local Trivy configuration scan; the GitHub Actions pipeline does not install or run the Trivy CLI. See [RELEASING.md](RELEASING.md) for the maintainer checklist.

## Module documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.62.0, < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.62.0, < 7.0.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_elasticache_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_cluster) | resource |
| [aws_elasticache_global_replication_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_global_replication_group) | resource |
| [aws_elasticache_parameter_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_parameter_group) | resource |
| [aws_elasticache_replication_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_serverless_cache.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache) | resource |
| [aws_elasticache_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Whether provisioned cache modifications are applied immediately instead of during the next maintenance window. | `bool` | `null` | no |
| <a name="input_at_rest_encryption_enabled"></a> [at\_rest\_encryption\_enabled](#input\_at\_rest\_encryption\_enabled) | Whether encryption at rest is enabled for a replication group. | `bool` | `null` | no |
| <a name="input_auth_token"></a> [auth\_token](#input\_auth\_token) | Legacy Redis OSS/Valkey AUTH token. This sensitive value is stored in Terraform state; prefer auth\_token\_wo. | `string` | `null` | no |
| <a name="input_auth_token_update_strategy"></a> [auth\_token\_update\_strategy](#input\_auth\_token\_update\_strategy) | Strategy used when changing a replication-group AUTH token: SET, ROTATE, or DELETE. | `string` | `null` | no |
| <a name="input_auth_token_wo"></a> [auth\_token\_wo](#input\_auth\_token\_wo) | Write-only Redis OSS/Valkey AUTH token. This sensitive ephemeral value is not stored in Terraform plan or state. | `string` | `null` | no |
| <a name="input_auth_token_wo_version"></a> [auth\_token\_wo\_version](#input\_auth\_token\_wo\_version) | Version that triggers updates to auth\_token\_wo. Increment whenever the write-only token changes. | `number` | `null` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Whether eligible minor engine upgrades are applied automatically to provisioned cache nodes. | `bool` | `null` | no |
| <a name="input_automatic_failover_enabled"></a> [automatic\_failover\_enabled](#input\_automatic\_failover\_enabled) | Whether a replication-group read replica is automatically promoted when the primary fails. | `bool` | `null` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Availability Zone for a provisioned cluster. Conflicts with preferred\_availability\_zones. | `string` | `null` | no |
| <a name="input_az_mode"></a> [az\_mode](#input\_az\_mode) | Memcached cluster Availability Zone mode: single-az or cross-az. | `string` | `null` | no |
| <a name="input_cache_usage_limits"></a> [cache\_usage\_limits](#input\_cache\_usage\_limits) | Storage and ECPU limits for a serverless cache. | <pre>object({<br/>    data_storage = optional(object({<br/>      minimum = optional(number)<br/>      maximum = optional(number)<br/>      unit    = optional(string, "GB")<br/>    }))<br/>    ecpu_per_second = optional(object({<br/>      minimum = optional(number)<br/>      maximum = optional(number)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_cluster_mode"></a> [cluster\_mode](#input\_cluster\_mode) | Replication-group cluster mode migration state: disabled, compatible, or enabled. | `string` | `null` | no |
| <a name="input_cluster_replication_group_id"></a> [cluster\_replication\_group\_id](#input\_cluster\_replication\_group\_id) | Existing replication group ID to which a deployment\_type = cluster resource is attached as a read replica. Standalone cluster settings are inherited when this is set. | `string` | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create the selected ElastiCache deployment and module-managed supporting resources. | `bool` | `true` | no |
| <a name="input_create_global_replication_group"></a> [create\_global\_replication\_group](#input\_create\_global\_replication\_group) | Whether to create an ElastiCache global replication group from this module's primary replication group. Use another module call with global\_replication\_group\_id for each secondary Region. | `bool` | `false` | no |
| <a name="input_create_parameter_group"></a> [create\_parameter\_group](#input\_create\_parameter\_group) | Whether to create and associate an ElastiCache parameter group. Serverless caches do not use parameter groups. | `bool` | `false` | no |
| <a name="input_create_subnet_group"></a> [create\_subnet\_group](#input\_create\_subnet\_group) | Whether to create and associate an ElastiCache subnet group for a provisioned deployment. | `bool` | `false` | no |
| <a name="input_daily_snapshot_time"></a> [daily\_snapshot\_time](#input\_daily\_snapshot\_time) | Daily UTC snapshot time for a Redis OSS or Valkey serverless cache. | `string` | `null` | no |
| <a name="input_data_tiering_enabled"></a> [data\_tiering\_enabled](#input\_data\_tiering\_enabled) | Whether data tiering is enabled for an eligible replication-group node type. | `bool` | `null` | no |
| <a name="input_deployment_type"></a> [deployment\_type](#input\_deployment\_type) | ElastiCache deployment to create: cluster, replication\_group, or serverless. Use separate module calls for multiple independent deployments. | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Description for a replication group or serverless cache. | `string` | `"Managed by Terraform"` | no |
| <a name="input_durability"></a> [durability](#input\_durability) | Valkey replication-group durability mode: default, async, sync, or disabled. Requires cluster mode and a supported Valkey version. | `string` | `null` | no |
| <a name="input_enforce_resilience_baseline"></a> [enforce\_resilience\_baseline](#input\_enforce\_resilience\_baseline) | Whether to require resilient topology and backups appropriate to the selected deployment type. | `bool` | `false` | no |
| <a name="input_enforce_security_baseline"></a> [enforce\_security\_baseline](#input\_enforce\_security\_baseline) | Whether to reject deployments without explicit VPC networking, encryption, and supported authentication controls. Global secondaries may inherit encryption and authentication from the primary. | `bool` | `false` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Cache engine. Clusters support memcached or redis, replication groups support redis or valkey, and serverless supports all three. May be omitted for inherited replication-group resources. | `string` | `null` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Engine version for a provisioned cluster or replication group. Specify explicitly in production so upgrades are deliberate. | `string` | `null` | no |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | Final snapshot identifier for a Redis OSS cluster or Redis OSS/Valkey replication group. Null skips a final snapshot. | `string` | `null` | no |
| <a name="input_global_automatic_failover_enabled"></a> [global\_automatic\_failover\_enabled](#input\_global\_automatic\_failover\_enabled) | Intra-Region automatic failover setting applied to global datastore members. Null inherits automatic\_failover\_enabled. This does not provide automatic cross-Region failover. | `bool` | `null` | no |
| <a name="input_global_cache_node_type"></a> [global\_cache\_node\_type](#input\_global\_cache\_node\_type) | Cache node type applied across the global replication group. Null inherits node\_type from the primary replication group. | `string` | `null` | no |
| <a name="input_global_engine"></a> [global\_engine](#input\_global\_engine) | Engine applied across the global replication group: redis or valkey. Null inherits engine from the primary replication group. | `string` | `null` | no |
| <a name="input_global_engine_version"></a> [global\_engine\_version](#input\_global\_engine\_version) | Engine version applied across the global replication group. Null inherits engine\_version from the primary replication group. | `string` | `null` | no |
| <a name="input_global_num_node_groups"></a> [global\_num\_node\_groups](#input\_global\_num\_node\_groups) | Number of node groups or shards applied across the global replication group. Null inherits num\_node\_groups from the primary replication group. | `number` | `null` | no |
| <a name="input_global_parameter_group_name"></a> [global\_parameter\_group\_name](#input\_global\_parameter\_group\_name) | Parameter group applied across the global replication group. Null uses the created or existing primary parameter group when configured. | `string` | `null` | no |
| <a name="input_global_replication_group_description"></a> [global\_replication\_group\_description](#input\_global\_replication\_group\_description) | Description for the module-created global replication group. | `string` | `null` | no |
| <a name="input_global_replication_group_id"></a> [global\_replication\_group\_id](#input\_global\_replication\_group\_id) | Global replication group ID to join as a secondary replication group. Engine and node settings are inherited when set. | `string` | `null` | no |
| <a name="input_global_replication_group_id_suffix"></a> [global\_replication\_group\_id\_suffix](#input\_global\_replication\_group\_id\_suffix) | Identifier suffix for a module-created global replication group. Null uses name. | `string` | `null` | no |
| <a name="input_global_replication_group_timeouts"></a> [global\_replication\_group\_timeouts](#input\_global\_replication\_group\_timeouts) | Optional create, update, and delete timeouts for the module-created global replication group. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_ip_discovery"></a> [ip\_discovery](#input\_ip\_discovery) | IP version advertised in the discovery protocol for a provisioned cluster or replication group: ipv4 or ipv6. | `string` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Customer-managed KMS key ARN for replication-group or serverless-cache encryption at rest. | `string` | `null` | no |
| <a name="input_log_delivery_configuration"></a> [log\_delivery\_configuration](#input\_log\_delivery\_configuration) | Log delivery configurations for a Redis OSS cluster or Redis OSS/Valkey replication group. A maximum of one engine log and one slow log is supported. | <pre>set(object({<br/>    destination      = string<br/>    destination_type = string<br/>    log_format       = string<br/>    log_type         = string<br/>  }))</pre> | `[]` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Weekly maintenance window for a provisioned cluster or replication group, in UTC ddd:hh24:mi-ddd:hh24:mi format. | `string` | `null` | no |
| <a name="input_major_engine_version"></a> [major\_engine\_version](#input\_major\_engine\_version) | Major engine version for a serverless cache. | `string` | `null` | no |
| <a name="input_multi_az_enabled"></a> [multi\_az\_enabled](#input\_multi\_az\_enabled) | Whether Multi-AZ support is enabled for a replication group. Requires automatic failover. | `bool` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | ElastiCache deployment identifier and prefix for module-created supporting resources. | `string` | n/a | yes |
| <a name="input_network_type"></a> [network\_type](#input\_network\_type) | IP protocol type for cache connections: ipv4, ipv6, or dual\_stack. | `string` | `null` | no |
| <a name="input_node_group_configuration"></a> [node\_group\_configuration](#input\_node\_group\_configuration) | Explicit replication-group shard configurations. Requires num\_node\_groups and conflicts with preferred\_cache\_cluster\_azs. | <pre>set(object({<br/>    node_group_id              = optional(string)<br/>    primary_availability_zone  = optional(string)<br/>    primary_outpost_arn        = optional(string)<br/>    replica_availability_zones = optional(list(string))<br/>    replica_count              = optional(number)<br/>    replica_outpost_arns       = optional(list(string))<br/>    slots                      = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Cache node type for a provisioned cluster or replication group. | `string` | `null` | no |
| <a name="input_notification_topic_arn"></a> [notification\_topic\_arn](#input\_notification\_topic\_arn) | SNS topic ARN that receives notifications from a provisioned cluster or replication group. | `string` | `null` | no |
| <a name="input_num_cache_clusters"></a> [num\_cache\_clusters](#input\_num\_cache\_clusters) | Total primary and replica cache clusters in a cluster-mode-disabled replication group. Conflicts with sharded topology arguments. | `number` | `null` | no |
| <a name="input_num_cache_nodes"></a> [num\_cache\_nodes](#input\_num\_cache\_nodes) | Number of nodes in a standalone cluster. Redis OSS requires one; Memcached supports 1-40. | `number` | `null` | no |
| <a name="input_num_node_groups"></a> [num\_node\_groups](#input\_num\_node\_groups) | Number of node groups or shards in a cluster-mode-enabled replication group. | `number` | `null` | no |
| <a name="input_outpost_mode"></a> [outpost\_mode](#input\_outpost\_mode) | Outpost mode for a Memcached cluster: single-outpost or cross-outpost. | `string` | `null` | no |
| <a name="input_parameter_group_description"></a> [parameter\_group\_description](#input\_parameter\_group\_description) | Description for the module-created parameter group. | `string` | `"Managed by Terraform"` | no |
| <a name="input_parameter_group_family"></a> [parameter\_group\_family](#input\_parameter\_group\_family) | Engine family for a module-created parameter group, such as memcached1.6, redis7, valkey8, or valkey9. | `string` | `null` | no |
| <a name="input_parameter_group_name"></a> [parameter\_group\_name](#input\_parameter\_group\_name) | Existing parameter group name, or name override for the module-created parameter group. | `string` | `null` | no |
| <a name="input_parameter_group_tags"></a> [parameter\_group\_tags](#input\_parameter\_group\_tags) | Additional tags for the module-created parameter group. | `map(string)` | `{}` | no |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | Parameters applied to the module-created parameter group. | <pre>set(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_port"></a> [port](#input\_port) | Port on which provisioned cache nodes accept connections. AWS defaults to 11211 for Memcached and 6379 for Redis OSS or Valkey. | `number` | `null` | no |
| <a name="input_preferred_availability_zones"></a> [preferred\_availability\_zones](#input\_preferred\_availability\_zones) | Ordered Availability Zones for Memcached cluster nodes. The list length must equal num\_cache\_nodes. | `list(string)` | `null` | no |
| <a name="input_preferred_cache_cluster_azs"></a> [preferred\_cache\_cluster\_azs](#input\_preferred\_cache\_cluster\_azs) | Ordered Availability Zones for cache clusters in a cluster-mode-disabled replication group. | `list(string)` | `null` | no |
| <a name="input_preferred_outpost_arn"></a> [preferred\_outpost\_arn](#input\_preferred\_outpost\_arn) | Preferred Outpost ARN for a Memcached cluster. Required when outpost\_mode is set. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Optional AWS Region for module-managed resources. Null uses the Region configured on the AWS provider. | `string` | `null` | no |
| <a name="input_replicas_per_node_group"></a> [replicas\_per\_node\_group](#input\_replicas\_per\_node\_group) | Number of replica nodes in each replication-group shard. Requires num\_node\_groups. | `number` | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | VPC security group IDs associated with the selected cache deployment. | `set(string)` | `[]` | no |
| <a name="input_security_group_names"></a> [security\_group\_names](#input\_security\_group\_names) | Legacy cache security group names associated with a replication group. Prefer security\_group\_ids for VPC deployments. | `set(string)` | `[]` | no |
| <a name="input_snapshot_arns"></a> [snapshot\_arns](#input\_snapshot\_arns) | Redis RDB snapshot ARNs used to restore a provisioned cluster or replication group. Clusters accept one ARN. | `list(string)` | `[]` | no |
| <a name="input_snapshot_arns_to_restore"></a> [snapshot\_arns\_to\_restore](#input\_snapshot\_arns\_to\_restore) | Snapshot ARNs from which to restore a Redis OSS or Valkey serverless cache. | `list(string)` | `[]` | no |
| <a name="input_snapshot_name"></a> [snapshot\_name](#input\_snapshot\_name) | Snapshot name from which to restore a provisioned cluster or replication group. | `string` | `null` | no |
| <a name="input_snapshot_retention_limit"></a> [snapshot\_retention\_limit](#input\_snapshot\_retention\_limit) | Number of automatic snapshots retained for the selected deployment. Zero disables provisioned-cache backups. | `number` | `null` | no |
| <a name="input_snapshot_window"></a> [snapshot\_window](#input\_snapshot\_window) | Daily UTC snapshot window for a provisioned cluster or replication group. | `string` | `null` | no |
| <a name="input_subnet_group_description"></a> [subnet\_group\_description](#input\_subnet\_group\_description) | Description for the module-created subnet group. | `string` | `"Managed by Terraform"` | no |
| <a name="input_subnet_group_name"></a> [subnet\_group\_name](#input\_subnet\_group\_name) | Existing subnet group name, or name override for the module-created subnet group. | `string` | `null` | no |
| <a name="input_subnet_group_tags"></a> [subnet\_group\_tags](#input\_subnet\_group\_tags) | Additional tags for the module-created subnet group. | `map(string)` | `{}` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs for a module-created subnet group or directly for a serverless cache. | `set(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to module-created resources. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update, and delete timeouts for the selected primary ElastiCache resource. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_transit_encryption_enabled"></a> [transit\_encryption\_enabled](#input\_transit\_encryption\_enabled) | Whether in-transit encryption is enabled. For standalone clusters the AWS provider supports this only for eligible Memcached versions. | `bool` | `null` | no |
| <a name="input_transit_encryption_mode"></a> [transit\_encryption\_mode](#input\_transit\_encryption\_mode) | Replication-group in-transit encryption migration mode: preferred or required. | `string` | `null` | no |
| <a name="input_user_group_id"></a> [user\_group\_id](#input\_user\_group\_id) | Redis OSS/Valkey user group ID associated with a serverless cache. | `string` | `null` | no |
| <a name="input_user_group_ids"></a> [user\_group\_ids](#input\_user\_group\_ids) | Redis OSS/Valkey user group IDs associated with a replication group. AWS currently permits at most one. | `set(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cache_nodes"></a> [cache\_nodes](#output\_cache\_nodes) | Provisioned cluster cache node connection details, or an empty list for another deployment type. |
| <a name="output_cluster_address"></a> [cluster\_address](#output\_cluster\_address) | Memcached cluster DNS address without a port, or null when unavailable. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | Provisioned cluster ARN, or null for another deployment type. |
| <a name="output_cluster_configuration_endpoint"></a> [cluster\_configuration\_endpoint](#output\_cluster\_configuration\_endpoint) | Memcached cluster configuration endpoint, or null when unavailable. |
| <a name="output_cluster_engine_version_actual"></a> [cluster\_engine\_version\_actual](#output\_cluster\_engine\_version\_actual) | Actual engine version running on the provisioned cluster, or null for another deployment type. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Provisioned cluster ID, or null for another deployment type. |
| <a name="output_global_replication_group_arn"></a> [global\_replication\_group\_arn](#output\_global\_replication\_group\_arn) | Module-created global replication group ARN, or null when creation is disabled. |
| <a name="output_global_replication_group_engine"></a> [global\_replication\_group\_engine](#output\_global\_replication\_group\_engine) | Engine of the module-created global replication group, or null when creation is disabled. |
| <a name="output_global_replication_group_engine_version_actual"></a> [global\_replication\_group\_engine\_version\_actual](#output\_global\_replication\_group\_engine\_version\_actual) | Actual engine version running across the module-created global replication group, or null when creation is disabled. |
| <a name="output_global_replication_group_id"></a> [global\_replication\_group\_id](#output\_global\_replication\_group\_id) | Created global replication group ID, joined global replication group ID for a secondary, or null when global replication is unused. |
| <a name="output_global_replication_group_node_groups"></a> [global\_replication\_group\_node\_groups](#output\_global\_replication\_group\_node\_groups) | Shard IDs and slot ranges for the module-created global replication group, or an empty set when creation is disabled. |
| <a name="output_parameter_group_arn"></a> [parameter\_group\_arn](#output\_parameter\_group\_arn) | Module-created parameter group ARN, or null when creation is disabled. |
| <a name="output_parameter_group_id"></a> [parameter\_group\_id](#output\_parameter\_group\_id) | Module-created parameter group ID, or null when creation is disabled. |
| <a name="output_parameter_group_name"></a> [parameter\_group\_name](#output\_parameter\_group\_name) | Created or existing parameter group name associated with the provisioned deployment, or null when unset. |
| <a name="output_replication_group_arn"></a> [replication\_group\_arn](#output\_replication\_group\_arn) | Redis OSS or Valkey replication group ARN, or null for another deployment type. |
| <a name="output_replication_group_configuration_endpoint"></a> [replication\_group\_configuration\_endpoint](#output\_replication\_group\_configuration\_endpoint) | Configuration endpoint for a cluster-mode-enabled replication group, or null when unavailable. |
| <a name="output_replication_group_engine_version_actual"></a> [replication\_group\_engine\_version\_actual](#output\_replication\_group\_engine\_version\_actual) | Actual engine version running on the replication group, or null for another deployment type. |
| <a name="output_replication_group_id"></a> [replication\_group\_id](#output\_replication\_group\_id) | Redis OSS or Valkey replication group ID, or null for another deployment type. |
| <a name="output_replication_group_member_clusters"></a> [replication\_group\_member\_clusters](#output\_replication\_group\_member\_clusters) | Cache cluster IDs belonging to the replication group, or an empty set for another deployment type. |
| <a name="output_replication_group_primary_endpoint"></a> [replication\_group\_primary\_endpoint](#output\_replication\_group\_primary\_endpoint) | Primary endpoint for a cluster-mode-disabled replication group, or null when unavailable. |
| <a name="output_replication_group_reader_endpoint"></a> [replication\_group\_reader\_endpoint](#output\_replication\_group\_reader\_endpoint) | Reader endpoint for a cluster-mode-disabled replication group, or null when unavailable. |
| <a name="output_serverless_cache_arn"></a> [serverless\_cache\_arn](#output\_serverless\_cache\_arn) | Serverless cache ARN, or null for another deployment type. |
| <a name="output_serverless_cache_endpoint"></a> [serverless\_cache\_endpoint](#output\_serverless\_cache\_endpoint) | Serverless cache endpoint details, or an empty list for another deployment type. |
| <a name="output_serverless_cache_full_engine_version"></a> [serverless\_cache\_full\_engine\_version](#output\_serverless\_cache\_full\_engine\_version) | Full serverless cache engine version, or null for another deployment type. |
| <a name="output_serverless_cache_id"></a> [serverless\_cache\_id](#output\_serverless\_cache\_id) | Serverless cache ID, or null for another deployment type. |
| <a name="output_serverless_cache_reader_endpoint"></a> [serverless\_cache\_reader\_endpoint](#output\_serverless\_cache\_reader\_endpoint) | Serverless cache reader endpoint details, or an empty list when unavailable. |
| <a name="output_serverless_cache_status"></a> [serverless\_cache\_status](#output\_serverless\_cache\_status) | Serverless cache status, or null for another deployment type. |
| <a name="output_subnet_group_arn"></a> [subnet\_group\_arn](#output\_subnet\_group\_arn) | Module-created subnet group ARN, or null when creation is disabled. |
| <a name="output_subnet_group_id"></a> [subnet\_group\_id](#output\_subnet\_group\_id) | Module-created subnet group ID, or null when creation is disabled. |
| <a name="output_subnet_group_name"></a> [subnet\_group\_name](#output\_subnet\_group\_name) | Created or existing subnet group name associated with the provisioned deployment, or null when unset. |
| <a name="output_subnet_group_vpc_id"></a> [subnet\_group\_vpc\_id](#output\_subnet\_group\_vpc\_id) | VPC ID of the module-created subnet group, or null when creation is disabled. |
<!-- END_TF_DOCS -->
