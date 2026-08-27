# Codex Instructions

These instructions apply to the whole Terraform Amazon ElastiCache module.

## Module Scope

- Keep this as a reusable ElastiCache module, not a complete environment stack.
- Create one selected cache deployment per module call: a provisioned cluster, a Redis OSS/Valkey replication group, or a serverless cache.
- Do not create VPCs, subnets, security groups, KMS keys, CloudWatch log groups, Firehose streams, SNS topics, user groups, or AWS provider configuration in the root module.
- Accept existing networking, encryption, notification, logging-destination, and user-group inputs and expose outputs useful for composition.
- Treat the current variables, outputs, resource addresses, and defaults as the compatibility baseline after the first release.

## Terraform Style

- Run `terraform fmt -recursive` after editing Terraform files.
- Keep root files split by concern: `versions.tf`, `variables.tf`, `locals.tf`, `cluster.tf`, `replication_group.tf`, `global_replication_group.tf`, `serverless.tf`, `parameters.tf`, `network.tf`, and `outputs.tf`.
- Keep primary resources named `main` and use `count` for the selected optional singleton deployment and supporting groups.
- Document every variable and output. Use variable validation for constrained values and resource preconditions for cross-variable rules.
- Use `local.common_tags` for module-created resources and merge supporting-resource tags on top.
- Never configure an AWS provider in the root module or hard-code Regions, accounts, credentials, ARNs, subnet IDs, security group IDs, or KMS keys.
- Do not expose or output AUTH tokens. Prefer ephemeral write-only provider arguments and clearly document state-backed legacy secrets.

## ElastiCache Practices

- Support only arguments exposed by the pinned AWS provider. Run `make schema-check` whenever provider constraints or ElastiCache resources change.
- `aws_elasticache_cluster` supports standalone Memcached, standalone single-node Redis OSS, and read replicas attached to a replication group; it does not support standalone Valkey.
- Use replication groups for provisioned Redis OSS or Valkey replicas and sharding.
- Create a global replication group only around this module call's primary replication group. Add each secondary Region with a separate module call using `global_replication_group_id`.
- Serverless caches support Memcached, Redis OSS, and Valkey and consume subnet IDs directly rather than subnet groups.
- Keep engine versions explicit in examples so upgrades remain deliberate.
- AUTH tokens require in-transit encryption and conflict with user groups. Prefer `auth_token_wo` with `auth_token_wo_version`.
- Customer-managed KMS keys for replication groups require at-rest encryption.
- Do not maintain a hard-coded regional engine-version or node-type availability matrix; AWS validates regional offerings.

## Examples And Documentation

- Use unprefixed `MAJOR.MINOR.PATCH` release tags.
- Keep separate Memcached, Redis OSS, Valkey, and global replication group examples under `examples/`, each consuming the root module from `../..`.
- Keep examples deployable and free of environment-specific identifiers. Use variables for Region, names, engine versions, subnets, security groups, and tags.
- Update the README whenever user-facing inputs, outputs, examples, defaults, or operational caveats change.
- Run `make docs` after changes affecting generated documentation and do not manually edit content between terraform-docs markers.
- Do not commit state, credentials, generated plans, real `terraform.tfvars`, or local `.terraform/` directories.

## Verification

Run `make check`, or run formatting, docs, initialization, validation, tests, provider schema coverage, and validation of every example separately. Run TFLint, actionlint, ShellCheck, and Trivy for release checks. Never run `terraform apply` or `terraform destroy` unless explicitly requested and the target environment is confirmed.
