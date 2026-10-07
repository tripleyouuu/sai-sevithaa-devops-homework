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

### Full workflow, run for real against a live AWS account

Once AWS credentials were configured (`aws configure`, verified first via
`aws sts get-caller-identity` without ever exposing the actual key values)
and the IAM user had `AdministratorAccess` attached (the first `apply`
attempt correctly failed with `AccessDenied: ... s3:CreateBucket` until
this was granted):

```
$ terraform apply -auto-approve
aws_s3_bucket.devops553: Creating...
aws_s3_bucket.devops553: Creation complete after 5s [id=sai-sevithaa-devops-session18-demo]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
bucket_arn = "arn:aws:s3:::sai-sevithaa-devops-session18-demo"
bucket_name = "sai-sevithaa-devops-session18-demo"
bucket_region = "ap-south-1"
```

Verified independently via the AWS CLI (not just Terraform's own state)
that the bucket is real:

```
$ aws s3api head-bucket --bucket sai-sevithaa-devops-session18-demo
{"BucketArn": "arn:aws:s3:::sai-sevithaa-devops-session18-demo", "BucketRegion": "ap-south-1", ...}

$ aws s3 ls | grep sai-sevithaa
2026-10-08 00:25:20 sai-sevithaa-devops-session18-demo
```

`terraform show` and `terraform output` captured in
[`terraform-s3-demo/task1_apply_output.txt`](terraform-s3-demo/task1_apply_output.txt).

Then torn down to avoid any ongoing cost:

```
$ terraform destroy -auto-approve
aws_s3_bucket.devops553: Destroying... [id=sai-sevithaa-devops-session18-demo]
aws_s3_bucket.devops553: Destruction complete after 2s
Destroy complete! Resources: 1 destroyed.

$ aws s3 ls | grep sai-sevithaa || echo 'bucket no longer exists'
bucket no longer exists
```

Full output: [`terraform-s3-demo/task1_destroy_output.txt`](terraform-s3-demo/task1_destroy_output.txt)

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
