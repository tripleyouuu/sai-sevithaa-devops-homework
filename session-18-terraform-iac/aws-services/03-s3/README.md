# S3 — Simple Storage Service

## What is S3?

S3 is AWS's object storage service — store and retrieve any amount of data
(files, not block/file-system storage) over HTTP(S), with 11-nines
durability. It's the service this course's `terraform-s3-demo/` actually
provisions.

## Buckets

A bucket is a top-level, globally-uniquely-named container for objects
(that's why `terraform-s3-demo`'s `bucket_name` had to be changed from the
course's default — bucket names collide across *all* AWS accounts
worldwide, not just within one account). A bucket belongs to one region.

## Objects

An object is a file plus metadata, identified by a key (its "path" within
the bucket — S3 doesn't have real folders, just keys with `/` in them that
the console *displays* as folders). Objects can range from 0 bytes to 5TB.

## Storage classes

Trade retrieval speed/availability for cost:

| Class | Use case |
|---|---|
| Standard | Frequently accessed, default |
| Intelligent-Tiering | Unknown/changing access patterns — auto-moves objects between tiers |
| Standard-IA / One Zone-IA | Infrequent access, cheaper storage, retrieval fee |
| Glacier Instant/Flexible/Deep Archive | Archival — minutes to hours of retrieval latency, cheapest storage |

## Versioning

Once enabled on a bucket, every `PUT` to the same key creates a new
version instead of overwriting — a "deleted" object just gets a delete
marker, and the prior version is still recoverable. Protects against
accidental overwrite/delete; increases storage cost since old versions
stick around until explicitly removed via a lifecycle rule.

## Lifecycle policies

Automated rules that transition objects between storage classes or expire
(delete) them after a set number of days — e.g. "move to Glacier after 90
days, delete after 365." Essential for cost control on buckets that
accumulate logs/backups indefinitely.

## Encryption

- **SSE-S3**: AWS manages the keys entirely, enabled by default on every
  bucket today.
- **SSE-KMS**: keys managed in AWS KMS, giving audit trails (CloudTrail)
  and the ability to control/rotate/revoke key access separately from
  bucket access.
- **SSE-C**: you supply your own encryption key per request; AWS never
  stores it.
- In-transit encryption is just normal HTTPS to the S3 endpoint.

## Bucket policies

A resource-based JSON policy attached directly to the bucket (as opposed
to an IAM identity-based policy attached to a user/role) — controls who
(which principals, which accounts) can do what to this specific bucket.
This is how buckets are made public, or shared cross-account, without
touching IAM at all. `terraform-s3-demo/main.tf` doesn't attach one, so
the bucket is private by default (AWS's modern default for new buckets).

## Common use cases

- Static website hosting.
- Terraform remote state backend (a very common pairing — this project
  currently uses local state, noted as a growth area).
- Application file/image uploads.
- Data lake storage for analytics pipelines.
- Build artifacts and container layer caches for CI/CD.
