# Session 15: Helm

## Task 1: Helm Commands

All run against `demo-chart/` (a standard `helm create`-scaffolded nginx
chart):

| Command | What it did |
|---|---|
| `helm create` | Scaffolds a new chart's folder structure (`Chart.yaml`, `values.yaml`, `templates/`) |
| `helm install demo-release ./demo-chart` | Rendered the chart's templates and deployed them → REVISION 1 |
| `helm list` | Shows all installed releases, their chart version and app version |
| `helm status demo-release` | Shows the release's current state + every resource it owns |
| `helm get values` / `helm get manifest` | Dumps the values actually in effect / the fully rendered YAML sent to the API server |
| `helm upgrade demo-release ./demo-chart --set replicaCount=2` | Re-renders with new values, applies the diff → REVISION 2 |
| `helm history demo-release` | Full revision timeline with status per revision |
| `helm rollback demo-release 1` | Re-applies revision 1's manifest as a **new** revision (4), not a time-travel — history keeps growing forward |
| `helm uninstall demo-release` | Deletes every resource the release owns |
| `helm repo add` / `helm repo update` | Registers a chart repository (Bitnami) and refreshes its index |
| `helm search repo bitnami/nginx` | Searches added repos for matching charts |

Full output: [`task1_commands_output.txt`](task1_commands_output.txt), [`task1_commands_output2.txt`](task1_commands_output2.txt)

## Task 2: Helm Rollback Workflow

```
Install (rev 1, nginx:1.16.0, 1 replica)
  ↓
Upgrade (rev 2, replicaCount=2)
  ↓ kubectl get deployment -o jsonpath=... -> replicas: 2
Upgrade again (rev 3, image.tag=1.25-alpine)
  ↓ kubectl get deployment ... -> image: nginx:1.25-alpine
Rollback to rev 1
  ↓ helm rollback demo-release 1
Verify
  ↓ kubectl get deployment ... -> image: nginx:1.16.0 (back to original)
```

```
$ helm history demo-release
REVISION	UPDATED                 	STATUS    	CHART           	APP VERSION	DESCRIPTION
1       	23:19:27 2026	superseded	demo-chart-0.1.1	1.16.0     	Install complete
2       	23:19:40 2026	superseded	demo-chart-0.1.1	1.16.0     	Upgrade complete
3       	23:20:14 2026	superseded	demo-chart-0.1.1	1.16.0     	Upgrade complete
4       	23:20:19 2026	deployed  	demo-chart-0.1.1	1.16.0     	Rollback to 1
```

The key thing this proves: **rollback doesn't delete history, it adds to
it** — revision 4 ("Rollback to 1") re-applies revision 1's exact manifest
as a brand new entry, so `helm history` always shows a complete forward
audit trail of every change, including rollbacks themselves. Full output:
[`task2_rollback_output.txt`](task2_rollback_output.txt)

## Task 3: Mini Project — Notes App Chart

`mini-project/notes-chart/` with two values files representing dev and
prod environments:

```
$ helm install notes-app ./notes-chart          # uses values.yaml
$ kubectl get deployment -o jsonpath='{...image}'
nginx:1.24   (1 replica, environment: development)

$ helm upgrade notes-app ./notes-chart -f notes-chart/values-prod.yaml
$ kubectl get deployment -o jsonpath='{...replicas}{...image}'
3
nginx:1.25   (environment: production)
```

One chart, two environments, zero template changes — purely driven by
`-f values-prod.yaml` overriding `replicaCount`, `image.tag`, and
`app.environment`. This is the core Helm value proposition: the same
templates produce different, environment-appropriate manifests. Full
output: [`mini-project/mini_project_output.txt`](mini-project/mini_project_output.txt)
