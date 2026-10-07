# Session 4: Networking Commands

Task 1 (practicing the commands/repo shared in the `devops-hero` GitHub repo)
is pending — that repo's URL hasn't been provided yet, so this covers the
core networking commands from the task list. Full raw output is in
[`commands_output.txt`](commands_output.txt).

## ping

```
$ ping -c 4 google.com
PING google.com (142.251.12.138): 56 data bytes
64 bytes from 142.251.12.138: icmp_seq=0 ttl=100 time=49.232 ms
64 bytes from 142.251.12.138: icmp_seq=1 ttl=100 time=49.080 ms
64 bytes from 142.251.12.138: icmp_seq=2 ttl=100 time=48.184 ms
64 bytes from 142.251.12.138: icmp_seq=3 ttl=100 time=49.970 ms

--- google.com ping statistics ---
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 48.184/49.116/49.970/0.635 ms
```

Sends ICMP echo requests to check if a host is reachable and measure round-trip latency. 0% packet loss here means the path to google.com is healthy.

## traceroute

```
$ traceroute -m 10 google.com
traceroute to google.com (142.251.12.138), 10 hops max, 40 byte packets
 1  172.20.10.1 (172.20.10.1)  5.671 ms  4.904 ms  6.108 ms
 2  * * *
 3  * * *
 ...
10  * * *
```

Shows the path (router hops) packets take to reach a destination, with latency per hop. Only hop 1 (the local gateway) responded here — later hops likely drop/rate-limit the ICMP/UDP probes traceroute relies on, which is common on networks with firewalls or sandboxed environments like this one.

## ifconfig (`ip addr` on Linux)

```
$ ifconfig en0
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 8e:89:f1:39:db:c8
	inet 172.20.10.10 netmask 0xfffffff0 broadcast 172.20.10.15
	inet6 fe80::8b3:c6dc:4e9:4b79%en0 prefixlen 64 ...
	status: active
```

Shows network interface configuration: MAC address, assigned IPv4/IPv6 addresses, and link status. On Ubuntu the equivalent is `ip addr show`.

## nslookup

```
$ nslookup google.com
Server:		1.0.0.1
Address:	1.0.0.1#53

Non-authoritative answer:
Name:	google.com
Address: 74.125.68.113
...
```

Queries DNS to resolve a hostname to its IP address(es), showing which DNS resolver answered. Multiple A records here means google.com has several IPs for load distribution.

## dig

```
$ dig google.com
;; ANSWER SECTION:
google.com.		207	IN	A	74.125.68.113
google.com.		207	IN	A	74.125.68.138
...
;; Query time: 38 msec
```

A more detailed DNS lookup tool than `nslookup` — shows the full query/answer structure, record TTL, and query time, useful for debugging DNS issues.

## curl -I

```
$ curl -sI https://google.com
HTTP/2 301
location: https://www.google.com/
content-type: text/html; charset=UTF-8
server: gws
```

Fetches only the HTTP response headers (no body) — fast way to check a web server's status code, redirects, and response headers without downloading the page.

## lsof -i (`ss`/`netstat` on Linux)

```
$ lsof -i -P -n
COMMAND    PID  USER   FD   TYPE  ...  NAME
identitys  675 vitha    5u  IPv6  ...  (ESTABLISHED)
...
```

Lists open network connections and listening ports per process. On Ubuntu, `ss -tulnp` or `netstat -tulnp` does the same job.

## whois

```
$ whois google.com
refer:        whois.verisign-grs.com
domain:       COM
organisation: VeriSign Global Registry Services
...
```

Looks up domain registration info from the relevant registry. This returned the `.com` TLD's registry referral rather than google.com's own registrant record (common for well-known domains with privacy/registry-level responses).

## Needed to finish Task 1

The `devops-hero` GitHub repo URL, to pull its specific command list and practice material.
