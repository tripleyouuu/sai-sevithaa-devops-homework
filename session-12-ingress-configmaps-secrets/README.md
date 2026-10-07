# Session 12: Kubernetes Ingress, ConfigMaps & Secrets

## Task 1 & 2: ConfigMap and Secret

Deployed `yatri-app-config` (ConfigMap) and `yatri-db-secret` (Secret)
together via `envFrom`/`secretKeyRef` into a backend pod, then verified
the decoded values live inside the running container:

```
$ kubectl exec deploy/yatri-backend -- env | grep -E 'ENVIRONMENT|LOG_LEVEL|POSTGRES'
POSTGRES_DB=yatri_production_db
POSTGRES_PASSWORD=secretpassword
POSTGRES_USER=yatri_admin
ENVIRONMENT=production
LOG_LEVEL=INFO
```

`kubectl get secret yatri-db-secret -o yaml` shows only the **base64-encoded**
form (`POSTGRES_PASSWORD: c2VjcmV0cGFzc3dvcmQ=`) — base64 is an encoding,
not encryption, so this is not actually secure storage; it just avoids
putting raw binary/credentials straight in plaintext YAML. Full output:
[`task1_2_output.txt`](task1_2_output.txt)

**Why Secrets shouldn't be committed to Git:** base64 is trivially
reversible (`echo <value> | base64 -d`), so a Secret manifest in a Git repo
is functionally equivalent to committing the plaintext credential — anyone
with repo access (or anyone who finds it in history, even after a later
"delete") has it. Real practice: keep Secret manifests out of version
control (`.gitignore` them), generate them at deploy time from a vault
(e.g. `kubectl create secret` in CI from a secrets manager), or use
tools like Sealed Secrets / External Secrets Operator that let you commit
an *encrypted* representation safely.

## Task 3: Ingress (`04-full-demo/`)

Deployed a frontend (nginx) + backend (Python, reads the ConfigMap/Secret)
behind one Ingress resource doing path-based routing: `/` → frontend,
`/api/*` → backend (with `rewrite-target` stripping the `/api` prefix).

```
$ minikube addons enable ingress
* The 'ingress' addon is enabled

$ kubectl apply -f configmap.yaml -f secret.yaml -f backend.yaml -f frontend.yaml -f ingress.yaml
$ kubectl get ingress yatri-ingress
NAME            CLASS   HOSTS         ADDRESS   PORTS   AGE
yatri-ingress   nginx   yatri.local             80      17s
```

Accessed through the ingress controller (port-forwarded, since NodePort/
LoadBalancer IPs aren't directly reachable from macOS through Colima — same
limitation as session 11) using the `Host: yatri.local` header to simulate
real DNS-based virtual hosting:

```
$ curl -s -H 'Host: yatri.local' http://localhost:8100/
...nginx welcome page (frontend)...

$ curl -s -H 'Host: yatri.local' http://localhost:8100/api/
Yatri Backend API
=================
ENVIRONMENT     : production
LOG_LEVEL       : INFO
DEFAULT_CURRENCY: INR
POSTGRES_USER   : yatri_admin
POSTGRES_DB     : yatri_production_db
```

Confirms both routing rules work correctly *and* re-verifies the
ConfigMap/Secret injection end to end through a real HTTP response, not
just `env`. Screenshots (via browser with `yatri.local` resolved to
localhost): [`04-full-demo/screenshot_frontend.png`](04-full-demo/screenshot_frontend.png),
[`04-full-demo/screenshot_api.png`](04-full-demo/screenshot_api.png).
Full output: [`04-full-demo/task3_output.txt`](04-full-demo/task3_output.txt)

## Task 4: Ingress vs Ingress Controller

- **Ingress** is just a Kubernetes API object (`kind: Ingress`) — a
  declarative set of HTTP routing rules (host/path → backend Service). On
  its own it does nothing; it's inert configuration.
- **Ingress Controller** is the actual piece of software (here,
  `ingress-nginx`, running as a Deployment in the `ingress-nginx`
  namespace) that watches the API for Ingress objects and does the real
  work: runs an HTTP(S) reverse proxy, reads the Ingress rules, and
  programs itself to route traffic accordingly.
- **Difference**: Ingress = the *what* (routing intent); Ingress Controller
  = the *how* (the proxy that implements it). There's no single built-in
  Ingress Controller in Kubernetes — you must install one (nginx, Traefik,
  AWS ALB Controller, etc.), unlike Services which work out of the box via
  kube-proxy.
- **Why both are required**: an Ingress object with no controller watching
  it simply sits there unenforced — `kubectl get ingress` would show no
  `ADDRESS` and nothing would route. Conversely a controller with no
  Ingress objects has nothing to route. This session's own
  `kubectl get ingress yatri-ingress` output above shows the controller
  recognizing and serving the rule (`CLASS nginx` matching
  `ingressClassName: nginx` in the YAML is what links the two).
- **Example**: `ingress-nginx` (what's used here) is the most common
  general-purpose controller; cloud-managed clusters often use a
  cloud-specific one instead (AWS Load Balancer Controller, GKE's native
  Ingress-GCE) that provisions a real cloud load balancer per Ingress.

## Task 5: Troubleshooting

Reproduced the course's documented real incident
(`troubleshooting/secret-base64-gotcha.md`): a Secret rejected by the
database with `password authentication failed`, despite the developer
swearing the password was correct.

```
$ echo "mypassword" | base64 | base64 -d | xxd | tail -2
00000000: 6d79 7061 7373 776f 7264 0a              mypassword.
```

**Root cause:** plain `echo` appends a trailing newline (`0a`) before
piping into `base64`, so the decoded secret is `mypassword\n` (11 bytes),
not `mypassword` (10 bytes) — the app passed exactly what was in the
Secret, the Secret itself was wrong.

```
$ echo -n "mypassword" | base64 | base64 -d | xxd | tail -2
00000000: 6d79 7061 7373 776f 7264                 mypassword
```

**Fix:** `echo -n` suppresses the newline — confirmed by the byte count
dropping to exactly 10 and the `==` padding changing (`bXlwYXNzd29yZA==`
vs `bXlwYXNzd29yZAo=`), a quick visual tell for this exact bug in review.
Full output: [`troubleshooting/output.txt`](troubleshooting/output.txt)
