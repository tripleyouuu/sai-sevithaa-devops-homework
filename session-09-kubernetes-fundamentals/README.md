# Session 9: Kubernetes Fundamentals

Resources used: [Kubernetes Basics Tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/),
[Minikube Installation Guide](https://minikube.sigs.k8s.io/docs/start/),
[Kubernetes Architecture](https://kubernetes.io/docs/concepts/architecture/).

## 1-2. Install Minikube, verify cluster status

Installed via `brew install minikube kubectl`, cluster started with the
Docker driver (Colima underneath, since this is a Mac without a native
Linux Docker daemon).

```
$ minikube start --driver=docker
...
* Done! kubectl is now configured to use "minikube" cluster...

$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

$ kubectl cluster-info
Kubernetes control plane is running at https://127.0.0.1:32771
CoreDNS is running at https://127.0.0.1:32771/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

$ kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    OS-IMAGE                         CONTAINER-RUNTIME
minikube   Ready    control-plane   34s   v1.37.0   192.168.49.2   Debian GNU/Linux 12 (bookworm)   containerd://2.3.4
```

Full output: [`setup_output.txt`](setup_output.txt)

## 3. Kubernetes architecture

**Control plane** (runs on the `minikube` node here, since it's a
single-node dev cluster — in production these run on dedicated master
nodes):
- **kube-apiserver** — the front door; every `kubectl` command, and every
  other control-plane component, talks to the cluster only through this
  REST API.
- **etcd** — the cluster's database. Stores all object state (every Pod,
  Service, ConfigMap spec you create) as key-value pairs. Nothing else
  keeps state; if etcd is lost, the cluster's desired state is lost.
- **kube-scheduler** — watches for newly created Pods with no node
  assigned, and picks a node for them based on resource requests,
  constraints, and affinity rules.
- **kube-controller-manager** — runs the reconciliation loops (Deployment
  controller, ReplicaSet controller, Node controller, etc.) that
  continuously compare actual cluster state to desired state and act to
  close the gap — this is the mechanism behind "Kubernetes is declarative."

**Node components** (run on every worker node, and on `minikube` here since
it plays both roles):
- **kubelet** — the agent that actually talks to the container runtime to
  start/stop containers per the PodSpecs assigned to its node, and reports
  node/pod health back to the API server.
- **kube-proxy** — maintains the network rules (iptables/IPVS) that let
  Services route traffic to the right Pods, including load-balancing
  across replicas.
- **Container runtime** (`containerd` here) — actually pulls images and
  runs containers.

## 4-5. Basic objects/commands + Basics tutorial hands-on

Created and exposed the tutorial's own sample app first:

```
$ kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
deployment.apps/kubernetes-bootcamp created

$ kubectl expose deployment/kubernetes-bootcamp --type=NodePort --port=8080
service/kubernetes-bootcamp exposed
```

Full output: [`basics_tutorial_output.txt`](basics_tutorial_output.txt)

**Real troubleshooting hit along the way:** the tutorial's own image failed
on this cluster — worth keeping as a genuine example rather than hiding it.

```
$ kubectl get pods
NAME                                   READY   STATUS             RESTARTS
kubernetes-bootcamp-55d75dfbd9-ctn9g   0/1     ImagePullBackOff   0
kubernetes-bootcamp-5cc66bcc9b-5mlh6   0/1     CrashLoopBackOff   11

$ kubectl logs kubernetes-bootcamp-5cc66bcc9b-5mlh6
exec /bin/sh: exec format error

$ kubectl describe pod kubernetes-bootcamp-55d75dfbd9-ctn9g
...Failed to pull image "gcr.io/google-samples/kubernetes-bootcamp:v2":
gcr.io/google-samples/kubernetes-bootcamp:v2: not found
```

Root cause, found via `kubectl logs` and `kubectl describe`: `v1` is an
old amd64-only image — `exec format error` is the kernel refusing to run a
foreign-architecture binary on this Apple Silicon (arm64) cluster — and
`v2` has since been removed from the registry entirely (`not found`). This
public tutorial image is simply stale; not something `kubectl` config could
fix. Deleted the deployment and re-ran the same tutorial steps (create,
expose, scale, update) against `nginx:1.25-alpine` → `nginx:1.27-alpine`
instead, which is multi-arch and pulls cleanly:

```
$ kubectl create deployment hello-k8s --image=nginx:1.25-alpine
$ kubectl expose deployment/hello-k8s --type=NodePort --port=80
$ kubectl scale deployments/hello-k8s --replicas=3
$ kubectl set image deployments/hello-k8s nginx=nginx:1.27-alpine
$ kubectl rollout status deployments/hello-k8s
Waiting for deployment "hello-k8s" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "hello-k8s" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "hello-k8s" rollout to finish: 1 old replicas are pending termination...
deployment "hello-k8s" successfully rolled out

$ kubectl get pods
NAME                         READY   STATUS      RESTARTS   AGE
hello-k8s-6bb5f98d5f-xmfzb   0/1     Completed   0          23s
hello-k8s-6bb5f98d5f-xsfmk   0/1     Completed   0          19s
hello-k8s-774d79f5bf-4ktwh   1/1     Running     0          1s
hello-k8s-774d79f5bf-bqn86   1/1     Running     0          1s
hello-k8s-774d79f5bf-lj6rc   1/1     Running     0          15s
```

Full output: [`scale_update_output.txt`](scale_update_output.txt). Accessed
via `kubectl port-forward svc/hello-k8s 8095:80` (NodePort isn't directly
reachable from macOS through the Docker driver without a forward/tunnel) —
screenshot: [`screenshot.png`](screenshot.png).

Core objects used in this session: `Deployment` (declares desired Pod
replicas + update strategy), `Pod` (the smallest deployable unit, one or
more containers), `Service` (stable network endpoint routing to a set of
Pods by label selector). Core commands: `kubectl create`, `kubectl apply`,
`kubectl get`, `kubectl expose`, `kubectl scale`, `kubectl set image`,
`kubectl rollout status`, `kubectl delete`.
