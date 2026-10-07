# Session 11 — Kubernetes Networking & Services

## Task 1 — All 5 Service Types

### 1. ClusterIP

```
$ kubectl get svc web-service-clusterip
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)
web-service-clusterip   ClusterIP   10.102.196.5   <none>        8080/TCP

$ kubectl exec curl-client -- curl -s http://web-service-clusterip:8080/
<!DOCTYPE html>...Welcome to nginx!...

$ kubectl get endpoints web-service-clusterip
web-service-clusterip   10.244.0.55:80,10.244.0.57:80,10.244.0.58:80
```

Output: [01-clusterip/output.txt](01-clusterip/output.txt)

### 2. NodePort

```
$ kubectl get svc web-service-nodeport
web-service-nodeport   NodePort   10.96.162.37   <none>   80:30080/TCP
```

Direct access via `<minikube-ip>:30080` times out through Colima's driver on macOS, so verified via `kubectl port-forward` instead. Output: [02-nodeport/output.txt](02-nodeport/output.txt)

### 3. LoadBalancer

```
$ kubectl get svc web-service-loadbalancer
web-service-loadbalancer   LoadBalancer   10.103.53.206   <pending>   80:32211/TCP
```

`EXTERNAL-IP` staying `<pending>` is expected on Minikube — no real cloud LB to assign one (`minikube tunnel` would simulate it but needs an interactive sudo prompt). Verified via port-forward. Output: [03-loadbalancer/output.txt](03-loadbalancer/output.txt)

### 4. ExternalName

```
$ kubectl exec dns-test-client -- nslookup external-database-service
external-database-service.default.svc.cluster.local	canonical name = nencyravaliya.me
```

No selector, no proxying — just a DNS CNAME to an external hostname. Output: [04-externalname/output.txt](04-externalname/output.txt)

### 5. Headless

```
$ kubectl exec headless-dns-client -- nslookup web-service-headless
Address: 10.244.0.66
Address: 10.244.0.68
Address: 10.244.0.67

$ kubectl exec headless-dns-client -- nslookup web-stateful-0.web-service-headless.default.svc.cluster.local
Address: 10.244.0.66
```

`clusterIP: None` — DNS returns every matching pod's IP directly, and each StatefulSet pod also gets its own stable name. Output: [05-headless/output.txt](05-headless/output.txt)

## Task 2 — Kubernetes Object Comparison

### Deployment vs ReplicaSet

| | ReplicaSet | Deployment |
|---|---|---|
| Purpose | keeps N identical pods running | manages ReplicaSets for declarative updates/rollback |
| Pod management | owns and recreates pods directly | creates/owns a ReplicaSet, which owns the pods |
| Scaling | `kubectl scale rs/<name>` | `kubectl scale deployment/<name>` (delegates to its ReplicaSet) |
| Rolling updates | none — changing the template doesn't trigger a rollout | built in — creates a new ReplicaSet and rolls over |
| Relationship | — | a Deployment creates and manages one or more ReplicaSets; you rarely touch a ReplicaSet directly |

### Deployment vs DaemonSet vs StatefulSet

| | Deployment | DaemonSet | StatefulSet |
|---|---|---|---|
| Use case | stateless apps, any replica interchangeable | one pod per node — log collectors, CNI/storage plugins | stateful apps needing identity — databases, Kafka |
| Pod creation | scheduler places N pods anywhere | one per matching node, auto as nodes join/leave | created in order (`pod-0`, `pod-1`, ...), fixed identity |
| Scaling | arbitrary, scheduler picks placement | tied to node count | ordered, respects pod identity |
| Networking | interchangeable behind a Service | usually hostNetwork/host-port | needs a headless Service, stable per-pod DNS name |
| Storage | typically none or a shared PVC | often host paths | own PVC per pod via `volumeClaimTemplate`, follows the pod |
| Example | nginx web tier | fluentd, node-exporter | mysql, kafka, zookeeper |

### ReplicaSet vs Service

ReplicaSet watches pod *count*; Service gives those pods a stable network identity and load-balances across whoever currently matches its label selector. A Service is needed because pod IPs are ephemeral — every replacement pod gets a new one, and a Service's IP/DNS name never changes. Traffic path: client → Service ClusterIP/DNS → kube-proxy's iptables/IPVS rules (built from Endpoints/EndpointSlices) → a matching pod. ReplicaSet and Service never talk to each other directly — they're connected only by both matching the same pod labels.

## Task 3 — FQDN

[fqdn/README.md](fqdn/README.md)

## Task 4 — CoreDNS

[coredns/README.md](coredns/README.md) — includes a live troubleshooting drill (broken selector → zero endpoints → root-caused → fixed) against the real cluster.
