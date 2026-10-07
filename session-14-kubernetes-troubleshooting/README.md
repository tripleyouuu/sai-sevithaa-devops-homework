# Session 14: Kubernetes Troubleshooting

## Task 1: Kubernetes Commands

Ran every command from the task list against real pods (`get-demo`,
`logs-demo`, `exec-demo`, `events-demo`):

| Command | What it showed |
|---|---|
| `kubectl get pods` / `get pods -o wide` | Pod status, and with `-o wide` also node + IP |
| `kubectl describe pod get-demo` | Full pod spec, container state, events |
| `kubectl logs logs-demo` | The container's stdout (`Application started` → `Application is healthy` repeating) |
| `kubectl exec get-demo -- nginx -v` | Ran a command inside the live container |
| `kubectl get events --sort-by=.lastTimestamp` | Cluster-wide event stream, newest last |
| `kubectl explain pod.spec.containers.livenessProbe` | Live API field docs, pulled from the cluster's own OpenAPI schema |
| `kubectl top pods` | Real-time CPU/memory per pod (via metrics-server) |

Full output: [`task1_commands_output.txt`](task1_commands_output.txt)

## Task 2: Troubleshoot Common Issues

Reproduced all 5 scenarios from `scenarios/`, each with its own
intentionally broken YAML — followed the same loop every time: identify →
investigate → root cause → fix → verify.

### CrashLoopBackOff
```
$ kubectl logs fail-1-crashloop-pod
[FATAL ERROR]: DATABASE_URL environment variable is MISSING!
```
**Root cause:** app requires `DATABASE_URL`, container has no such env var,
exits 1 every time, kubelet backs off restarts. **Fix:** supply the env
var — reran with `--env="DATABASE_URL=..."`, pod went `Completed`/healthy.
Output: [`scenario1_output.txt`](scenario1_output.txt)

### ImagePullBackOff
```
Failed to pull image "yatri-api-service:v999-invalid-tag-does-not-exist":
...pull access denied, repository does not exist...
```
**Root cause:** image name/tag doesn't exist on the registry. **Fix:**
pointed at a real image (`nginx:1.27`) — `Running` immediately.
Output: [`scenario2_output.txt`](scenario2_output.txt)

### Pending
```
Warning  FailedScheduling  0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory.
```
**Root cause:** pod requested 500 CPU cores + 1000Gi memory — no node on
earth satisfies that. **Fix:** lowered the request to `100m`/`64Mi`, pod
scheduled instantly. Output: [`scenario3_output.txt`](scenario3_output.txt)

### Service / DNS connectivity failure
```
$ kubectl exec fail-4-dns-failure-pod -- nslookup postgres-db-wrong-name.production.svc.cluster.local
** server can't find postgres-db-wrong-name.production.svc.cluster.local: NXDOMAIN
```
**Root cause:** hostname points at a service/namespace that doesn't exist
— a typo, not a DNS/CoreDNS problem (CoreDNS correctly reports NXDOMAIN for
a name that genuinely isn't registered). **Fix:** correct the hostname to
match a real Service's `<name>.<namespace>.svc.cluster.local`.
Output: [`scenario4_output.txt`](scenario4_output.txt)

### OOMKilled
```
$ kubectl get pod fail-5-oomkilled-pod
fail-5-oomkilled-pod   0/1   OOMKilled   1 (9s ago)   10s

State:   Terminated
  Reason:      OOMKilled
  Exit Code:   137
```
**Root cause:** container allocates up to 100 × 10MB (~1000MB total) while
`resources.limits.memory` caps it at `20Mi` — the kernel OOM-killer kills
the process (exit code 137 = 128 + SIGKILL/9) the moment it exceeds the
cgroup limit. **Fix:** first tried `256Mi` — still OOMKilled, because the
script's actual peak is ~1000MB, not the ~200MB the YAML's comment implied;
raising the limit to `1200Mi` let it run to completion (`Completed`). A
good reminder to verify an app's *real* memory need rather than trust a
comment. Output: [`scenario5_output.txt`](scenario5_output.txt)

## Task 3: Mini Project

Ran the full guided workbook from `mini-project/README.md` end to end.

| Problem | What I Saw | Command I Used | Root Cause | Fix |
|---|---|---|---|---|
| **Broken Pod** | `ErrImagePull` → `ImagePullBackOff` | `kubectl describe pod project-broken-pod` | `nginx:this-tag-does-not-exist` — tag doesn't exist on Docker Hub | Use a real tag (e.g. `nginx:1.27`) |
| **Service Problem** | `kubectl get endpoints troubleshooting-service` → `<none>` | `kubectl describe service` + `kubectl get pods --show-labels` | Service `selector: app=wrong-app` didn't match the pods' real label `app=troubleshooting-app` | `kubectl patch service ... selector.app=troubleshooting-app` — endpoints repopulated immediately |
| **Image Problem** | Same as Broken Pod row | `kubectl describe pod` → Events | Invalid/non-existent image tag | Correct the tag to a published one |

**Q&A for the broken pod:**
1. **Status:** `ImagePullBackOff` (started as `ErrImagePull`, then backed off)
2. **Actual error:** `failed to resolve reference ... nginx:this-tag-does-not-exist: not found`
3. **Command that found it:** `kubectl describe pod project-broken-pod` (the Events section specifically)
4. **What's wrong with the image:** the tag `this-tag-does-not-exist` was never published for the `nginx` image
5. **Fix:** change the image reference to a tag that actually exists, e.g. `nginx:1.27`

Full transcript: [`mini-project/mini_project_output.txt`](mini-project/mini_project_output.txt)

### Final troubleshooting checklist (confirmed useful in practice today)

```
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- sh
kubectl get events

# for Service problems
kubectl describe service <service-name>
kubectl get endpoints <service-name>
nslookup <service-name>
```

Every single scenario today was found with exactly this checklist, in this
order — `describe` and `get endpoints` alone solved 4 of the 6 problems
reproduced in this session.
