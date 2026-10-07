# Session 17: Complete CI/CD & DevSecOps

Project: `demo/` — a small Flask app with a full DevSecOps pipeline
(`.github/workflows/devsecops.yml`) covering every stage the task asks for.

## Pipeline flow (as built)

```
Code
  │
  ├─ test (pytest + coverage)
  ├─ sast (CodeQL)
  ├─ secret-scan (Gitleaks)
  └─ sca (pip-audit)
        │   (docker-build needs all 4 — this is the security gate)
        ▼
  docker-build
        │
        ▼
  image-scan (Trivy, HIGH/CRITICAL)
        │
        ▼
  push (Docker Hub)
        │
        ▼
  deploy (kind cluster, kubectl apply, rollout check, curl test)
```

- **SAST**: `github/codeql-action` — static analysis of the Python source
  for security-relevant bugs.
- **SCA**: `pip-audit` against `requirements.txt`.
- **Secret scanning**: added `gitleaks/gitleaks-action` (the source
  material didn't have a dedicated job for this task requirement).
- **Container image scanning**: `trivy image --severity HIGH,CRITICAL`.
- **Security gates**: `docker-build` has `needs: [test, sast, secret-scan, sca]`
  — the image is only built if every prior security/quality check passes;
  `push`/`deploy` are gated behind `image-scan` in turn, so a vulnerable
  image never reaches a registry or a cluster.

## Fixed before relying on it

The source workflow hardcoded another person's real Docker Hub username
(`nensiravaliya28`) directly in the YAML for both the login step and the
image tags. Replaced every occurrence with `${{ secrets.DOCKERHUB_USERNAME }}`
so the pipeline uses whoever's `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN`
secrets are configured on the repo it runs in, rather than silently pushing
images under someone else's account. Also updated `k8s/deployment.yaml`'s
image reference to the matching `__DOCKERHUB_USERNAME__` placeholder, and
the deploy job now substitutes it alongside the existing `__IMAGE_TAG__`
substitution.

## Verified every stage locally first

```
$ pytest --cov=app --cov-report=term-missing
tests/test_app.py ........                                               [100%]
TOTAL  102  32  69%
============================== 8 passed in 0.40s ===============================
```
Full output: [`scan-results/pytest_output.txt`](scan-results/pytest_output.txt)

```
$ pip-audit
Found 22 known vulnerabilities in 8 packages
Name       Version ID               Fix Versions
pip        21.2.4  PYSEC-2023-228   23.3
setuptools 58.0.4  PYSEC-2022-43012 65.5.1
...
```
Real findings — the local virtualenv's own `pip`/`setuptools`/tooling were
outdated, which `pip-audit` correctly flagged. This is genuinely useful
evidence that the SCA step works: it isn't a clean no-op, it actually
catches real, fixable issues. Full output:
[`scan-results/pip-audit_output.txt`](scan-results/pip-audit_output.txt)

```
$ docker build -t session17-python:local-test .
Successfully built ... Successfully tagged session17-python:local-test

$ trivy image --severity HIGH,CRITICAL session17-python:local-test
session17-python:local-test (debian 13.7)
Total: 44 (HIGH: 44, CRITICAL: 0)
```
44 HIGH-severity CVEs in the `python:3.12-slim` base image's OS packages
(util-linux, perl-base, ncurses — standard Debian base image findings, none
in the application's own code). Full output:
[`scan-results/trivy_output.txt`](scan-results/trivy_output.txt)

## What needs you before the full pipeline can run end to end

- **`DOCKERHUB_USERNAME`** and **`DOCKERHUB_TOKEN`** repo secrets — you'll
  need your own Docker Hub account and an access token for the `push`/
  `deploy` jobs to work. `test`, `sast`, `secret-scan`, `sca`, `docker-build`,
  and `image-scan` all run fine without them.
- A live pipeline screenshot — same as Session 16, this needs an actual
  push to GitHub to trigger, which is handled separately.
