# Session 15 — Helm

## Task 1 — Helm Commands

All run against `demo-chart/` (a standard `helm create`-scaffolded nginx chart):

| Command | What it did |
|---|---|
| `helm create` | scaffolds a new chart's folder structure |
| `helm install demo-release ./demo-chart` | renders templates, deploys → revision 1 |
| `helm list` | shows installed releases |
| `helm status demo-release` | release state + every resource it owns |
| `helm get values` / `get manifest` | values in effect / fully rendered YAML |
| `helm upgrade ... --set replicaCount=2` | re-renders, applies the diff → revision 2 |
| `helm history demo-release` | full revision timeline |
| `helm rollback demo-release 1` | re-applies revision 1 as a new revision, not a time-travel |
| `helm uninstall demo-release` | deletes every resource the release owns |
| `helm repo add` / `repo update` | registers a chart repo and refreshes its index |
| `helm search repo bitnami/nginx` | searches added repos |

Full output: [task1_commands_output.txt](task1_commands_output.txt), [task1_commands_output2.txt](task1_commands_output2.txt)

## Task 2 — Rollback Workflow

```
install (rev 1, nginx:1.16.0, 1 replica)
upgrade (rev 2, replicaCount=2)
upgrade again (rev 3, image.tag=1.25-alpine)
rollback to rev 1
```

```
$ helm history demo-release
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         superseded  Upgrade complete
4         deployed    Rollback to 1
```

Rollback doesn't delete history, it adds to it — revision 4 re-applies revision 1's exact manifest as a new entry, so `helm history` is always a complete forward audit trail including rollbacks themselves. Full output: [task2_rollback_output.txt](task2_rollback_output.txt)

## Task 3 — Mini Project: Notes App Chart

One chart, two values files for dev and prod:

```
$ helm install notes-app ./notes-chart
$ kubectl get deployment -o jsonpath='{...image}'
nginx:1.24   (1 replica, development)

$ helm upgrade notes-app ./notes-chart -f notes-chart/values-prod.yaml
$ kubectl get deployment -o jsonpath='{...replicas}{...image}'
3
nginx:1.25   (production)
```

Same templates, different manifests, purely from `-f values-prod.yaml`. Full output: [mini-project/mini_project_output.txt](mini-project/mini_project_output.txt)
