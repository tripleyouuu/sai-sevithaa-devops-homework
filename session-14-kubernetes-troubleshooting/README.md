# Session 14 — Kubernetes Troubleshooting

## Task 1 — Commands

Ran every command against real pods (`get-demo`, `logs-demo`, `exec-demo`, `events-demo`):

| Command | What it showed |
|---|---|
| `kubectl get pods` / `-o wide` | status, plus node + IP |
| `kubectl describe pod get-demo` | full spec, container state, events |
| `kubectl logs logs-demo` | container stdout |
| `kubectl exec get-demo -- nginx -v` | ran a command inside the live container |
| `kubectl get events --sort-by=.lastTimestamp` | cluster-wide event stream |
| `kubectl explain pod.spec.containers.livenessProbe` | live API field docs |
| `kubectl top pods` | real-time CPU/memory per pod |

Full output: [task1_commands_output.txt](task1_commands_output.txt)

## Task 2 — Troubleshoot Common Issues

Reproduced all 5 scenarios, each its own broken YAML: identify → investigate → root cause → fix → verify.

**CrashLoopBackOff**
```
$ kubectl logs fail-1-crashloop-pod
[FATAL ERROR]: DATABASE_URL environment variable is MISSING!
```
Missing env var, app exits 1 every time. Fixed by supplying `DATABASE_URL` — pod went healthy. [scenario1_output.txt](scenario1_output.txt)

**ImagePullBackOff**
```
Failed to pull image "yatri-api-service:v999-invalid-tag-does-not-exist": pull access denied
```
Tag doesn't exist. Fixed by pointing at `nginx:1.27`. [scenario2_output.txt](scenario2_output.txt)

**Pending**
```
Warning  FailedScheduling  0/1 nodes are available: Insufficient cpu, Insufficient memory.
```
Pod asked for 500 CPU cores + 1000Gi memory. Fixed by lowering to `100m`/`64Mi`. [scenario3_output.txt](scenario3_output.txt)

**DNS / Service connectivity failure**
```
$ kubectl exec fail-4-dns-failure-pod -- nslookup postgres-db-wrong-name.production.svc.cluster.local
** server can't find ...: NXDOMAIN
```
Hostname pointed at a service/namespace that doesn't exist — a typo, not a DNS problem. Fix is correcting the hostname. [scenario4_output.txt](scenario4_output.txt)

**OOMKilled**
```
$ kubectl get pod fail-5-oomkilled-pod
fail-5-oomkilled-pod   0/1   OOMKilled   1 (9s ago)   10s
State: Terminated, Reason: OOMKilled, Exit Code: 137
```
Container allocates ~1000MB, limit was `20Mi`. First tried raising to `256Mi` — still OOMKilled, since the real peak was higher than the YAML's comment claimed. `1200Mi` let it complete. [scenario5_output.txt](scenario5_output.txt)

## Task 3 — Mini Project

| Problem | What I Saw | Command | Root Cause | Fix |
|---|---|---|---|---|
| Broken Pod | `ErrImagePull` → `ImagePullBackOff` | `kubectl describe pod` | tag doesn't exist on Docker Hub | use a real tag |
| Service Problem | `kubectl get endpoints` → `<none>` | `describe service` + `get pods --show-labels` | selector didn't match pod labels | `kubectl patch service` to fix the selector |
| Image Problem | same as Broken Pod | `describe pod` → Events | invalid image tag | correct the tag |

Q&A: status was `ImagePullBackOff`; the error was `failed to resolve reference ... not found`; found via `kubectl describe pod` (Events section); the tag was never published; fix was pointing at a real tag.

Full transcript: [mini-project/mini_project_output.txt](mini-project/mini_project_output.txt)

### Checklist that actually worked today

```
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- sh
kubectl get events

kubectl describe service <service-name>
kubectl get endpoints <service-name>
nslookup <service-name>
```

`describe` and `get endpoints` alone solved 4 of the 6 problems reproduced today.
