# Session 18: Terraform & Infrastructure as Code

## Task 1: Terraform S3 Demo (`terraform-s3-demo/`)

Creates one AWS S3 bucket via `main.tf`/`variables.tf`/`providers.tf`/
`outputs.tf`/`terraform.tf`.

```
$ terraform init
Terraform has been successfully initialized!

$ terraform fmt
(no output — already correctly formatted)

$ terraform validate
Success! The configuration is valid.
```

`terraform plan` (and by extension `apply`/`show`/`output`/`destroy`)
correctly stops at the provider authentication step, since no AWS
credentials are configured yet on this machine:

```
$ terraform plan
Error: failed to refresh cached credentials, no EC2 IMDS role found...
Please see https://registry.terraform.io/providers/hashicorp/aws
for more information about providing credentials.
```

This is expected, correct behavior, not a bug — Terraform validated the
configuration's syntax and structure successfully; it just can't talk to
AWS's API without credentials, exactly as it shouldn't. Full output:
[`terraform-s3-demo/task1_output.txt`](terraform-s3-demo/task1_output.txt)

**Changed** the default `bucket_name` from the course material's
`yatri1107` to `sai-sevithaa-devops-session18-demo` — S3 bucket names are
globally unique across *every* AWS account, so the original default would
likely collide with the course author's own bucket (or fail with
`BucketAlreadyExists` for an unrelated reason) once real credentials are
in place.

**Still needed to finish this task:** your own AWS credentials via
`aws configure` (see the chat for the walkthrough). Once that's done:

```bash
cd terraform-s3-demo
terraform plan      # review what will be created
terraform apply     # create it (will ask for confirmation)
terraform show       # inspect the created state
terraform output     # print bucket_name / bucket_arn / bucket_region
terraform destroy   # tear it down once verified
```

I'll run these with you and show the plan before anything real gets
created, per the confirm-before-apply rule from earlier in this
conversation.

## Task 2: AWS Services Research (`aws-services/`)

Pure documentation, no AWS account needed — written from first-hand AWS
knowledge, cross-checked against this session's own Terraform project
(IAM underlies the credentials Terraform needs; VPC/EC2/S3 are exactly
what Sessions 18-19's Terraform resources provision).

- [`01-iam/README.md`](aws-services/01-iam/README.md) — Users, Groups,
  Roles, Policies, least privilege, best practices
- [`02-ec2/README.md`](aws-services/02-ec2/README.md) — AMI, instance
  types, key pairs, Security Groups, EBS, public/private IP, lifecycle
- [`03-s3/README.md`](aws-services/03-s3/README.md) — buckets, objects,
  storage classes, versioning, lifecycle policies, encryption, bucket
  policies
- [`04-vpc/README.md`](aws-services/04-vpc/README.md) — CIDR, subnets,
  route tables, Internet/NAT Gateway, Security Groups vs Network ACLs,
  public vs private subnet
- [`05-dynamodb-rds/README.md`](aws-services/05-dynamodb-rds/README.md) —
  DynamoDB (NoSQL, partition/sort keys) and RDS (engines, Multi-AZ, read
  replicas)
