# Session 4 — Networking Commands

Full raw output: [commands_output.txt](commands_output.txt)

## ping

```
$ ping -c 4 google.com
64 bytes from 142.251.12.138: icmp_seq=0 ttl=100 time=49.232 ms
...
4 packets transmitted, 4 packets received, 0.0% packet loss
```

Sends ICMP echo requests to check if a host is up and measure round-trip latency. 0% loss means the path is healthy.

## traceroute

```
$ traceroute -m 10 google.com
 1  172.20.10.1 (172.20.10.1)  5.671 ms  4.904 ms  6.108 ms
 2  * * *
 ...
10  * * *
```

Shows the hops a packet takes to reach a destination. Only the local gateway responded here — later hops drop the probes, common on networks with firewalls.

## ifconfig (`ip addr` on Linux)

```
$ ifconfig en0
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 8e:89:f1:39:db:c8
	inet 172.20.10.10 netmask 0xfffffff0 broadcast 172.20.10.15
	status: active
```

Interface config — MAC, assigned IP, link status.

## nslookup

```
$ nslookup google.com
Server:		1.0.0.1
Non-authoritative answer:
Name:	google.com
Address: 74.125.68.113
...
```

Resolves a hostname to its IP. Several A records here since google.com load-balances across multiple IPs.

## dig

```
$ dig google.com
;; ANSWER SECTION:
google.com.		207	IN	A	74.125.68.113
...
;; Query time: 38 msec
```

More detail than `nslookup` — full query/answer structure, record TTL, query time.

## curl -I

```
$ curl -sI https://google.com
HTTP/2 301
location: https://www.google.com/
```

Headers only, no body — quick way to check status codes and redirects.

## lsof -i (`ss`/`netstat` on Linux)

```
$ lsof -i -P -n
COMMAND    PID  USER   FD   TYPE  ...  NAME
identitys  675 vitha    5u  IPv6  ...  (ESTABLISHED)
```

Open connections and listening ports per process.

## whois

```
$ whois google.com
refer:        whois.verisign-grs.com
domain:       COM
```

Domain registration lookup. Returned the `.com` registry referral rather than google.com's own record, which is normal for a well-known domain.
