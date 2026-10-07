# Session 9 — Kubernetes Fundamentals

## Install Minikube, verify cluster status

```
$ minikube start --driver=docker
...
* Done! kubectl is now configured to use "minikube" cluster...

$ minikube status
host: Running
kubelet: Running
apiserver: Running

$ kubectl cluster-info
Kubernetes control plane is running at https://127.0.0.1:32771

$ kubectl get nodes -o wide
NAME       STATUS   ROLES           VERSION   CONTAINER-RUNTIME
minikube   Ready    control-plane   v1.37.0   containerd://2.3.4
```

Full output: [setup_output.txt](setup_output.txt)

## Kubernetes architecture

**Control plane**
- `kube-apiserver` — front door; every `kubectl` call and every other component talks to the cluster only through this
- `etcd` — the cluster's database, stores every object's desired state
- `kube-scheduler` — picks a node for newly created pods
- `kube-controller-manager` — runs the reconciliation loops that keep actual state matching desired state

**Node components**
- `kubelet` — talks to the container runtime, starts/stops containers per its node's pod specs
- `kube-proxy` — maintains the network rules that let Services route to the right pods
- container runtime (`containerd`) — pulls images, runs containers

On this single-node Minikube cluster, `minikube` plays both roles at once.

## Basics tutorial hands-on

```
$ kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
deployment.apps/kubernetes-bootcamp created

$ kubectl expose deployment/kubernetes-bootcamp --type=NodePort --port=8080
service/kubernetes-bootcamp exposed
```

Full output: [basics_tutorial_output.txt](basics_tutorial_output.txt)

The tutorial's own image failed on this cluster:

```
$ kubectl get pods
kubernetes-bootcamp-55d75dfbd9-ctn9g   0/1   ImagePullBackOff
kubernetes-bootcamp-5cc66bcc9b-5mlh6   0/1   CrashLoopBackOff

$ kubectl logs kubernetes-bootcamp-5cc66bcc9b-5mlh6
exec /bin/sh: exec format error

$ kubectl describe pod kubernetes-bootcamp-55d75dfbd9-ctn9g
...Failed to pull image "gcr.io/google-samples/kubernetes-bootcamp:v2": not found
```

`v1` is amd64-only (this cluster is arm64, hence the exec format error) and `v2` has been pulled from the registry entirely. Deleted the deployment and re-ran the same steps against `nginx:1.25-alpine` → `nginx:1.27-alpine` instead:

```
$ kubectl create deployment hello-k8s --image=nginx:1.25-alpine
$ kubectl expose deployment/hello-k8s --type=NodePort --port=80
$ kubectl scale deployments/hello-k8s --replicas=3
$ kubectl set image deployments/hello-k8s nginx=nginx:1.27-alpine
$ kubectl rollout status deployments/hello-k8s
deployment "hello-k8s" successfully rolled out

$ kubectl get pods
hello-k8s-6bb5f98d5f-xmfzb   0/1   Completed
hello-k8s-774d79f5bf-4ktwh   1/1   Running
hello-k8s-774d79f5bf-bqn86   1/1   Running
hello-k8s-774d79f5bf-lj6rc   1/1   Running
```

Full output: [scale_update_output.txt](scale_update_output.txt). Accessed via `kubectl port-forward svc/hello-k8s 8095:80` (NodePort isn't directly reachable from macOS through the Docker driver) — screenshot: [screenshot.png](screenshot.png).

Core objects used: Deployment, Pod, Service. Core commands: `kubectl create`, `get`, `expose`, `scale`, `set image`, `rollout status`, `delete`.
