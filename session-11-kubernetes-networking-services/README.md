# Session 11: Kubernetes Networking & Services

## Task 1: All 5 Service Types

Each type's folder has its own YAML, deploy steps, and captured output.

### 1. ClusterIP (`01-clusterip/`)

Default type — internal-only virtual IP, reachable only from inside the
cluster.

```
$ kubectl get svc web-service-clusterip
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)
web-service-clusterip   ClusterIP   10.102.196.5   <none>        8080/TCP

$ kubectl exec curl-client -- curl -s http://web-service-clusterip:8080/
<!DOCTYPE html>...Welcome to nginx!...

$ kubectl get endpoints web-service-clusterip
NAME                    ENDPOINTS
web-service-clusterip   10.244.0.55:80,10.244.0.57:80,10.244.0.58:80
```

Output: [`01-clusterip/output.txt`](01-clusterip/output.txt)

### 2. NodePort (`02-nodeport/`)

Opens a fixed port (30000-32767 range, here `30080`) on every node, on top
of a ClusterIP.

```
$ kubectl get svc web-service-nodeport
NAME                   TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)
web-service-nodeport   NodePort   10.96.162.37   <none>        80:30080/TCP
```

Direct access via `<minikube-ip>:30080` times out through Colima's Docker
driver on macOS (the VM's bridge network isn't exposed straight to the Mac
host), so verified via `kubectl port-forward` instead, which confirmed the
app itself is reachable and serving correctly. Output: [`02-nodeport/output.txt`](02-nodeport/output.txt)

### 3. LoadBalancer (`03-loadbalancer/`)

```
$ kubectl get svc web-service-loadbalancer
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
web-service-loadbalancer   LoadBalancer   10.103.53.206   <pending>     80:32211/TCP
```

`EXTERNAL-IP` staying `<pending>` is the *correct* behavior on Minikube —
there's no real cloud load balancer to provision one. Minikube's
`minikube tunnel` command simulates it, but that needs an interactive sudo
password prompt this automated session can't supply, so verified the
backing app directly via port-forward instead (same approach as NodePort).
Output: [`03-loadbalancer/output.txt`](03-loadbalancer/output.txt)

### 4. ExternalName (`04-externalname/`)

No selector, no proxying — it's a pure DNS CNAME alias to an external name.

```
$ kubectl exec dns-test-client -- nslookup external-database-service
external-database-service.default.svc.cluster.local	canonical name = nencyravaliya.me
```

CoreDNS correctly returns the CNAME record pointing at the configured
external hostname. Output: [`04-externalname/output.txt`](04-externalname/output.txt)

### 5. Headless (`05-headless/`)

`clusterIP: None` — no virtual IP at all. DNS returns every matching pod's
IP directly, which is what StatefulSets (databases, brokers) need for
peer-to-peer discovery.

```
$ kubectl exec headless-dns-client -- nslookup web-service-headless
Name:	web-service-headless.default.svc.cluster.local
Address: 10.244.0.66
Address: 10.244.0.68
Address: 10.244.0.67

$ kubectl exec headless-dns-client -- nslookup web-stateful-0.web-service-headless.default.svc.cluster.local
Name:	web-stateful-0.web-service-headless.default.svc.cluster.local
Address: 10.244.0.66
```

Each StatefulSet pod (`web-stateful-0/1/2`) also gets its own stable,
individually addressable DNS name. Output: [`05-headless/output.txt`](05-headless/output.txt)

## Task 2: Kubernetes Object Comparison

### Deployment vs ReplicaSet

| | ReplicaSet | Deployment |
|---|---|---|
| **Purpose** | Guarantees N identical pod replicas are running at all times | Manages ReplicaSets to provide declarative updates, rollouts, and rollback |
| **Pod management** | Directly owns and recreates pods matching its selector | Doesn't touch pods directly — creates/owns a ReplicaSet, which owns the pods |
| **Scaling** | `kubectl scale rs/<name> --replicas=N` | `kubectl scale deployment/<name> --replicas=N` (delegates to its ReplicaSet) |
| **Rolling updates** | No native support — changing the pod template doesn't trigger a rollout | Built-in: changing the template creates a *new* ReplicaSet and rolls pods over to it (RollingUpdate/Recreate strategies, history, rollback) |
| **Relationship** | A Deployment creates and fully manages one or more ReplicaSets (old ones kept at 0 replicas for rollback history) — you almost never create a ReplicaSet directly in practice | — |

In short: you basically always use a Deployment; ReplicaSet is the
lower-level mechanism Deployments are built on.

### Deployment vs DaemonSet vs StatefulSet

| | Deployment | DaemonSet | StatefulSet |
|---|---|---|---|
| **Use case** | Stateless apps (web servers, APIs) where any replica is interchangeable | One copy of a pod on every (or selected) node — log collectors, node monitoring agents, CNI/storage plugins | Stateful apps needing stable identity — databases, Kafka/Zookeeper, anything with per-instance storage or peer discovery |
| **Pod creation** | Scheduler places N pods anywhere there's capacity | Exactly one pod per matching node, automatically added/removed as nodes join/leave | Pods created **in order** (`pod-0`, then `pod-1`, ...), each with a fixed identity |
| **Scaling** | Arbitrary replica count, scheduler picks placement | Tied to node count, not manually scaled | Ordered scale up/down, respects pod identity order |
| **Networking** | Pods are interchangeable behind a Service, no individual identity | Usually `hostNetwork` or host-port bound, since it's tied to the node itself | Needs a **headless Service** so each pod gets a stable, individual DNS name |
| **Storage** | Typically no persistent per-pod storage (or a shared PVC) | Often mounts host paths to access node-level resources/logs | Each pod gets its **own** PersistentVolumeClaim, created from a `volumeClaimTemplate`, that follows that specific pod across rescheduling |
| **Example** | `nginx` web tier | `fluentd`/`filebeat` log shipper, `node-exporter` | `mysql`, `kafka`, `zookeeper` |

### ReplicaSet vs Service

- **ReplicaSet's responsibility**: keep the right *number* of pod replicas
  alive — it watches pod count, not traffic.
- **Service's responsibility**: give those pods a stable network identity
  (virtual IP + DNS name) and load-balance traffic across whichever pods
  currently match its label selector.
- **Why a Service is required**: pod IPs are ephemeral — every time a
  ReplicaSet replaces a dead pod, the new one gets a brand new IP. Without a
  Service sitting in front, every client would need to re-discover pod IPs
  constantly. A Service's IP and DNS name never change, even as the pods
  behind it are replaced.
- **How traffic reaches pods**: client → Service's ClusterIP/DNS name →
  `kube-proxy`'s iptables/IPVS rules (built from watching the Service's
  Endpoints/EndpointSlices) → one of the matching pods, selected by the
  Service's label selector. ReplicaSet and Service are decoupled — neither
  knows the other exists; they're connected only by both watching/matching
  the same pod labels.

## Task 3: FQDN

See [`fqdn/README.md`](fqdn/README.md) — FQDN anatomy
(`<service>.<namespace>.svc.cluster.local`), `/etc/resolv.conf` internals,
short-name vs cross-namespace resolution, Service FQDN vs per-pod FQDN
(StatefulSet/headless), and common `ndots:5` pitfalls.

## Task 4: CoreDNS

See [`coredns/README.md`](coredns/README.md) — what CoreDNS is, its real
Corefile pulled from this cluster, how service discovery/DNS resolution
works end to end, and a full troubleshooting drill (broken selector → zero
endpoints → root-caused → fixed → verified) run against the live cluster.
