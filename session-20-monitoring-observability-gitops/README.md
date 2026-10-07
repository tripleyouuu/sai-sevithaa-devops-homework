# Session 20 — Monitoring, Observability & GitOps

## Task 1 — Monitoring

Ran Prometheus + Grafana via `docker compose up -d`.

```
$ curl http://localhost:9090/-/healthy
Prometheus Server is Healthy.

$ curl http://localhost:3000/api/health
{"database": "ok", "version": "12.1.1", ...}

$ curl "http://localhost:9090/api/v1/query?query=up"
{"metric":{"__name__":"up","instance":"prometheus:9090","job":"prometheus"},"value":[...,"1"]}
```

`up == 1` is the basic health signal. Screenshot: [04-grafana/screenshots/prometheus_targets.png](04-grafana/screenshots/prometheus_targets.png)

Added Prometheus as a Grafana data source (`http://prometheus:9090`, the compose service name, not `localhost`), confirmed the connection test, ran the `up` query live in Grafana's Explore view. [04-grafana/screenshots/grafana_login.png](04-grafana/screenshots/grafana_login.png), [04-grafana/screenshots/prometheus_up_query.json](04-grafana/screenshots/prometheus_up_query.json)

Alerts weren't configured in this minimal demo (no Alertmanager), but `IF error_rate > 5% THEN alert` is exactly what Prometheus's alerting rules + Alertmanager would add on top of these same metrics.

Containers stopped afterward.

## Task 2 — Observability

| Pillar | Answers | Example from this repo |
|---|---|---|
| Metrics | how much/fast, right now | `kubectl top pods`, the HPA's `cpu: 46%/50%` (Session 13) |
| Logs | what happened, in detail | `kubectl logs`, Sessions 9-14 |
| Traces | what path did one request take across services | not demoed — needs app-level instrumentation (OpenTelemetry) none of this course's demo apps have |

Monitoring answers known failure modes with pre-built dashboards. Observability is the broader ability to ask new, arbitrary questions about a system from its external outputs, without shipping new code first — matters once a system is distributed enough that no one holds its whole behavior in their head.

Common tools: Prometheus/Grafana (metrics), EFK/Loki (logs), Jaeger/Tempo (traces). Kubernetes itself is a built-in observability source — `kubectl describe` events, `kubectl get events`, and `kubectl top` (reading kubelet's cAdvisor) needed zero extra tooling, as Sessions 9-14 relied on repeatedly.

## Task 3 — GitOps

A Git repo is the single source of truth for desired state, and a controller inside the cluster continuously reconciles actual state to match it — instead of a CI pipeline pushing `kubectl apply` imperatively, the cluster pulls its own state from Git. The manifests describe what should exist (`replicas: 5`), never a sequence of commands — same as every YAML this course has used since Session 9. The controller doesn't sync once; it keeps comparing live state to Git and corrects drift automatically (`selfHeal: true`, demoed below).

Workflow: `git push` → controller detects the commit → diffs against live state → applies the diff → cluster converges, no human runs `kubectl apply`.

Demoed with Argo CD:

```
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side --force-conflicts
$ kubectl get pods -n argocd
(all 7 Argo CD components Running 1/1)

$ kubectl apply -f 07-argocd/app/argocd-application.yaml
application.argoproj.io/session20-app created

$ kubectl get application -n argocd
session20-app   Synced   Healthy

$ kubectl get all -n session20
deployment.apps/session20-gitops-app   5/5   5   5
```

The `Application` resource points at a public repo/path; within ~10 seconds Argo CD cloned it, created the `session20` namespace, and deployed exactly what the repo's `deployment.yaml` declares — 5 replicas — with zero manual `kubectl apply` against the app. `selfHeal: true` means a manual `kubectl scale --replicas=1` afterward would get reverted back to 5 automatically, since Git still says 5.

Confirmed the Argo CD UI itself is live: [07-argocd/argocd_login.png](07-argocd/argocd_login.png). Full transcript: [gitops_output.txt](gitops_output.txt)

Cleaned up afterward — deleted the Application, the `session20` namespace, and the `argocd` namespace.
