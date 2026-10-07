# DynamoDB & RDS — Database Services

## DynamoDB (NoSQL)

### NoSQL

DynamoDB is a fully-managed, serverless key-value/document database — no
servers to provision or patch, scales automatically, pay mostly per
request (on-demand mode) or per provisioned throughput. Schema-less beyond
the key definition: different items in the same table can have completely
different attributes.

### Tables

The top-level container, roughly analogous to a SQL table, but with no
fixed schema for non-key attributes — you don't declare columns up front.

### Items

A single row/record within a table — a collection of attributes, each
with a name and typed value (string, number, binary, set, map, list...).

### Attributes

The individual fields on an item — e.g. `{ userId: "123", name: "Vitha",
tags: ["admin", "beta"] }`. Only the key attributes need to be consistent
across every item in the table.

### Partition key

The required primary key field — DynamoDB hashes this value to decide
which physical storage partition the item lives on. Good partition key
choice (high cardinality, evenly distributed values) is the single biggest
factor in DynamoDB performance — a poorly chosen key (e.g. a fixed
`status` field with only 3 possible values) causes "hot partitions" that
throttle under load.

### Sort key

An optional second part of the primary key — within one partition key's
items, the sort key orders and uniquely identifies them (e.g. partition
key `userId`, sort key `timestamp`, letting you efficiently query "all of
this user's events, ordered by time").

### Use cases

Session stores, shopping carts, IoT event ingestion, gaming leaderboards,
any workload needing predictable low-millisecond latency at massive scale
where access patterns are known in advance (DynamoDB is designed around
modeling for your queries up front, unlike SQL's "ask anything" flexibility).

## RDS (Relational Database Service)

### Relational database

RDS is managed infrastructure for running a *traditional* SQL database —
AWS handles patching, backups, and failover, but you still get a real
database engine with full SQL, joins, transactions, and a fixed schema,
unlike DynamoDB.

### Supported engines

MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, and Amazon Aurora (AWS's
own MySQL/PostgreSQL-compatible engine built for higher throughput and
cheaper storage scaling).

### DB instances

The actual running database server — you pick an instance class (similar
concept to EC2 instance types, e.g. `db.t3.micro`) and storage
type/amount, similar to provisioning a VM, just for a managed database.

### Security

RDS instances live inside a VPC (same model as EC2 — subnets, security
groups) and are almost never given a public IP in production; encryption
at rest (KMS) and in transit (SSL/TLS) are both supported and commonly
mandated.

### Backups

Automated daily snapshots plus continuous transaction-log backup, enabling
**point-in-time recovery** to any second within the retention window (up
to 35 days), plus the ability to take manual snapshots that persist
indefinitely.

### Multi-AZ

A synchronously-replicated standby copy of the database in a second
Availability Zone — if the primary fails, RDS automatically fails over to
the standby (typically under a minute), with no application-level
intervention needed beyond reconnecting. Pure availability feature, not a
read-scaling one — the standby isn't queryable directly.

### Read replicas

Asynchronously-replicated **read-only** copies, which *can* be queried
directly — used to horizontally scale read-heavy workloads by routing
reads away from the primary. Unlike Multi-AZ, read replicas can live in a
different region entirely, and (for most engines) can be manually promoted
to a standalone primary if needed.

### Use cases

Anything needing real SQL semantics — relational data with joins and
transactions, existing applications built against a specific SQL engine,
reporting/analytics queries over structured data.
