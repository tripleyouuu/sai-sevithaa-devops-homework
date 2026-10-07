# Session 20: Monitoring, Observability & GitOps

## Task 1: Monitoring (`04-grafana/`)

Ran Prometheus + Grafana via `docker compose up -d`.

```
$ curl http://localhost:9090/-/healthy
Prometheus Server is Healthy.

$ curl http://localhost:3000/api/health
{"database": "ok", "version": "12.1.1", ...}
```

**Metrics**: Prometheus scrapes its own `/metrics` endpoint every 5s per
`prometheus.yml`, confirmed via the `up` metric:

```
$ curl "http://localhost:9090/api/v1/query?query=up"
{"metric":{"__name__":"up","instance":"prometheus:9090","job":"prometheus"},"value":[...,"1"]}
```

`up == 1` means the target is healthy and being scraped — this *is* the
most basic application-health signal Prometheus provides. Screenshot of
the target showing `UP` with a live "last scrape" timestamp:
[`04-grafana/screenshots/prometheus_targets.png`](04-grafana/screenshots/prometheus_targets.png)

**CPU/memory/application health**: added Prometheus as a Grafana data
source (`http://prometheus:9090`, the docker-compose service name — not
`localhost`, since Grafana reaches Prometheus over the compose network,
not the host) and confirmed "Successfully queried the Prometheus API" in
Grafana's own connection test, then ran the `up` query live in Grafana's
Explore view and watched it graph in real time. Grafana login screenshot:
[`04-grafana/screenshots/grafana_login.png`](04-grafana/screenshots/grafana_login.png) ·
raw query result: [`04-grafana/screenshots/prometheus_up_query.json`](04-grafana/screenshots/prometheus_up_query.json)

**Alerts**: not configured in this minimal 2-container demo (no
Alertmanager), but the `IF error_rate > 5% THEN alert` pattern is what
Prometheus's own `alerting_rules` + Alertmanager would implement on top of
exactly these same scraped metrics.

Containers stopped (`docker compose down`) after verification, to avoid
leaving anything running.

## Task 2: Observability

Kubernetes already surfaces all three pillars without extra tooling —
this course's own earlier sessions already produced live examples of each:

| Pillar | What it answers | Example already produced in this repo |
|---|---|---|
| **Metrics** | "How much / how fast, right now?" — numeric time series | `kubectl top pods`, the HPA's `cpu: 46%/50%` reading (Session 13) |
| **Logs** | "What happened, in detail, at this moment?" — discrete events | `kubectl logs`, used throughout Sessions 9-14 |
| **Traces** | "What path did this one request take across services?" — not demoed hands-on in this course, since it needs app-level instrumentation (OpenTelemetry) that none of this course's demo apps include | — |

**Why observability is required**: monitoring alone answers *known*
failure modes ("is CPU too high") with pre-built dashboards/alerts.
Observability is the broader ability to ask *new, arbitrary* questions
about a system's internal state from its external outputs, without
having shipped new code first — essential once a system is distributed
enough (microservices, Kubernetes) that no single person holds its whole
behavior in their head, and failures are novel more often than repeats of
a known pattern.

**Common tools**: Prometheus + Grafana (metrics, demoed above), the
EFK/ELK stack or Loki (logs), Jaeger/Tempo + OpenTelemetry (traces).

**Kubernetes observability**: the control plane itself is a built-in
observability source — `kubectl describe`'s Events section, `kubectl get
events`, and the kubelet's own cAdvisor metrics (what `kubectl top` reads)
are all first-class K8s signals that needed zero extra tooling to access,
as Sessions 9-14 of this course repeatedly relied on.

## Task 3: GitOps

**What is GitOps**: a deployment model where a Git repository is the
single source of truth for a system's *desired* state, and an in-cluster
controller continuously reconciles the *actual* cluster state to match it
— instead of a CI pipeline pushing changes imperatively (`kubectl apply`
from a runner), the cluster pulls its own desired state from Git.

**Git as the source of truth**: every `kubectl apply` run manually in
Sessions 9-19 of this course was imperative — a human or a CI job decided
*when* to apply what. GitOps inverts that: the manifests in Git are the
only thing that matters, and a controller inside the cluster watches that
Git repo and applies whatever it finds, on its own schedule.

**Declarative configuration**: the Git repo holds *what should exist*
(`replicas: 5`, `image: nginx:1.27-alpine`), never a sequence of commands
— matches every YAML manifest this entire course has used from Session 9
onward.

**Continuous reconciliation**: the controller doesn't just sync once —
it keeps comparing live cluster state to the Git-declared state forever,
and corrects drift automatically. Demonstrated live below (`selfHeal: true`
is exactly this).

**GitOps workflow**: `git push` to the tracked repo/path → controller
detects the new commit → diffs it against live cluster state → applies
the diff → cluster converges to match Git, with no human running
`kubectl apply` at all.

**Kubernetes + GitOps, demoed live with Argo CD**:

```
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side --force-conflicts
...
$ kubectl get pods -n argocd
# all 7 Argo CD components Running 1/1

$ kubectl apply -f 07-argocd/app/argocd-application.yaml
application.argoproj.io/session20-app created

$ kubectl get application -n argocd
NAME            SYNC STATUS   HEALTH STATUS
session20-app   Synced        Healthy

$ kubectl get all -n session20
pod/session20-gitops-app-679fcbbd85-545kn   1/1   Running
pod/session20-gitops-app-679fcbbd85-64dgw   1/1   Running
pod/session20-gitops-app-679fcbbd85-68pln   1/1   Running
pod/session20-gitops-app-679fcbbd85-dsdfk   1/1   Running
pod/session20-gitops-app-679fcbbd85-nfwss   1/1   Running
deployment.apps/session20-gitops-app   5/5   5   5
```

Argo CD's `Application` resource (`07-argocd/app/argocd-application.yaml`)
points at a public Git repo/path; within ~10 seconds of being applied, Argo
CD cloned it, created the `session20` namespace (`CreateNamespace=true`),
and deployed exactly what the repo's `deployment.yaml` declares —
**5 replicas**, matching the source file exactly — with zero `kubectl
apply` against the app itself. `syncPolicy.automated.selfHeal: true` means
if anyone manually edited that Deployment afterward (e.g. `kubectl scale
--replicas=1`), Argo CD would revert it back to 5 on its own, since Git
still says 5 — that's "continuous reconciliation" in action, not just a
one-time apply.

Confirmed the Argo CD UI itself is live and serving (not just the API):
[`07-argocd/argocd_login.png`](07-argocd/argocd_login.png). Full command
transcript: [`gitops_output.txt`](gitops_output.txt)

Cleaned up afterward (`kubectl delete application`, deleted the
`session20` namespace, deleted the `argocd` namespace) to leave the
cluster clean.
