# Session 19: Cloud & Terraform in Action

`terraform-infra/` — an end-to-end AWS infrastructure project matching the
session's suggested architecture:

```
Terraform
  │
  ├── VPC (10.20.0.0/16)
  │
  ├── Subnet (10.20.1.0/24, public)
  │
  ├── Internet Gateway + Route Table (0.0.0.0/0 -> IGW)
  │
  ├── Security Group (HTTP/HTTPS inbound, all outbound)
  │
  ├── EC2 instance (latest Amazon Linux 2023, in the public subnet)
  │
  └── S3 bucket (application assets)
```

The course's own `08-mini-project` source only defined VPC → Subnet →
Internet Gateway → Route Table → Security Group — missing the EC2 and S3
resources the session's own suggested architecture diagram calls for. Added:

- `data "aws_ami" "amazon_linux"` — looks up the latest Amazon Linux 2023
  AMI dynamically rather than hardcoding a region-specific AMI ID (which
  goes stale and differs per region).
- `aws_instance.web` — launched into the public subnet, attached to the
  security group, with an auto-assigned public IP.
- `aws_s3_bucket.assets` — a second, independent resource demonstrating
  Terraform managing multiple unrelated service types in one project.
- Matching `variables.tf` entries (`instance_type`, `bucket_name`) and
  `outputs.tf` entries (`instance_id`, `instance_public_ip`, `bucket_name`).

## What this demonstrates

- **Providers**: `hashicorp/aws ~> 6.0`, configured once in `versions.tf`.
- **Variables**: `aws_region`, `instance_type`, `bucket_name` — all with
  sensible defaults, overridable via `terraform.tfvars`.
- **Resources**: 7 resources + 1 data source across 3 different AWS
  services (networking, compute, storage).
- **Outputs**: every resource's key identifier (`vpc_id`, `subnet_id`,
  `security_group_id`, `instance_id`, `instance_public_ip`, `bucket_name`)
  surfaced for easy inspection or chaining into another Terraform module.
- **Dependencies**: entirely implicit, via Terraform's normal reference
  graph — e.g. `aws_instance.web.subnet_id = aws_subnet.public.id` means
  Terraform automatically creates the subnet before the instance, no
  explicit `depends_on` needed anywhere in this project.
- **Terraform state**: local state file (`terraform.tfstate`, gitignored)
  — the natural next step for a real team would be an S3 + DynamoDB remote
  backend (which Session 18's `03-s3` research doc and this session's own
  S3 bucket make a nice segue into, though not implemented here to keep
  this project self-contained).

## Verified locally (no AWS credentials needed for these)

```
$ terraform init
Terraform has been successfully initialized!

$ terraform fmt
main.tf   (reformatted one minor alignment issue)

$ terraform validate
Success! The configuration is valid.
```

`terraform plan` correctly stops at the credentials step, same as Session
18:

```
$ terraform plan
Error: No valid credential sources found
Error: failed to refresh cached credentials, no EC2 IMDS role found...
```

Full output: [`terraform-infra/task_output.txt`](terraform-infra/task_output.txt)

## Full workflow, run for real against a live AWS account

```
$ terraform apply -auto-approve
...
Plan: 8 to add, 0 to change, 0 to destroy.
```

First attempt failed on the EC2 instance specifically — a real, useful
finding:

```
Error: creating EC2 Instance: ... InvalidParameterCombination: The specified
instance type is not eligible for Free Tier. For a list of Free Tier
instance types, run 'describe-instance-types' with the filter
'free-tier-eligible=true'.
```

`t2.micro` (the older-generation default) isn't free-tier eligible on this
particular AWS account — AWS now scopes free-tier eligibility per account
rather than it being a fixed global list. Checked what actually is:

```
$ aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true" --query "InstanceTypes[].InstanceType" --output text
t8i.micro  t4g.small  c7i-flex.large  t3.micro  t4g.micro  t8i.small  m7i-flex.large  t3.small
```

Changed the default `instance_type` from `t2.micro` to `t3.micro` and
re-ran — all 8 resources created successfully:

```
$ terraform apply -auto-approve
aws_instance.web: Creation complete after 16s [id=i-0caa9af400f3701e9]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
bucket_name = "sai-sevithaa-devops-session19-assets"
instance_id = "i-0caa9af400f3701e9"
instance_public_ip = "13.233.61.125"
security_group_id = "sg-0ccdb793587c896db"
subnet_id = "subnet-09f414da95be665d6"
vpc_cidr = "10.20.0.0/16"
vpc_id = "vpc-0a04eeb355cfc9977"
```

**Verified independently via the AWS CLI** (not just trusting Terraform's
own state) — note the CLI's configured default region is `ap-south-2`
while this project deploys to `ap-south-1`, so `--region` has to be passed
explicitly or the CLI looks in the wrong region entirely and reports
"not found" for resources that do exist:

```
$ aws ec2 describe-instances --region ap-south-1 --instance-ids i-0caa9af400f3701e9 \
    --query 'Reservations[0].Instances[0].[State.Name,InstanceType,PublicIpAddress,VpcId]' --output table
running | t3.micro | 13.233.61.125 | vpc-0a04eeb355cfc9977

$ curl -v http://13.233.61.125/
* Connected to 13.233.61.125 (13.233.61.125) port 80
> GET / HTTP/1.1
* Recv failure: Connection reset by peer
```

The TCP connection succeeding on port 80 confirms the entire networking
path works end to end (Security Group ingress rule, subnet routing,
Internet Gateway) — the connection reset (not a timeout) is expected,
since this is a bare AMI with no web server installed; the task is about
the networking architecture, not deploying an app on top of it.

Full output: [`terraform-infra/task_apply_output.txt`](terraform-infra/task_apply_output.txt)

**Torn down afterward**, verified gone three ways (not just trusting
`terraform destroy`'s own "success" message):

```
$ terraform destroy -auto-approve
Destroy complete! Resources: 8 destroyed.

$ aws ec2 describe-instances --region ap-south-1 --instance-ids i-0caa9af400f3701e9 --query '...State.Name'
terminated

$ aws s3 ls | grep session19 || echo 'bucket no longer exists'
bucket no longer exists

$ aws ec2 describe-vpcs --region ap-south-1 --vpc-ids vpc-0a04eeb355cfc9977
An error occurred (InvalidVpcID.NotFound): The vpc ID 'vpc-0a04eeb355cfc9977' does not exist
```

Full output: [`terraform-infra/task_destroy_output.txt`](terraform-infra/task_destroy_output.txt)
