# IAM

**What it is** — controls who can do what to which resources, account-wide. Every API call (console, CLI, Terraform) gets checked against IAM first. Global, not region-scoped, free to use.

**Users** — a person or app with long-term credentials. Never use the root account day to day — create an IAM user immediately and lock root away with MFA.

**Groups** — named collection of users sharing permissions. Attach a policy once to the group instead of to every user. No nested groups.

**Roles** — like a user but no long-term credentials. Anything that needs access (EC2, Lambda, another account, a CI pipeline via OIDC) assumes the role and gets short-lived, auto-rotating credentials. Preferred over hardcoded keys.

**Policies** — JSON documents listing allowed/denied actions on resources:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::my-bucket/*" }
  ]
}
```

Attach to users, groups, or roles. AWS ships managed policies (`AmazonS3ReadOnlyAccess`, `AdministratorAccess`) or write custom ones.

**Permissions** — default is zero, everything implicitly denied until a policy allows it. An explicit `Deny` always beats an `Allow`.

**Least privilege** — grant only what's needed, nothing more. Start narrow, add permissions as real `AccessDenied` errors show up, rather than starting at `AdministratorAccess` (fine for a personal learning account, not for production).

**Best practices** — no root for daily work, MFA on root, one user per person, prefer roles over access keys, review/prune unused permissions, rotate keys that must exist, use groups over per-user policies.

**Use cases** — scoped CI/CD permissions (push to a registry, deploy to a cluster, without full account access), an EC2 instance reading S3 via an instance role instead of stored credentials, cross-account access via role assumption.
