# VPC

**What it is** — an isolated, software-defined network inside AWS, full control over IP ranges, subnets, routing, gateways. Every EC2/RDS/EKS node lives inside one. Exactly what Session 19's project provisions (VPC → Subnet → Security Group → EC2 → S3).

**CIDR** — defines the IP range, e.g. `10.0.0.0/16` (first 16 bits fixed, 65,536 addresses free). Subnets carve smaller ranges out of it, e.g. `10.0.1.0/24`.

**Subnets** — a segment of the VPC's CIDR, tied to one Availability Zone. Resources launch into a subnet, not the VPC directly. "Public" vs "private" is just convention, based on whether the route table sends `0.0.0.0/0` to an Internet Gateway.

**Route tables** — rules for where traffic from a subnet goes, keyed by destination CIDR. Every subnet has one. A `0.0.0.0/0` route to an Internet Gateway is what makes a subnet public.

**Internet Gateway** — the actual path between the VPC and the internet, one per VPC. Without it nothing reaches the internet, public subnet or not.

**NAT Gateway** — lets private-subnet instances make outbound connections without being reachable inbound (Internet Gateway is bidirectional, this isn't). Lives in a public subnet, billed hourly plus per-GB.

**Security Groups** — stateful, instance-level (see EC2 notes).

**Network ACLs** — stateless, subnet-level, numbered rules evaluated in order, support explicit deny, and need matching inbound/outbound rules separately (no auto-allow-back like Security Groups). A coarser second layer — most day-to-day control happens at the Security Group level.

**Public vs private subnet** — public has a route to an Internet Gateway, private doesn't (uses a NAT Gateway for outbound if needed). Typical pattern: load balancers/bastion hosts public, app servers/databases private.
