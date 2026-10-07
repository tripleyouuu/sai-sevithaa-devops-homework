# Session 10: Kubernetes Pods, ReplicaSets & Deployments

All YAMLs apply straight to a local Minikube cluster. Commands and output
captured per strategy; each is cleaned up (`kubectl delete`) before the next
to avoid resource/port clashes.

## Task 1: Deployment Strategies

### 1. Rolling Update (`01-rolling-update/`)

`maxSurge: 1, maxUnavailable: 0` — one extra pod is created before an old
one is removed, so capacity never drops below the desired count.

```
$ kubectl apply -f 01-rolling-update/deployment-v1.yaml -f 01-rolling-update/service.yaml
$ kubectl apply -f 01-rolling-update/deployment-v2.yaml
$ kubectl get pods -l app=app-rolling -o wide
NAME                           READY   STATUS        RESTARTS   AGE
app-rolling-56bff6d88c-bl5dr   1/1     Running       0          6s     <- new (v2)
app-rolling-56bff6d88c-kfddj   1/1     Running       0          18s    <- new (v2)
app-rolling-56bff6d88c-nfxtd   1/1     Running       0          12s    <- new (v2)
app-rolling-56bff6d88c-wzkcz   1/1     Running       0          24s    <- new (v2)
app-rolling-86d7d44d5b-mqg5b   1/1     Terminating   0          33s    <- old (v1), still draining
app-rolling-86d7d44d5b-pjblr   0/1     Completed     0          33s    <- old (v1)
```

Old and new ReplicaSet's pods coexist mid-rollout — exactly what "rolling"
means. Full output: [`01-rolling-update/output.txt`](01-rolling-update/output.txt)

### 2. Blue-Green (`02-blue-green/`)

Two full Deployments (`app-blue` v1, `app-green` v2) run simultaneously;
the switch is purely a Service selector change (`slot: blue` → `slot: green`),
so the cutover is instant with zero rollout time.

```
$ kubectl get svc myapp-service -o jsonpath='{.spec.selector}'
{"app":"myapp","slot":"blue"}
$ curl .../   ->  Version: v1 | Slot: BLUE (LIVE)

$ kubectl apply -f 02-blue-green/service-green.yaml
$ kubectl get svc myapp-service -o jsonpath='{.spec.selector}'
{"app":"myapp","slot":"green"}
$ curl .../   ->  Version: v2 | Slot: GREEN (STANDBY -> PROMOTED)
```

Full output: [`02-blue-green/output.txt`](02-blue-green/output.txt) · Screenshot of the switched (green) state: [`02-blue-green/green_active_screenshot.png`](02-blue-green/green_active_screenshot.png)

### 3. Canary (`03-canary/`)

One Service selects both `app-stable` (9 replicas) and `app-canary` (1
replica) via their shared `app=myapp-canary` label — kube-proxy then
load-balances across all 10 pods, so the pod-count ratio *is* the traffic
split (9:1 = 90/10).

`kubectl port-forward` to a Service always pins to a single backend pod for
the life of the connection, so it can't show a traffic split — tested from
*inside* the cluster instead with a disposable pod making 20 real requests
through the Service's ClusterIP:

```
$ kubectl run curl-test --image=curlimages/curl --restart=Never --rm -i --command -- \
    sh -c 'for i in $(seq 1 20); do curl -s http://myapp-canary-service/; done'
...
=== tally ===
   2 Track: canary
  13 Track: stable
```

~13% canary in this sample (small-sample noise around the 10% target) —
confirms both versions are genuinely live and splitting real traffic. Full
output: [`03-canary/output.txt`](03-canary/output.txt) · Screenshot: [`03-canary/screenshot.png`](03-canary/screenshot.png)

### 4. Recreate (`04-recreate/`)

```
$ kubectl apply -f 04-recreate/deployment-v2.yaml
$ kubectl get pods -l app=app-recreate
NAME                            READY   STATUS    RESTARTS   AGE
app-recreate-7bd8d89b8b-kbffq   1/1     Running   0          0s
app-recreate-7bd8d89b8b-mpv7p   1/1     Running   0          0s
app-recreate-7bd8d89b8b-qqv8k   1/1     Running   0          0s
```

All three new pods appear at **AGE 0s simultaneously** — proof the old
ReplicaSet was scaled to zero first and only then was the new one created,
unlike rolling update's overlap. This strategy trades a brief outage for
the guarantee that old and new versions never run at the same time (useful
when two versions can't safely coexist, e.g. incompatible DB migrations).
Full output: [`04-recreate/output.txt`](04-recreate/output.txt)

## Task 2: Pod Lifecycle (`pod-lifecycle/`)

Applied all 12 YAMLs, checked status/details for each, then cleaned up.

| # | File | Resulting phase/status | What it demonstrates |
|---|---|---|---|
| 01 | `01-running.yaml` | `Running` | normal healthy steady state |
| 02 | `02-pending.yaml` | `Pending` (`FailedScheduling`) | pod requests more memory than the node has free — scheduler can't place it |
| 03 | `03-succeeded.yaml` | `Succeeded`/`Completed` | a Job-style container that runs to completion and exits 0 |
| 04 | `04-failed.yaml` | `Error` | container exits non-zero, no restart policy to retry |
| 05 | `05-crashloopbackoff.yaml` | `CrashLoopBackOff` | container keeps exiting, kubelet backs off restart attempts exponentially |
| 06 | `06-imagepullbackoff.yaml` | `ImagePullBackOff` | image reference doesn't exist (`pull access denied`) |
| 07 | `07-readiness.yaml` | `Running`, `1/1` | readiness probe passing — pod receives Service traffic |
| 08 | `08-liveness.yaml` | `Running` | liveness probe watches for a stuck process and restarts the container if it fails |
| 09 | `09-startup.yaml` | `0/1 Running` → `1/1 Running` after ~35s | startup probe holds off liveness/readiness checks until a slow-starting app signals it's actually up |
| 10 | `10-init-container.yaml` | `Init:0/1` → `1/1 Running` | init container runs to completion *before* the main container starts |
| 11 | `11-multi-container.yaml` | `2/2 Running` | app + sidecar container in one pod, started together |
| 12 | `12-termination.yaml` | graceful shutdown | `kubectl delete` took **10.9s** (not instant, not the full 20s grace period) — the container's `trap TERM` handler ran its 10s cleanup and exited on its own before the grace period expired |

Full outputs: [`pod-lifecycle/output_part1.txt`](pod-lifecycle/output_part1.txt) (01-06),
[`pod-lifecycle/output_part2.txt`](pod-lifecycle/output_part2.txt) (07,08,10,11),
[`pod-lifecycle/09-startup_output.txt`](pod-lifecycle/09-startup_output.txt),
[`pod-lifecycle/12-termination_output.txt`](pod-lifecycle/12-termination_output.txt)

The 02-pending case is a genuine resource constraint hit on this
2 vCPU / 4 GB Minikube VM, not a scripted failure — the scheduler really
did refuse to place it, which is the most realistic possible demo of
`Pending`.
