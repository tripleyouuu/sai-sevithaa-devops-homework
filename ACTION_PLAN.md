# DevOps Homework — Action Plan

Source: `DevOps Homework.pdf`. Session 21 (final project) is intentionally excluded per instructions.

**Update:** the course's own source-material repo (`devops-heros`, cloned locally to `/Users/vitha/Desktop/devops-heros`) is now available and confirms the session numbering definitively: Session 1 = DevOps Engineer Roadmap (orientation, no homework), Session 2 = Linux, Session 3 = Shell Scripting, Session 4 = Networking, Session 5 = Git/GitHub, Sessions 6–7 = Docker, Session 8 = Docker Networking & Volumes, Session 9 = Kubernetes fundamentals, Session 10 = K8s core objects, Sessions 11–20 as already mapped. The earlier "combine 1+2" folder has been split back into `session-01-devops-roadmap` and `session-02-linux` to match. From here on, each session's folder in this repo is built using the real source material in `devops-heros/sessionN-...` as ground truth rather than generic equivalents.

## Tooling status

Installed via Homebrew: Colima, Docker CLI + Compose, kubectl, Minikube, Helm, Terraform (via `hashicorp/tap`), AWS CLI, Node.js, Maven, gh CLI, poppler. Colima still needs to be started (`colima start`) before any `docker`/`minikube` command will work — done per-session as needed.

## Phase 0: Tooling prerequisites (blocking)

This Mac currently has **none** of the following installed: Docker, Minikube, kubectl, Helm, Terraform, AWS CLI, Homebrew, Node.js, Maven, `gh` CLI. Only `git`, `python3`, and `java` are present.

Before any session past Session 5 (Git) can actually be executed and verified, we need:

| Tool | Needed for | Install method |
|---|---|---|
| Homebrew | installing everything below | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| Docker Desktop (or Colima) | Sessions 6–8, 16–17, 21 | `brew install --cask docker` (Desktop, needs GUI launch once) or `brew install colima docker` (CLI-only, no GUI) |
| Minikube | Sessions 9–15, 20 | `brew install minikube` |
| kubectl | Sessions 9–15, 20 | `brew install kubectl` |
| Helm | Session 15 | `brew install helm` |
| Terraform | Sessions 18–19 | `brew install terraform` |
| AWS CLI | Sessions 18–19 | `brew install awscli` + `aws configure` (your own AWS credentials — I will never enter these for you) |
| gh CLI | Session 16–17 (optional, for PR/Actions viewing) | `brew install gh` |
| Node.js | Session 6 (nodejs-app) | `brew install node` |
| Maven/JDK | Session 6 (java-app) | `brew install maven` (java already present) |

**I can run the Homebrew + CLI-tool installs myself** since they're reversible package installs, but Docker Desktop requires a one-time manual GUI launch/login (I can't click through a macOS GUI app's first-run flow), and AWS costs real money and needs your own credentials, so those two steps need you. I'll flag each as I reach it rather than blocking on all of them now.

## Screenshot strategy

- Where a command's **text output** is the evidence (kubectl get, docker ps, terraform plan, etc.), I'll capture it as a fenced code block in the README — that satisfies "output screenshots" without a literal image and is more reviewable in Git diffs.
- Where a **browser/GUI view** is the actual deliverable (a webpage showing "Hello World", a dashboard), I'll use the built-in browser tool to open it and capture a real screenshot image, saved into the session folder and embedded in the README.
- Anything neither of those can reach (e.g. AWS Console UI, since I won't hold your AWS login; a physical interview-prep moment) gets flagged explicitly with manual capture instructions.

---

## session-01-02-linux — Linux Fundamentals (Sessions 1–2, combined)

Runs inside a Docker Ubuntu container (`docker run -it ubuntu bash`) since this machine is macOS and tasks need real Linux (`adduser`, `journalctl` don't exist on macOS). Depends on Docker being installed (Phase 0).

Deliverables: `README.md` with commands + output for all 4 tasks.

1. **Soft link vs hard link**
   - `touch original.txt`
   - `ln -s original.txt softlink.txt` — create soft link
   - `ln original.txt hardlink.txt` — create hard link
   - `ls -li original.txt softlink.txt hardlink.txt` — compare inode numbers
   - `rm original.txt` then `cat softlink.txt` (broken) vs `cat hardlink.txt` (still works) — demonstrate the difference
   - `rm softlink.txt hardlink.txt` — cleanup
   - README section: written explanation framed as an interview answer
2. **adduser vs useradd**
   - `man adduser`, `man useradd` — read docs
   - `useradd -m testuser1` then inspect `/etc/passwd`, `/home`
   - `adduser testuser2` (interactive, prompts for password/info) — note this is the Debian/Ubuntu-recommended one
   - README: explain adduser is a friendlier Perl wrapper around useradd, preferred on Ubuntu
3. **journalctl**
   - `journalctl --no-pager | head -50`
   - `journalctl -u ssh` (or another installed service) — service-specific logs
   - `journalctl --since "1 hour ago"`
   - `journalctl -p err` — errors only
4. **Linux command cheat sheet**
   - Practice core commands: `ls, cd, pwd, cp, mv, rm, mkdir, chmod, chown, grep, find, df, du, ps, top, kill, tar, curl, wget, ssh, scp`
   - README: one-line purpose + one example per command

---

## session-03-shell-scripting — System Information Script

Deliverable: a `.sh` script + `README.md` with command outputs. Runs fine natively on macOS zsh/bash (no Docker needed), though commands produce BSD-flavored output here vs GNU on real Ubuntu — note that in the README since the course is Ubuntu-based.

Script (`sysinfo.sh`) must:
- Print current date (`date`)
- Print hostname (`hostname`)
- Print username (`whoami`)
- Print disk usage (`df -h`)
- Print running processes (`ps aux`)
- Use variables to store/reuse values
- Take input via `read -p`
- Create a directory via `mkdir`
- Create a file via `touch`
- Redirect `ps` output into that file via `>`

Submission: public GitHub repo (already set up), script pushed, `README.md` with every command's output pasted in.

---

## session-04-networking — Networking Commands

Deliverable: an `.md` file with command output/screenshots + short explanations per command.

1. Practice commands/repo from the shared `devops-hero` GitHub repo (need the actual repo URL/name from you — I don't have it yet).
2. Run and document (macOS equivalents noted where they differ from Ubuntu):
   - `ping -c 4 google.com`
   - `traceroute google.com`
   - `netstat -tulnp` (macOS: `netstat -an` / `lsof -i -P`)
   - `ip addr` (macOS: `ifconfig`)
   - `nslookup google.com`
   - `dig google.com`
   - `curl -I https://google.com`
   - `ss -tulnp` (macOS: no direct equivalent, use `lsof -i`)
   - `whois google.com`
3. One short paragraph per command: what it showed and what you understood.

**Needs from you:** the `devops-hero` repo URL to pull Task 1's specific command list.

---

## session-05-git — git commit -a -m & Cherry-Pick

Deliverable: screenshots or `.md` file with commands/output, in the repo.

**Task 1 — commit -a -m vs commit -m**
- Make a tracked file, modify it, `git commit -m "msg"` (fails/doesn't include unstaged changes)
- Modify again, `git commit -a -m "msg"` (auto-stages tracked file changes and commits)
- Document the difference: `-a` auto-stages modified/deleted tracked files; `-m` alone only commits what's already staged.

**Task 2 — Cherry-pick**
- On `main`: 2–4 commits, `git log --oneline`
- `git checkout -b feature-branch`
- 2–3 commits on `feature-branch`, `git log --oneline`
- `git checkout main`
- `git cherry-pick <commit-sha>` — pick one specific commit from feature-branch
- `git log --oneline` on main to verify the change landed

---

## session-06-docker-helloworld — Docker Hello World x6

Needs Docker installed and running (Phase 0). Each subfolder already created: `nodejs-app`, `python-app`, `java-app`, `Apache-app`, `React-app`, `nginx-app`.

For **each** app: write minimal source + `Dockerfile`, `docker build`, `docker run`, verify "Hello World" in a browser, screenshot via the built-in browser tool.

- **nodejs-app**: minimal Express "Hello World" server, `Dockerfile` using `node:alpine`, `EXPOSE 3000`
- **python-app**: minimal Flask "Hello World" app, `Dockerfile` using `python:slim`, `EXPOSE 5000`
- **java-app**: minimal Spring Boot or plain servlet "Hello World", `Dockerfile` using `maven` build stage + `eclipse-temurin` runtime, `EXPOSE 8080`
- **Apache-app**: static `index.html` "Hello World", `Dockerfile FROM httpd`, `EXPOSE 80`
- **React-app**: `create-react-app`-style minimal app (or a trimmed static build) showing "Hello World", `Dockerfile` multi-stage (`node` build → `nginx` serve)
- **nginx-app**: static `index.html` "Hello World", `Dockerfile FROM nginx`, `EXPOSE 80`

Each: `docker build -t <name> .`, `docker run -d -p <port>:<port> <name>`, verify with browser screenshot, `docker ps` output, then stop/remove container.

Deliverable: push all 6 folders with code + Dockerfiles; root `README.md` summarizing each app + its screenshot.

---

## session-07-docker-multistage — Multi-Stage Build

1. Clone the repo with the multi-stage Dockerfile (**needs the repo URL from you**).
2. `docker build -t multistage-app .`
3. `docker run -d -p 8080:8080 multistage-app`
4. Browser screenshot confirming: "Hello World from Docker multi-stage build"
5. `docker ps` output showing the container on port 8080
6. `README.md`: your name, enrollment number, the two screenshots/outputs above
7. **Task 3**: deploy 3 more different app types via Docker (Node.js, Python, Java) — can reuse/adapt the session-06 apps, documented separately here per the PDF's instructions

**Needs from you:** the multi-stage Dockerfile repo URL, and your enrollment number for the README.

---

## session-08-docker-networking-volume — Networking & Volumes

1. **Container networking**: 3 containers — frontend (nginx/alpine), backend (nginx/alpine), database (mysql) — `docker network create` x3, `docker network connect` to add backend to 2 networks, `docker exec ... ping` to verify connectivity between containers.
2. **Host network**: `docker pull httpd`, `docker run --network host httpd`, verify at `http://localhost:80` (browser screenshot).
3. **Bind mount**: local folder + `index.html` containing "Hello students", `docker run -v $(pwd)/html:/usr/share/nginx/html nginx`, browser screenshot, then edit `index.html` locally and re-screenshot without restarting the container to prove live reflection.
4. **Overlay network**: research-only — document use cases and cross-host behavior in `README.md` (no hands-on needed, Swarm/multi-host is out of scope for a single Docker Desktop install).

Deliverable: `README.md` with all screenshots + explanations.

---

## session-09-kubernetes-fundamentals — Minikube & K8s Basics

Needs Minikube + kubectl (Phase 0).

1. `minikube start`
2. `minikube status`
3. `kubectl cluster-info`
4. `kubectl get nodes`
5. `kubectl config view`
6. Explore architecture: control plane components (API server, etcd, scheduler, controller-manager) vs node components (kubelet, kube-proxy, container runtime) — written notes
7. Basic objects/commands: `kubectl get pods/svc/deployments`, `kubectl create`, `kubectl apply`, `kubectl delete`
8. Hands-on the official Kubernetes Basics tutorial (create/expose/scale/update a sample deployment)

Deliverable: `README.md` with commands used, output screenshots, short architecture notes.

---

## session-10-kubernetes-pods-deployments — Deployment Strategies + Pod Lifecycle

**Task 1 — all 4 deployment strategies**, each with its own YAML + README section:
1. **Rolling Update**: Deployment with `strategy: RollingUpdate`, `kubectl apply`, change image, `kubectl rollout status`, `kubectl get pods` showing mixed old/new during rollout.
2. **Blue-Green**: two Deployments (`app-blue`, `app-green`), one Service, switch the Service's `selector` to flip traffic, verify active version via `curl`/`kubectl get endpoints`.
3. **Canary**: stable Deployment (majority replicas) + canary Deployment (few replicas) behind one Service/label selector, verify traffic split by repeated requests.
4. **Recreate**: Deployment with `strategy: Recreate`, update image, observe all old pods terminate before new ones start (`kubectl get pods -w`).

**Task 2 — Pod lifecycle**: for each lifecycle YAML (init containers, probes, terminationGracePeriod examples) — `kubectl apply -f`, `kubectl get pods`, `kubectl describe pod`, capture output, explain observed phases (Pending → ContainerCreating → Running → Succeeded/Failed/CrashLoopBackOff) in README.

Deliverable: all YAMLs, commands, outputs, screenshots, `README.md`.

---

## session-11-kubernetes-networking-services — Services, Object Comparison, FQDN, CoreDNS

**Task 1 — all 5 Service types**, each with YAML + deploy + verify + screenshot:
1. ClusterIP (default internal-only)
2. NodePort (`minikube service <svc> --url` to access)
3. LoadBalancer (`minikube tunnel` needed to get external IP)
4. ExternalName (points to an external DNS name, e.g. `example.com`)
5. Headless (`clusterIP: None`, verify via `nslookup` returning pod IPs directly)

**Task 2 — README.md** comparing:
- Deployment vs ReplicaSet (purpose, pod management, scaling, rolling updates, their relationship)
- Deployment vs DaemonSet vs StatefulSet (use cases, pod creation, scaling, networking, storage, examples)
- ReplicaSet vs Service (responsibilities, why a Service is needed, how traffic reaches pods)

**Task 3 — `fqdn/README.md`**: what FQDN is, K8s Service DNS, naming convention (`<svc>.<namespace>.svc.cluster.local`), namespace-based DNS, pod-to-service communication, examples.

**Task 4 — `coredns/README.md`**: what CoreDNS is, why K8s uses it, service discovery mechanics, DNS query resolution, CoreDNS config (`kubectl -n kube-system get configmap coredns -o yaml`), troubleshooting DNS issues (`kubectl exec -it <pod> -- nslookup <svc>`).

---

## session-12-kubernetes-ingress-configmaps-secrets

**Task 1 — ConfigMap**: `kubectl create configmap`, mount into a pod (env or volume), `kubectl exec` to verify values inside the container.

**Task 2 — Secret**: `kubectl create secret generic`, inject into a pod, `kubectl exec` to verify (base64-decoded) value, README note on why secrets shouldn't be committed to Git (use `.gitignore` the raw secret manifest, or sealed-secrets/external-secrets in real setups).

**Task 3 — Ingress**: deploy an app + Service + Ingress resource (needs an ingress controller — `minikube addons enable ingress`), access via the Ingress host, verify routing.

**Task 4 — `README.md`**: Ingress vs Ingress Controller — definitions, difference, why both are required, examples.

**Task 5 — Troubleshooting**: needs the course's "troubleshooting folder" content (**needs the repo/material from you**) — identify problem, run diagnostic commands, root-cause, fix, before/after screenshots.

Deliverable: ConfigMap/Secret/Ingress YAMLs, troubleshooting docs, screenshots, `README.md`.

---

## session-13-kubernetes-storage-hpa-probes

**Task 1 — `01-kubernetes-volumes/README.md`**: document + practical examples of `emptyDir`, `hostPath`, PersistentVolume, PersistentVolumeClaim, StorageClass, dynamic provisioning.

**Task 2 — HPA hands-on** (needs `hpa.yml` — **needs the file/repo from you**, or I draft an equivalent):
- `kubectl apply -f hpa.yml`, deploy app
- `kubectl get hpa`, `kubectl describe hpa`
- needs `metrics-server` (`minikube addons enable metrics-server`) for `kubectl top pods` to work
- Deploy a load generator (e.g. a busybox `while true; do wget -q -O- app; done` pod)
- Watch `kubectl get hpa -w` and `kubectl get pods -w` as it scales

**Task 3 — Mini project**: needs the specific Session 13 mini-project brief (**needs the material from you**).

---

## session-14-kubernetes-troubleshooting

**Task 1 — commands practice**: `kubectl get`, `describe`, `logs`, `exec`, `get events`, `explain`, `top`, `get -o wide` — run each against real objects, capture output.

**Task 2 — troubleshoot common issues** (I'll intentionally break pods to reproduce each, fix, and document before/after):
- CrashLoopBackOff (bad command/exit code)
- ImagePullBackOff / ErrImagePull (bad image name/tag)
- Pending (resource requests too high / no matching node)
- ContainerCreating stuck (bad volume/configmap mount)
- Service connectivity issues (wrong selector/port)
- DNS issues (wrong service name)
- Pod networking issues (NetworkPolicy blocking traffic)
- Configuration issues (bad env var / missing ConfigMap key)

**Task 3 — mini project**: needs the Session 14 mini-project brief (**needs the material from you**).

Deliverable per issue: problem statement, investigation steps, root cause, fix, before/after output, screenshots, `README.md`.

---

## session-15-helm

Needs Helm (Phase 0).

**Task 1 — commands**, each executed, explained, output captured:
`helm create`, `helm install`, `helm list`, `helm status`, `helm get`, `helm upgrade`, `helm history`, `helm rollback`, `helm uninstall`, `helm repo add/update`, `helm search repo/hub`.

**Task 2 — rollback workflow**: `helm install` → `helm upgrade` (change a value) → verify → `helm upgrade` again (change again) → verify → `helm rollback <release> <revision>` → verify. Document each step's output.

**Task 3 — mini project**: needs the Session 15 mini-project brief (**needs the material from you**).

Deliverable: a Helm chart, `values.yaml`, templates, command outputs, screenshots, README files.

---

## session-16-cicd-github-actions — CI/CD Demo Project

References `10-final-cicd-pipeline` from the course (**needs the material/repo from you** to match it exactly; otherwise I'll build an equivalent from scratch).

Build: a small app + Dockerfile + `.github/workflows/ci-cd.yml` covering:
- CI vs CD (explain in README)
- Workflow triggers (`on: push/pull_request`)
- Jobs, steps, runners (`ubuntu-latest`)
- Secrets (`secrets.GITHUB_TOKEN` or a registry token via repo Settings → Secrets — **needs you to add any registry credentials**, I won't set secrets on your GitHub account without asking)
- Artifacts (`actions/upload-artifact`)
- Build + test steps
- Pipeline execution screenshot (GitHub Actions run page — needs `gh` CLI or browser)

Deliverable: app source, Dockerfile, workflow file, screenshots of a green pipeline run, `README.md`.

**Note:** pushing a workflow and triggering a run means pushing to GitHub — I'll confirm with you before the first push/PR per the explicit-permission rules.

---

## session-17-cicd-devsecops — CI/CD + DevSecOps Pipeline

Extends session-16's pipeline with a security stage:

Flow: Code → Build → Unit Test → SAST → SCA → Secret Scan → Docker Build → Container Image Scan → Security Gate → Push Image → Deploy to Kubernetes

Tooling (free/open-source, GitHub Actions-friendly):
- SAST: `github/codeql-action` or Semgrep Action
- SCA: `npm audit`/`pip-audit` or Trivy filesystem scan, or GitHub's Dependabot
- Secret scanning: Gitleaks Action
- Container image scanning: Trivy or Grype Action
- Security gate: fail the job on high/critical findings
- Deploy: `kubectl apply` step against Minikube is not reachable from a GitHub-hosted runner — document this as a known limitation and either (a) use a self-hosted runner pointed at local Minikube, or (b) treat the "deploy" step as a dry-run/manifest-validation step and note the real deploy happens locally. I'll flag this choice to you before building it.

Deliverable: app, Dockerfile, workflow, security tool configs, K8s manifests, pipeline screenshots, `README.md`.

---

## session-18-terraform-iac — Terraform + AWS Services Research

Needs Terraform + AWS CLI + **your own AWS credentials** (Phase 0). `terraform apply` creates a real S3 bucket — costs are negligible (S3 storage for an empty bucket is effectively free) but it's still a real-account change, so **I will stop and confirm with you before running `terraform apply`**, and run `terraform destroy` right after verification unless you want it kept.

**Task 1 — `terraform-s3-demo/`**: `main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`, `terraform.tfvars`, `README.md`. Resource: one `aws_s3_bucket`. Commands, each output captured in README:
`terraform init` → `terraform fmt` → `terraform validate` → `terraform plan` → `terraform apply` → `terraform show` → `terraform output` → `terraform destroy`.

**Task 2 — `aws-services/` research** (no AWS account needed, pure documentation), one `README.md` each:
- `01-iam`: IAM concept, Users, Groups, Roles, Policies, Permissions, least privilege, best practices, use cases
- `02-ec2`: EC2, AMI, instance types, key pairs, Security Groups, EBS, public vs private IP, instance lifecycle, use cases
- `03-s3`: S3, buckets, objects, storage classes, versioning, lifecycle policies, encryption, bucket policies, use cases
- `04-vpc`: VPC, CIDR, subnets, route tables, Internet Gateway, NAT Gateway, Security Groups, Network ACLs, public vs private subnet
- `05-dynamodb-rds`: DynamoDB (NoSQL, tables, items, attributes, partition/sort key, use cases) + RDS (engines, DB instances, security, backups, Multi-AZ, read replicas, use cases)

**Needs from you:** AWS credentials configured via `aws configure` (I will never type or view your actual keys — you run that command yourself), and explicit go-ahead before any `terraform apply`.

---

## session-19-cloud-terraform — End-to-End AWS Infra

Same AWS/Terraform prerequisites and confirm-before-apply rule as session-18. This one provisions more (VPC, Subnet, Security Group, EC2, S3) — a running EC2 instance has an hourly cost, so this needs your explicit sign-off on instance type (e.g. `t2.micro`, free-tier eligible) before `apply`, and should be destroyed promptly after verification/screenshots.

Build Terraform demonstrating: providers, variables, resources, outputs, dependencies (`depends_on` / implicit refs), AWS infra (VPC → Subnet → Security Group → EC2 → S3), Terraform state, `terraform plan`, `terraform apply`, `terraform destroy`.

Deliverable: Terraform project, architecture diagram (I'll generate this as an SVG/diagram, not a live AWS screenshot), command screenshots, `README.md`.

---

## session-20-monitoring-observability-gitops

**Task 1 — Monitoring**: deploy Prometheus + Grafana on Minikube (`helm install` from the `prometheus-community` chart repo, or `minikube addons enable metrics-server` for a lighter version), demonstrate metrics, logs (`kubectl logs`), alerts (a basic Prometheus alert rule), CPU/memory utilization (`kubectl top`), application health (readiness/liveness probe status).

**Task 2 — Observability**: `README.md` on the three pillars (Metrics, Logs, Traces) — what each means, why observability matters, common tools (Prometheus, Grafana, Loki, Jaeger/Tempo), Kubernetes observability specifics.

**Task 3 — GitOps**: `README.md` covering what GitOps is, Git as source of truth, declarative config, continuous reconciliation, GitOps workflow, Kubernetes + GitOps. Hands-on demo via Argo CD (`helm install argocd`) syncing this repo's K8s manifests to the Minikube cluster, if time/scope allows — otherwise documented conceptually with a note on what a live demo would require.

Deliverable: monitoring demo, observability docs, GitOps demo, screenshots, `README.md`.

---

## Open items I need from you before I can execute fully

1. The `devops-hero` GitHub repo URL (session-04).
2. The multi-stage Dockerfile repo URL (session-07), plus your enrollment number for that README.
3. The Session 12 "troubleshooting folder" material.
4. The `hpa.yml` file / Session 13 mini-project brief.
5. The Session 14 mini-project brief.
6. The Session 15 mini-project brief.
7. The `10-final-cicd-pipeline` reference material (session-16), if you want mine to match it exactly rather than an equivalent I design.
8. AWS credentials configured locally (sessions 18–19) — run `aws configure` yourself; I'll never handle the raw keys.
9. Confirmation before I run any `terraform apply` (creates real, billable AWS resources) or push/open a PR to GitHub Actions.
10. Confirmation on Docker install approach: Docker Desktop (GUI, needs your one-time login) vs Colima (CLI-only, I can fully automate).

Everything else I can proceed with directly.
