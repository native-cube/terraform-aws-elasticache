# Global replication group example

Creates an encrypted and AUTH-protected Redis OSS global datastore with a writable primary replication group in `primary_region` and a read-only secondary replication group in `secondary_region`. Each Region uses its own existing private subnets and security groups; the module creates the two regional subnet groups. Both hardening profiles are enabled, automatic snapshots are retained, and final snapshots are created when regional members are destroyed.

Supply an engine version and node type available in both Regions and provide `auth_token_wo` through an ephemeral environment or secret source. Increment `auth_token_wo_version` when rotating it. ElastiCache global replication groups are supported for Redis OSS and Valkey, not Memcached or serverless caches. The global replication group itself is managed through the primary module call, while the secondary module call joins using the primary call's `global_replication_group_id` output.

Global datastores use IPv4 and do not provide automatic cross-Region failover. Plan and test a separate promotion and client-reconfiguration procedure.
