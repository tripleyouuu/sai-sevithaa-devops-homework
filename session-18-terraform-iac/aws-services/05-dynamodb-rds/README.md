# DynamoDB & RDS

## DynamoDB (NoSQL)

Fully-managed, serverless key-value/document database — no servers to patch, scales automatically, pay per request or provisioned throughput. Schema-less beyond the key.

- **Tables** — like a SQL table but no fixed schema for non-key attributes
- **Items** — a row: attributes with typed values (string, number, binary, set, map, list)
- **Attributes** — the individual fields, e.g. `{ userId: "123", name: "Vitha" }` — only key attributes need to be consistent across items
- **Partition key** — required, DynamoDB hashes it to pick a storage partition. High-cardinality, evenly-distributed keys matter a lot — a low-cardinality key (e.g. a 3-value `status` field) causes hot partitions
- **Sort key** — optional second part of the primary key, orders/uniquely identifies items within one partition key (e.g. `userId` + `timestamp`)
- **Use cases** — session stores, shopping carts, IoT ingestion, leaderboards — predictable low-latency at scale where access patterns are known upfront

## RDS

Managed infrastructure for a traditional SQL database — AWS handles patching/backups/failover, you still get full SQL, joins, transactions, fixed schema.

- **Engines** — MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, Aurora (AWS's own MySQL/Postgres-compatible engine)
- **DB instances** — the running server, pick an instance class (`db.t3.micro`) and storage, same mental model as EC2
- **Security** — lives in a VPC, rarely a public IP in production, encryption at rest (KMS) and in transit both supported
- **Backups** — automated snapshots + transaction-log backup, point-in-time recovery up to 35 days, plus manual snapshots that persist indefinitely
- **Multi-AZ** — synchronous standby in a second AZ, auto-failover under a minute. Availability feature, not queryable directly
- **Read replicas** — async, read-only, queryable, used to scale reads off the primary. Can live in a different region, promotable to standalone
- **Use cases** — anything needing real SQL — joins, transactions, existing apps built against a specific engine, reporting over structured data
