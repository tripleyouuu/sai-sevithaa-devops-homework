# EC2 — Elastic Compute Cloud

## What is EC2?

EC2 is AWS's core virtual machine service — rent a server by the second,
choose its CPU/memory/storage/OS, and have full root access to it. It's
the building block most other "compute" services (EKS worker nodes, RDS
under the hood, Elastic Beanstalk) are ultimately built on top of.

## AMI (Amazon Machine Image)

An AMI is a snapshot template an EC2 instance boots from — OS, any
pre-installed software, and block device mappings. AWS, the OS vendor
(Ubuntu, Amazon Linux), or you yourself can supply one. Launching 50
identical instances from the same custom AMI is how fleets get built
consistently without manual setup.

## Instance types

Named `<family><generation>.<size>` — e.g. `t3.micro`, `m6g.large`,
`c7g.xlarge`. The family letter signals the trade-off: `t` = burstable/
general-purpose (what this course's free-tier sessions use), `m` =
balanced, `c` = compute-optimized, `r` = memory-optimized, `g` = GPU. Size
(`micro` → `2xlarge` → ...) scales vCPU/RAM roughly linearly within a
family.

## Key pairs

An EC2 key pair is an SSH public/private key pair — AWS stores the public
half and injects it into the instance's `~/.ssh/authorized_keys` at boot;
you keep the private half locally to SSH in. Lose the private key and
there's no "reset password" — you'd need to detach the root volume onto
another instance to recover access, or just terminate and relaunch.

## Security Groups

A stateful, instance-level virtual firewall — a set of allow rules (no
explicit deny rules exist; everything not allowed is implicitly denied).
"Stateful" means a response to an allowed inbound request is automatically
allowed back out, without needing a matching outbound rule. Multiple
security groups can attach to one instance; their rules are additive.

## EBS (Elastic Block Store)

Network-attached block storage that an EC2 instance mounts as a regular
disk — persists independently of the instance's lifecycle (unlike
`instance store`, which is physically attached and wiped on stop/
termination). Supports point-in-time snapshots to S3, and can be detached
from one instance and reattached to another.

## Public vs private IP

- **Private IP**: assigned from the VPC's subnet CIDR, always present,
  used for in-VPC communication.
- **Public IP**: optionally assigned (auto-assign setting or an Elastic
  IP), routable from the internet via the VPC's Internet Gateway. An
  auto-assigned public IP changes if the instance stops/starts; an
  **Elastic IP** is a static public IP you reserve and keep across
  restarts (and get billed for if it's not attached to a running
  instance).

## Instance lifecycle

`pending` → `running` → (`stopping` → `stopped` → `pending` → `running`,
repeatable) → `shutting-down` → `terminated`. Stopping preserves EBS-backed
root volumes (and their data) and just deallocates compute; terminating
deletes the instance and, by default, its root EBS volume (configurable
per-volume with "delete on termination").

## Common use cases

- Hosting the application layer behind a load balancer.
- Self-hosted CI/CD runners.
- The compute nodes behind a Kubernetes cluster (EKS worker nodes) — the
  same EC2 primitives (AMI, security groups, instance types) this course's
  Session 19 Terraform project provisions directly.
