# S3

**What it is** — object storage, any amount of data over HTTP(S), 11-nines durability. What `terraform-s3-demo/` actually provisions.

**Buckets** — top-level, globally-unique-named container (why `bucket_name` had to change from the course default — names collide across every AWS account, not just one). One region each.

**Objects** — a file plus metadata, identified by a key. S3 has no real folders, just keys containing `/` that the console displays as folders. 0 bytes to 5TB.

**Storage classes** — Standard (default), Intelligent-Tiering (auto-moves between tiers on unknown access patterns), Standard-IA/One Zone-IA (infrequent access, cheaper, retrieval fee), Glacier (archival, minutes-to-hours retrieval, cheapest).

**Versioning** — once enabled, every PUT to the same key creates a new version instead of overwriting; delete just adds a delete marker. Protects against accidental overwrite, costs more storage until pruned by a lifecycle rule.

**Lifecycle policies** — automated rules to transition or expire objects after N days, e.g. move to Glacier at 90 days, delete at 365.

**Encryption** — SSE-S3 (AWS-managed keys, default today), SSE-KMS (keys in KMS, audit trail via CloudTrail), SSE-C (you supply the key, AWS never stores it). In-transit is just HTTPS.

**Bucket policies** — resource-based JSON policy on the bucket itself (vs. IAM identity-based policies on users/roles) — how buckets get made public or shared cross-account without touching IAM. `terraform-s3-demo/main.tf` doesn't attach one, so the bucket stays private by default.

**Use cases** — static site hosting, Terraform remote state backend, app file uploads, data lake storage, CI/CD build artifacts.
