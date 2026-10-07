# FQDN

## What is an FQDN

A Fully Qualified Domain Name is the complete, unambiguous address of a resource. Inside one namespace you can use a short name (`backend`) and it resolves fine; reach across namespaces or from outside the cluster and you need the full name.

## Kubernetes Service DNS

Every Service gets a DNS record automatically the moment it's created, in the form:

```
<service-name>.<namespace>.svc.cluster.local
```

- `service-name` — the Service's `metadata.name`
- `namespace` — where it lives
- `svc` — tells CoreDNS this is a Service, not a Pod
- `cluster.local` — the cluster's base domain (configurable, this is the default)

## Namespace-based DNS

Inside the same namespace, the short name works:

```
curl http://backend
```

Across namespaces it doesn't — a pod in `dev` calling `http://backend` resolves to `backend.dev.svc.cluster.local`, not whatever's in `production`. You need at least the namespace:

```
curl http://backend.production
```

or the full FQDN for no ambiguity at all.

This works because every pod's `/etc/resolv.conf` has a `search` list that appends namespace suffixes automatically:

```
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

`ndots:5` means any name with fewer than 5 dots gets the search suffixes tried first — which is why a call to an external domain like `api.stripe.com` can cost a few wasted internal lookups before it falls through to the real DNS.

## Pod-to-Service communication

1. Pod does `curl http://backend`
2. Linux checks `/etc/resolv.conf`, queries CoreDNS at `10.96.0.10`
3. CoreDNS returns the Service's ClusterIP
4. The request goes to that IP; kube-proxy routes it to one of the Service's backing pods

Individual pods can also be addressed directly when fronted by a headless Service — `<pod-name>.<service-name>.<namespace>.svc.cluster.local` — which is what StatefulSets use for peer discovery (see the headless Service demo in the main [README](../README.md)).

## Examples

```
auth-svc.default.svc.cluster.local          -> a Service's ClusterIP
web-stateful-0.web-service-headless.default.svc.cluster.local   -> one specific StatefulSet pod
```
