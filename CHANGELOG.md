# Changelog

All notable changes to this module are documented in this file. The module follows [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-08-27

### Added

- Provisioned Memcached and standalone Redis OSS clusters, including replication-group read replicas.
- Redis OSS and Valkey replication groups with encryption, AUTH, Multi-AZ, sharding, durability, logs, snapshots, global secondaries, and custom timeouts.
- Redis OSS and Valkey global replication groups with complete provider argument coverage and a two-Region composition example.
- Memcached, Redis OSS, and Valkey serverless caches with storage and ECPU usage limits.
- Optional module-managed parameter and subnet groups.
- Opt-in security and resilience baselines with plan-time enforcement for encryption, authentication, networking, availability, and recovery controls.
- Cross-input safeguards for AUTH rotation, write-only token versions, automatic failover topology, snapshots, time windows, and global datastore limitations.
- Hardened Redis OSS RBAC, Valkey RBAC, Memcached, and write-only AUTH global-datastore examples.
- Production operations, token rotation, monitoring, failover, backup, and recovery guidance.
- Flat singleton module interface, common tags, singular outputs, native tests, generated documentation, provider-schema coverage, workflow and shell linting, and minimum/latest compatibility CI.

[1.0.0]: https://github.com/native-cube/terraform-aws-elasticache/releases/tag/1.0.0
