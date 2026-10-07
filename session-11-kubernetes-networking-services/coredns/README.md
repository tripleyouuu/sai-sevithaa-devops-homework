# CoreDNS

## What is CoreDNS?

CoreDNS is the DNS server Kubernetes runs inside the cluster (in the
`kube-system` namespace) to provide **service discovery** — resolving
Service and Pod names to IP addresses so applications never need to
hardcode IPs that change every time a pod is rescheduled. It replaced
`kube-dns` as the default starting in Kubernetes 1.13, and is itself just a
Deployment + Service like anything else in the cluster, not special
built-in magic.

```
$ kubectl get pods -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-559f6c778d-shwj4   1/1     Running   0          52m

$ kubectl get svc -n kube-system kube-dns
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP
```

## Why Kubernetes uses CoreDNS

- It's a **plugin-chain DNS server** — each capability (Kubernetes API
  watching, caching, forwarding, health checks, metrics) is a small,
  composable plugin configured in a single `Corefile`, instead of a
  monolithic DNS codebase.
- It watches the Kubernetes API directly for Service/Endpoint changes and
  updates its DNS records in real time — no separate sync process.
- It's a CNCF graduated project with a small footprint, which is why it's
  the default for virtually every Kubernetes distribution (Minikube
  included).

## How service discovery works

Every Service automatically gets a DNS record of the form
`<service>.<namespace>.svc.cluster.local` the moment it's created — no
manual registration. CoreDNS's `kubernetes` plugin is what watches the API
server for Service/Endpoint objects and serves those records.

## How DNS queries are resolved

Pulled this cluster's actual Corefile to see the real config, not just the
docs:

```
$ kubectl get configmap coredns -n kube-system -o yaml
...
Corefile: |
    .:53 {
        log
        errors
        health { lameduck 5s }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        hosts {
           192.168.5.2 host.minikube.internal
           fallthrough
        }
        forward . /etc/resolv.conf { max_concurrent 1000 }
        cache 30 { disable success cluster.local; disable denial cluster.local }
        loop
        reload
        loadbalance
    }
```

Reading this top to bottom: queries for `cluster.local` (or reverse-DNS
`in-addr.arpa`/`ip6.arpa`) are answered straight from the cluster's own
Service/Pod records via the `kubernetes` plugin; anything else
(`forward . /etc/resolv.conf`) is forwarded upstream to whatever DNS server
the node itself uses — which is exactly how a pod resolving `google.com`
still works. `cache 30` keeps answers for 30s to cut repeated API lookups;
`loop`/`reload`/`loadbalance` are operational safety nets (loop detection,
live Corefile reload, round-robin record order).

Full output: [`output.txt`](output.txt)

## Troubleshooting DNS issues — live drill

Deployed `troubleshooting/empty-endpoints.yaml` from the course material: a
Service with a **typo'd selector** (`app: wrong-backend-name`) that doesn't
match the real backend pods (`app: yatri-backend`).

```
$ kubectl exec curl-test-pod -- curl -s --max-time 3 http://broken-backend-service/
command terminated with exit code 7        # connection refused/unreachable

$ kubectl get endpoints broken-backend-service
NAME                     ENDPOINTS   AGE
broken-backend-service   <none>      9s
```

**Diagnosis flow:** an app can't reach a Service → check
`kubectl get endpoints <service>` first. `<none>` means the Service has no
matching pods, which is a **selector problem**, not a DNS or networking
problem (CoreDNS will happily resolve the Service name to its ClusterIP
either way — the ClusterIP just has nowhere to route to).

```
$ kubectl describe svc broken-backend-service | grep -i selector
Selector:                 app=wrong-backend-name

$ kubectl get pods --show-labels | grep yatri
yatri-backend-...   app=yatri-backend,pod-template-hash=...,tier=api
```

Root cause confirmed: selector typo. Fixed and verified:

```
$ kubectl patch svc broken-backend-service -p '{"spec":{"selector":{"app":"yatri-backend"}}}'
service/broken-backend-service patched

$ kubectl get endpoints broken-backend-service
NAME                     ENDPOINTS
broken-backend-service   10.244.0.69:5000,10.244.0.70:5000,10.244.0.71:5000

$ kubectl exec curl-test-pod -- curl -s http://broken-backend-service/
Backend v1.0.0 listening on port 5000
```

**General DNS troubleshooting checklist**, generalized from this drill:
1. `kubectl get endpoints <service>` — empty means selector/label mismatch, not a DNS bug.
2. `kubectl exec <pod> -- cat /etc/resolv.conf` — confirm the pod is pointed at CoreDNS (`nameserver 10.96.0.10` by default).
3. `kubectl exec <pod> -- nslookup <service>` — confirms CoreDNS itself is answering.
4. `kubectl logs -n kube-system -l k8s-app=kube-dns` — check CoreDNS's own logs for errors (e.g. forwarding loops, upstream failures).
5. `kubectl get configmap coredns -n kube-system -o yaml` — verify the Corefile wasn't misconfigured.

Full output: [`output.txt`](output.txt)
