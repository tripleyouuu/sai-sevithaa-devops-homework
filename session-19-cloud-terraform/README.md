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

## Still needed: your AWS credentials

Once `aws configure` is set up (see the AWS walkthrough earlier in this
conversation), the remaining workflow is:

```bash
cd terraform-infra
terraform plan      # I'll show you exactly what this creates first
terraform apply     # creates VPC, subnet, IGW, route table, SG, EC2, S3
terraform output    # print instance_public_ip, bucket_name, etc.
# verify the instance is reachable / bucket exists
terraform destroy   # tear everything down once verified, to avoid ongoing cost
```

An architecture diagram and apply/destroy screenshots will be added here
once that runs for real. The EC2 instance type defaults to `t2.micro`
(free-tier eligible on a new AWS account) specifically so this stays free
to run.
