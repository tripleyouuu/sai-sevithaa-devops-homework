# Session 10 — Kubernetes Pods, ReplicaSets & Deployments

Each strategy cleaned up with `kubectl delete` before the next, to avoid clashes.

## Task 1 — Deployment Strategies

### 1. Rolling Update

`maxSurge: 1, maxUnavailable: 0` — one extra pod comes up before an old one goes down.

```
$ kubectl apply -f 01-rolling-update/deployment-v1.yaml -f 01-rolling-update/service.yaml
$ kubectl apply -f 01-rolling-update/deployment-v2.yaml
$ kubectl get pods -l app=app-rolling -o wide
app-rolling-56bff6d88c-bl5dr   1/1   Running       0   6s     (new)
app-rolling-56bff6d88c-kfddj   1/1   Running       0   18s    (new)
app-rolling-86d7d44d5b-mqg5b   1/1   Terminating   0   33s    (old)
app-rolling-86d7d44d5b-pjblr   0/1   Completed     0   33s    (old)
```

Old and new pods coexist mid-rollout. Full output: [01-rolling-update/output.txt](01-rolling-update/output.txt)

### 2. Blue-Green

Two full Deployments running at once; the cutover is a Service selector flip.

```
$ kubectl get svc myapp-service -o jsonpath='{.spec.selector}'
{"app":"myapp","slot":"blue"}
$ curl .../   ->  Version: v1 | Slot: BLUE (LIVE)

$ kubectl apply -f 02-blue-green/service-green.yaml
$ kubectl get svc myapp-service -o jsonpath='{.spec.selector}'
{"app":"myapp","slot":"green"}
$ curl .../   ->  Version: v2 | Slot: GREEN (PROMOTED)
```

Full output: [02-blue-green/output.txt](02-blue-green/output.txt) · Screenshot: [02-blue-green/green_active_screenshot.png](02-blue-green/green_active_screenshot.png)

### 3. Canary

One Service selects both `app-stable` (9 replicas) and `app-canary` (1 replica), so the pod-count ratio is the traffic split. `kubectl port-forward` pins to one pod for the life of the connection and can't show a split, so I tested from inside the cluster with 20 real requests through the Service's ClusterIP instead:

```
$ kubectl run curl-test --image=curlimages/curl --restart=Never --rm -i --command -- \
    sh -c 'for i in $(seq 1 20); do curl -s http://myapp-canary-service/; done'
...
   2 Track: canary
  13 Track: stable
```

~13% canary (sample noise around the 10% target). Full output: [03-canary/output.txt](03-canary/output.txt) · Screenshot: [03-canary/screenshot.png](03-canary/screenshot.png)

### 4. Recreate

```
$ kubectl apply -f 04-recreate/deployment-v2.yaml
$ kubectl get pods -l app=app-recreate
app-recreate-7bd8d89b8b-kbffq   1/1   Running   0   0s
app-recreate-7bd8d89b8b-mpv7p   1/1   Running   0   0s
app-recreate-7bd8d89b8b-qqv8k   1/1   Running   0   0s
```

All three new pods appear at age 0s at once — the old ReplicaSet was scaled to zero first, then the new one created. A brief outage, but old and new never run together. Full output: [04-recreate/output.txt](04-recreate/output.txt)

## Task 2 — Pod Lifecycle

Applied all 12 YAMLs, checked status/details, cleaned up.

| # | File | Resulting status | What it shows |
|---|---|---|---|
| 01 | `01-running.yaml` | `Running` | normal healthy state |
| 02 | `02-pending.yaml` | `Pending` | pod requests more memory than the node has free |
| 03 | `03-succeeded.yaml` | `Completed` | container runs to completion, exits 0 |
| 04 | `04-failed.yaml` | `Error` | exits non-zero, no restart policy |
| 05 | `05-crashloopbackoff.yaml` | `CrashLoopBackOff` | keeps exiting, kubelet backs off restarts |
| 06 | `06-imagepullbackoff.yaml` | `ImagePullBackOff` | image reference doesn't exist |
| 07 | `07-readiness.yaml` | `Running`, `1/1` | readiness probe passing, receives traffic |
| 08 | `08-liveness.yaml` | `Running` | liveness probe watches and restarts on failure |
| 09 | `09-startup.yaml` | `0/1` → `1/1` after ~35s | startup probe delays the others until the app is actually up |
| 10 | `10-init-container.yaml` | `Init:0/1` → `1/1 Running` | init container runs before the main one starts |
| 11 | `11-multi-container.yaml` | `2/2 Running` | app + sidecar started together |
| 12 | `12-termination.yaml` | graceful shutdown | `kubectl delete` took 10.9s — the `trap TERM` handler ran its cleanup before the grace period ran out |

Full outputs: [pod-lifecycle/output_part1.txt](pod-lifecycle/output_part1.txt) (01-06), [pod-lifecycle/output_part2.txt](pod-lifecycle/output_part2.txt) (07,08,10,11), [pod-lifecycle/09-startup_output.txt](pod-lifecycle/09-startup_output.txt), [pod-lifecycle/12-termination_output.txt](pod-lifecycle/12-termination_output.txt)

The `02-pending` case is a real resource limit on this 2 vCPU / 4 GB Minikube VM, not a scripted failure.
