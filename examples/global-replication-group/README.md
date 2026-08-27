# Global replication group example

Creates an encrypted Redis OSS global datastore with a writable primary replication group in `primary_region` and a read-only secondary replication group in `secondary_region`. Each Region uses its own existing private subnets and security groups; the module creates the two regional subnet groups.

Supply an engine version and node type available in both Regions. ElastiCache global replication groups are supported for Redis OSS and Valkey, not Memcached or serverless caches. The global replication group itself is managed through the primary module call, while the secondary module call joins using the primary call's `global_replication_group_id` output.
