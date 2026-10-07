# VPC — Virtual Private Cloud

## What is VPC?

A VPC is an isolated, software-defined network inside AWS — your own
private slice of the AWS network, with full control over IP ranges,
subnets, routing, and gateways. Every EC2 instance, RDS database, and EKS
cluster node lives inside a VPC. This is exactly what Session 19's
Terraform project provisions (VPC → Subnet → Security Group → EC2 → S3).

## CIDR

Classless Inter-Domain Routing notation defines the VPC's IP address
range, e.g. `10.0.0.0/16` — the `/16` means the first 16 bits are fixed
(network portion), leaving 16 bits (65,536 addresses) for hosts/subnets.
Subnets then carve smaller ranges out of the VPC's CIDR, e.g.
`10.0.1.0/24` (256 addresses) for one subnet.

## Subnets

A subnet is a segment of the VPC's CIDR range, tied to exactly one
Availability Zone. Resources launch *into* a subnet, not directly into the
VPC. Subnets are labeled public or private purely by convention, based on
whether their route table sends `0.0.0.0/0` traffic to an Internet Gateway.

## Route tables

A route table is a set of rules determining where network traffic from a
subnet is directed, keyed by destination CIDR. Every subnet is associated
with exactly one route table (the VPC's "main" one by default, or a custom
one). The entry that makes a subnet "public" is a route sending
`0.0.0.0/0` (everything not matched more specifically) to an Internet
Gateway.

## Internet Gateway

A horizontally-scaled, VPC-attached component that provides the actual
path between the VPC and the public internet — exactly one per VPC,
attached once. Without an Internet Gateway, nothing in the VPC (public
subnet or not) can reach the internet directly, no matter the route table.

## NAT Gateway

Lets instances in a **private** subnet (no direct public IP) initiate
outbound internet connections (e.g. to download OS updates) **without**
being reachable from the internet inbound — unlike an Internet Gateway,
which is bidirectional. A NAT Gateway lives in a public subnet and is used
as the private subnet's route-table target for `0.0.0.0/0`, billed hourly
plus per-GB processed.

## Security Groups

(Detailed in `02-ec2/README.md`.) Stateful, attached at the instance/ENI
level.

## Network ACLs

A **stateless**, subnet-level firewall — unlike Security Groups, NACLs
evaluate numbered rules in order and support explicit `DENY` rules, and
responses to allowed traffic are **not** automatically allowed back out
(you need matching inbound *and* outbound rules). NACLs are a coarser,
second layer of defense; most day-to-day traffic control happens at the
Security Group level instead.

## Public vs private subnet

- **Public subnet**: route table sends `0.0.0.0/0` → Internet Gateway.
  Instances here can get a public IP and are directly internet-reachable
  (subject to Security Groups/NACLs).
- **Private subnet**: no route to an Internet Gateway. Instances here have
  no inbound internet reachability at all; outbound internet access (if
  needed) goes through a NAT Gateway in a public subnet instead.

Typical pattern: load balancers and bastion hosts in public subnets;
application servers and databases in private subnets, reachable only from
inside the VPC.
