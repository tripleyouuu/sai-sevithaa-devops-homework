# EC2

**What it is** — rent a VM by the second, choose CPU/memory/storage/OS, full root access. The building block most other compute services (EKS nodes, RDS, Elastic Beanstalk) sit on top of.

**AMI** — the template an instance boots from: OS, pre-installed software, block device mappings. From AWS, an OS vendor, or your own custom one.

**Instance types** — `<family><gen>.<size>`, e.g. `t3.micro`, `m6g.large`. `t` = burstable general-purpose, `m` = balanced, `c` = compute-optimized, `r` = memory-optimized, `g` = GPU. Size scales vCPU/RAM within a family.

**Key pairs** — SSH keypair; AWS injects the public half into `~/.ssh/authorized_keys` at boot, you keep the private half. Lose it and there's no reset — you'd detach the root volume onto another instance to recover, or just relaunch.

**Security Groups** — stateful, instance-level firewall, allow rules only (no explicit deny). A response to an allowed inbound request is auto-allowed back out, no matching outbound rule needed.

**EBS** — network-attached block storage, persists independently of the instance (unlike instance store, which gets wiped on stop/termination). Snapshots to S3, can be detached and reattached elsewhere.

**Public vs private IP** — private IP is always present, from the subnet CIDR. Public IP is optional, routable via the Internet Gateway; an auto-assigned one changes on stop/start, an Elastic IP is static (and billed if not attached to a running instance).

**Lifecycle** — `pending` → `running` → (`stopping`/`stopped`/`pending`/`running`, repeatable) → `shutting-down` → `terminated`. Stopping keeps the EBS root volume; terminating deletes it by default.

**Use cases** — app layer behind a load balancer, self-hosted CI runners, Kubernetes worker nodes (EKS) — same AMI/security-group/instance-type primitives Session 19's Terraform project provisions directly.
