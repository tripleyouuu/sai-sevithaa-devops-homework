# CoreDNS

## What is CoreDNS

The DNS server Kubernetes runs in `kube-system` for service discovery — resolving Service and Pod names to IPs so apps never need to hardcode an IP that changes every time a pod reschedules. Replaced `kube-dns` as the default in 1.13. Just a Deployment + Service like anything else in the cluster.

```
$ kubectl get pods -n kube-system -l k8s-app=kube-dns
coredns-559f6c778d-shwj4   1/1   Running

$ kubectl get svc -n kube-system kube-dns
kube-dns   ClusterIP   10.96.0.10   53/UDP,53/TCP,9153/TCP
```

## Why Kubernetes uses it

Plugin-chain DNS server — each capability (API watching, caching, forwarding, health checks) is a small plugin in one `Corefile`. It watches the API directly for Service/Endpoint changes and updates records in real time, no separate sync step. CNCF graduated, small footprint, default on virtually every distribution including Minikube.

## How service discovery works

Every Service gets a DNS record (`<service>.<namespace>.svc.cluster.local`) the moment it's created, no manual registration — CoreDNS's `kubernetes` plugin watches the API server for Service/Endpoint objects and serves those records.

## How queries are resolved

Pulled the real Corefile from this cluster:

```
$ kubectl get configmap coredns -n kube-system -o yaml
Corefile: |
    .:53 {
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
        }
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

Queries for `cluster.local` are answered from the cluster's own records via the `kubernetes` plugin; anything else is forwarded upstream to the node's own resolver, which is how a pod resolving `google.com` still works. Full output: [output.txt](output.txt)

## Troubleshooting drill

Deployed `troubleshooting/empty-endpoints.yaml`: a Service with a typo'd selector (`app: wrong-backend-name`) that doesn't match the real pods.

```
$ kubectl exec curl-test-pod -- curl -s --max-time 3 http://broken-backend-service/
command terminated with exit code 7

$ kubectl get endpoints broken-backend-service
broken-backend-service   <none>
```

An empty endpoints list means a selector/label mismatch, not a DNS problem — CoreDNS resolves the Service name fine either way, the ClusterIP just has nowhere to route.

```
$ kubectl describe svc broken-backend-service | grep -i selector
Selector:   app=wrong-backend-name

$ kubectl get pods --show-labels | grep yatri
yatri-backend-...   app=yatri-backend,...
```

Fixed and verified:

```
$ kubectl patch svc broken-backend-service -p '{"spec":{"selector":{"app":"yatri-backend"}}}'
service/broken-backend-service patched

$ kubectl get endpoints broken-backend-service
broken-backend-service   10.244.0.69:5000,10.244.0.70:5000,10.244.0.71:5000

$ kubectl exec curl-test-pod -- curl -s http://broken-backend-service/
Backend v1.0.0 listening on port 5000
```

General checklist: `kubectl get endpoints <service>` first (empty = selector mismatch), then `cat /etc/resolv.conf` inside a pod, then `nslookup <service>`, then CoreDNS's own logs, then the Corefile itself.

Full output: [output.txt](output.txt)
