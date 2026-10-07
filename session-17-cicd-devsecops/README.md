# Session 17 — Complete CI/CD & DevSecOps

`demo/` — a small Flask app with a DevSecOps pipeline.

## Pipeline flow

```
Code
  -> test (pytest + coverage)
  -> sast (CodeQL)
  -> secret-scan (Gitleaks)
  -> sca (pip-audit)
       (docker-build needs all 4 — this is the security gate)
  -> docker-build
  -> image-scan (Trivy, HIGH/CRITICAL)
  -> push (Docker Hub)
  -> deploy (kind cluster, kubectl apply, rollout check, curl test)
```

Secret scanning (Gitleaks) wasn't in the source workflow, added it since the task explicitly asks for it. `docker-build` needs `[test, sast, secret-scan, sca]` so an image is only built once every check passes; `push`/`deploy` are gated behind `image-scan` in turn.

## Fixed before relying on it

The source workflow hardcoded another person's real Docker Hub username directly in the YAML. Replaced every occurrence with `${{ secrets.DOCKERHUB_USERNAME }}` so it uses whoever's secrets are configured on the repo it actually runs in, and updated `k8s/deployment.yaml`'s image placeholder to match.

## Verified every stage locally first

```
$ pytest --cov=app --cov-report=term-missing
tests/test_app.py ........                                               [100%]
8 passed in 0.40s
```
[scan-results/pytest_output.txt](scan-results/pytest_output.txt)

```
$ pip-audit
Found 22 known vulnerabilities in 8 packages
pip        21.2.4  PYSEC-2023-228   23.3
setuptools 58.0.4  PYSEC-2022-43012 65.5.1
...
```
Real findings — the local virtualenv's own pip/setuptools were outdated, which pip-audit correctly caught. [scan-results/pip-audit_output.txt](scan-results/pip-audit_output.txt)

```
$ docker build -t session17-python:local-test .
$ trivy image --severity HIGH,CRITICAL session17-python:local-test
session17-python:local-test (debian 13.7)
Total: 44 (HIGH: 44, CRITICAL: 0)
```
44 HIGH CVEs in the base image's OS packages (util-linux, perl-base, ncurses), none in app code. [scan-results/trivy_output.txt](scan-results/trivy_output.txt)

## Still needed

- `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` repo secrets for the `push`/`deploy` jobs — everything else runs without them.
- A live pipeline screenshot, once this is pushed to GitHub.
