# Session 12 — Kubernetes Ingress, ConfigMaps & Secrets

## Task 1 & 2 — ConfigMap and Secret

Deployed `yatri-app-config` and `yatri-db-secret` into a backend pod via `envFrom`/`secretKeyRef`, verified the decoded values live inside the container:

```
$ kubectl exec deploy/yatri-backend -- env | grep -E 'ENVIRONMENT|LOG_LEVEL|POSTGRES'
POSTGRES_DB=yatri_production_db
POSTGRES_PASSWORD=secretpassword
POSTGRES_USER=yatri_admin
ENVIRONMENT=production
LOG_LEVEL=INFO
```

`kubectl get secret yatri-db-secret -o yaml` only shows the base64-encoded form — base64 is an encoding, not encryption. Full output: [task1_2_output.txt](task1_2_output.txt)

Secrets shouldn't be committed to Git because base64 is trivially reversible (`base64 -d`) — a Secret manifest in a repo is functionally the same as committing the plaintext credential. In practice: keep Secret manifests out of version control, generate them at deploy time from a vault, or use something like Sealed Secrets that lets you commit an actually-encrypted version.

## Task 3 — Ingress

Frontend (nginx) + backend (Python, reads the ConfigMap/Secret) behind one Ingress doing path-based routing: `/` → frontend, `/api/*` → backend.

```
$ minikube addons enable ingress
$ kubectl apply -f configmap.yaml -f secret.yaml -f backend.yaml -f frontend.yaml -f ingress.yaml
$ kubectl get ingress yatri-ingress
yatri-ingress   nginx   yatri.local             80      17s
```

Accessed via port-forward with a `Host: yatri.local` header (NodePort/LoadBalancer IPs aren't directly reachable from macOS through Colima):

```
$ curl -s -H 'Host: yatri.local' http://localhost:8100/
...nginx welcome page...

$ curl -s -H 'Host: yatri.local' http://localhost:8100/api/
ENVIRONMENT     : production
POSTGRES_USER   : yatri_admin
POSTGRES_DB     : yatri_production_db
```

Both routes work, and this re-confirms the ConfigMap/Secret injection through a real HTTP response. Screenshots: [04-full-demo/screenshot_frontend.png](04-full-demo/screenshot_frontend.png), [04-full-demo/screenshot_api.png](04-full-demo/screenshot_api.png). Full output: [04-full-demo/task3_output.txt](04-full-demo/task3_output.txt)

## Task 4 — Ingress vs Ingress Controller

Ingress is just the API object — declarative routing rules, does nothing on its own. The Ingress Controller (`ingress-nginx` here) is the actual proxy that watches for Ingress objects and does the routing. Kubernetes ships no built-in controller, unlike Services which work out of the box via kube-proxy — you have to install one. Both are required: an Ingress with no controller sits unenforced, a controller with no Ingress objects has nothing to route. `CLASS nginx` in the `kubectl get ingress` output above is what links the two (`ingressClassName: nginx` in the YAML). Cloud clusters often use a cloud-specific controller instead (AWS Load Balancer Controller, GKE Ingress-GCE) that provisions a real load balancer per Ingress.

## Task 5 — Troubleshooting

Reproduced a documented real incident: a Secret rejected with `password authentication failed`, developer swore the password was right.

```
$ echo "mypassword" | base64 | base64 -d | xxd | tail -2
00000000: 6d79 7061 7373 776f 7264 0a              mypassword.
```

Plain `echo` appends a trailing newline before piping into `base64`, so the decoded secret was `mypassword\n` (11 bytes), not `mypassword` (10). The app got exactly what was in the Secret — the Secret itself was wrong.

```
$ echo -n "mypassword" | base64 | base64 -d | xxd | tail -2
00000000: 6d79 7061 7373 776f 7264                 mypassword
```

`echo -n` fixes it — 10 bytes, and the `==` padding changes too (`bXlwYXNzd29yZA==` vs `bXlwYXNzd29yZAo=`), a quick visual tell for this bug in review. Full output: [troubleshooting/output.txt](troubleshooting/output.txt)
