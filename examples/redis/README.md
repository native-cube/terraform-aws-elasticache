# Redis OSS example

Creates an encrypted two-node Redis OSS replication group with automatic failover, Multi-AZ placement, seven retained snapshots, a final snapshot, and module-managed parameter and subnet groups. Both hardening profiles are enabled.

Supply an engine version available in the selected Region, existing private subnet and security group IDs, and exactly one existing Redis OSS RBAC user group. Configure that group with password or IAM-authenticated users and least-privilege access strings before passing its ID to the module.
