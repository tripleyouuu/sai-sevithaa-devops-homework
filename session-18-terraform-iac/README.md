# Session 18 — Terraform & Infrastructure as Code

## Task 1 — Terraform S3 Demo

```
$ terraform init
Terraform has been successfully initialized!

$ terraform fmt
$ terraform validate
Success! The configuration is valid.
```

Changed the default `bucket_name` from the course material's `yatri1107` to `sai-sevithaa-devops-session18-demo` — bucket names are globally unique across every AWS account, so the original would likely collide.

Ran the full workflow against a real AWS account (first `apply` attempt failed with `AccessDenied: s3:CreateBucket` until `AdministratorAccess` was attached to the IAM user):

```
$ terraform apply -auto-approve
aws_s3_bucket.devops553: Creation complete after 5s [id=sai-sevithaa-devops-session18-demo]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
bucket_arn = "arn:aws:s3:::sai-sevithaa-devops-session18-demo"
bucket_name = "sai-sevithaa-devops-session18-demo"
bucket_region = "ap-south-1"
```

Verified independently via the AWS CLI, not just Terraform's own state:

```
$ aws s3api head-bucket --bucket sai-sevithaa-devops-session18-demo
{"BucketArn": "arn:aws:s3:::sai-sevithaa-devops-session18-demo", ...}

$ aws s3 ls | grep sai-sevithaa
2026-10-08 00:25:20 sai-sevithaa-devops-session18-demo
```

`terraform show`/`output`: [terraform-s3-demo/task1_apply_output.txt](terraform-s3-demo/task1_apply_output.txt)

Torn down afterward:

```
$ terraform destroy -auto-approve
Destroy complete! Resources: 1 destroyed.

$ aws s3 ls | grep sai-sevithaa || echo 'bucket no longer exists'
bucket no longer exists
```

Full output: [terraform-s3-demo/task1_destroy_output.txt](terraform-s3-demo/task1_destroy_output.txt)

## Task 2 — AWS Services Research

- [01-iam](aws-services/01-iam/README.md)
- [02-ec2](aws-services/02-ec2/README.md)
- [03-s3](aws-services/03-s3/README.md)
- [04-vpc](aws-services/04-vpc/README.md)
- [05-dynamodb-rds](aws-services/05-dynamodb-rds/README.md)
