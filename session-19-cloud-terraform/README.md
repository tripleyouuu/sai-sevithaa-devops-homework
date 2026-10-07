# Session 19 — Cloud & Terraform in Action

`terraform-infra/` provisions:

```
VPC (10.20.0.0/16)
  -> Subnet (10.20.1.0/24, public)
  -> Internet Gateway + Route Table
  -> Security Group (HTTP/HTTPS inbound)
  -> EC2 instance (Amazon Linux 2023, public subnet)
  -> S3 bucket
```

The source material only covered VPC → Subnet → IGW → Route Table → Security Group, missing the EC2 and S3 the task's own architecture calls for. Added `data "aws_ami"` (looks up the latest Amazon Linux AMI instead of hardcoding one), `aws_instance.web`, and `aws_s3_bucket.assets`, plus matching variables and outputs.

Dependencies are all implicit through Terraform's reference graph — `aws_instance.web.subnet_id = aws_subnet.public.id` is enough for Terraform to create the subnet first, no `depends_on` needed anywhere.

## Verified locally (no credentials needed)

```
$ terraform init
Terraform has been successfully initialized!

$ terraform fmt
$ terraform validate
Success! The configuration is valid.
```

`terraform plan` stops at the credentials step, same as Session 18. Full output: [terraform-infra/task_output.txt](terraform-infra/task_output.txt)

## Full workflow against a live AWS account

```
$ terraform apply -auto-approve
Plan: 8 to add, 0 to change, 0 to destroy.
```

First attempt failed on the EC2 instance:

```
Error: InvalidParameterCombination: The specified instance type is not eligible for Free Tier.
```

`t2.micro` isn't free-tier eligible on this account — AWS scopes it per account now, not a fixed list:

```
$ aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true" --query "InstanceTypes[].InstanceType" --output text
t8i.micro  t4g.small  t3.micro  t4g.micro  t8i.small  t3.small
```

Switched the default `instance_type` to `t3.micro`, re-ran — all 8 resources created:

```
$ terraform apply -auto-approve
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
bucket_name = "sai-sevithaa-devops-session19-assets"
instance_id = "i-0caa9af400f3701e9"
instance_public_ip = "13.233.61.125"
vpc_id = "vpc-0a04eeb355cfc9977"
```

Verified independently via the AWS CLI (its default region is `ap-south-2`, this project deploys to `ap-south-1`, so `--region` has to be explicit):

```
$ aws ec2 describe-instances --region ap-south-1 --instance-ids i-0caa9af400f3701e9 \
    --query 'Reservations[0].Instances[0].[State.Name,InstanceType,PublicIpAddress]' --output table
running | t3.micro | 13.233.61.125

$ curl -v http://13.233.61.125/
* Connected to 13.233.61.125 (13.233.61.125) port 80
* Recv failure: Connection reset by peer
```

The TCP connection succeeding confirms the networking path works end to end (Security Group, routing, Internet Gateway) — the reset is expected since it's a bare AMI with no web server, the task is the networking architecture, not an app. Full output: [terraform-infra/task_apply_output.txt](terraform-infra/task_apply_output.txt)

Torn down afterward, verified gone three ways:

```
$ terraform destroy -auto-approve
Destroy complete! Resources: 8 destroyed.

$ aws ec2 describe-instances --region ap-south-1 --instance-ids i-0caa9af400f3701e9 --query '...State.Name'
terminated

$ aws s3 ls | grep session19 || echo 'bucket no longer exists'
bucket no longer exists

$ aws ec2 describe-vpcs --region ap-south-1 --vpc-ids vpc-0a04eeb355cfc9977
An error occurred (InvalidVpcID.NotFound)
```

Full output: [terraform-infra/task_destroy_output.txt](terraform-infra/task_destroy_output.txt)
