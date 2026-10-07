# IAM — Identity and Access Management

## What is IAM?

IAM is AWS's service for controlling **who** (authentication) can do
**what** (authorization) to **which resources**, account-wide. Every
single AWS API call — console click, CLI command, Terraform `apply` — is
checked against IAM before it's allowed to proceed. IAM itself is global
(not region-scoped) and free to use.

## Users

An IAM User represents a single person or application with long-term
credentials (console password and/or access keys). AWS's own guidance:
**never use the root account** (the one created at signup) for daily work
— create an IAM user for yourself immediately and lock the root account
away (MFA, no access keys).

## Groups

A Group is just a named collection of Users that share the same
permissions — attach a policy to the group once instead of to every user
individually. A user can belong to multiple groups; their effective
permissions are the union of all attached policies. Groups cannot be
nested (no groups-within-groups).

## Roles

A Role is like a User but has no long-term credentials — instead, anything
that needs access (an EC2 instance, a Lambda function, another AWS
account, a CI pipeline via OIDC) *assumes* the role and receives
short-lived, auto-rotating temporary credentials. This is the preferred
way to grant an AWS resource access to other AWS resources — e.g. an EC2
instance reading from S3 should use an instance role, never a hardcoded
access key baked into the instance.

## Policies

A Policy is a JSON document that explicitly lists allowed (or denied)
actions on specific resources:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

Policies attach to Users, Groups, or Roles. AWS provides managed policies
(`AmazonS3ReadOnlyAccess`, `AdministratorAccess`, etc.) for common cases;
custom policies give precise control.

## Permissions

By default, an IAM identity has **zero** permissions — everything is
implicitly denied until a policy explicitly allows it. An explicit `Deny`
in any attached policy always wins over an `Allow`, no matter where it
comes from.

## Least privilege

The core IAM security principle: grant only the exact permissions a user/
role needs to do its job, nothing more. Practically: start with a narrow
policy and add permissions as real `AccessDenied` errors surface, rather
than starting with `AdministratorAccess` and never tightening it (a common
real-world anti-pattern, usually acceptable only in a personal learning
account like the one used for this course).

## IAM best practices

- Never use the root account for daily work; enable MFA on it and lock
  away its credentials.
- One IAM user per human; never share credentials.
- Prefer roles over long-lived access keys wherever possible (EC2 instance
  roles, GitHub Actions OIDC, etc.).
- Apply least privilege; review and prune unused permissions periodically.
- Rotate any access keys that must exist.
- Use groups to manage permissions at scale instead of per-user policies.

## Common use cases

- Giving a CI/CD pipeline (like the GitHub Actions workflows built in
  Sessions 16-17) scoped permission to push to ECR/deploy to EKS, without
  handing it full account access.
- Letting an EC2 instance read/write a specific S3 bucket via an instance
  role (no credentials stored on the instance at all).
- Cross-account access: Account A's role lets a trusted Account B assume
  it temporarily, instead of sharing credentials.
