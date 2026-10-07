# Session 16: CI/CD & GitHub Actions

Project: `final-cicd-pipeline/` — a small Python calculator app with a full
GitHub Actions pipeline covering every concept from the task list.

## CI vs CD

- **CI (Continuous Integration)**: every push/PR automatically runs the
  test suite and builds the app, catching breakage *before* it merges —
  the `test`, `build`, and `security-check` jobs here.
- **CD (Continuous Delivery)**: once CI passes, automatically package and
  publish a deployable artifact — the `docker-build-push` job, which builds
  the Docker image and pushes it to GitHub Container Registry (GHCR).

## Pipeline (`.github/workflows/ci.yml`)

```
push/PR to main
      │
      ▼
   test ──────────┬──────────────┐
      │            │              │
      ▼            ▼              ▼
   build    security-check   (both need test)
      │            │
      └─────┬──────┘
            ▼
   docker-build-push (needs both build + security-check)
```

- **Workflow**: the whole file — triggers on `push`/`pull_request` to
  `main`, plus `workflow_dispatch` for manual runs.
- **Jobs**: `test`, `build`, `security-check`, `docker-build-push` — four
  independent units of work, each on its own fresh runner.
- **Steps**: each job is a sequence of steps (checkout → setup → run).
- **Runners**: every job specifies `runs-on: ubuntu-latest` — a
  GitHub-hosted VM, torn down after the job finishes.
- **Secrets**: `docker-build-push` logs into GHCR using
  `secrets.GITHUB_TOKEN` — a token GitHub injects automatically per run, no
  manual secret setup needed, scoped to `packages: write` via the
  workflow's `permissions:` block.
- **Artifacts**: `build` uploads `build/` (the compiled output +
  `build-info.txt`) via `actions/upload-artifact`, downloadable from the
  Actions run summary.
- **Build**: `build.sh` copies the app source and stamps a build-info file.
- **Test**: `pytest -v` runs the full test suite.
- **Pipeline execution**: see note below.

## Verified locally before relying on CI

Ran every step by hand first, since this session doesn't push to GitHub
(push is handled separately) and a workflow is only as good as what it
actually runs:

```
$ pytest -v
tests/test_calculator.py::test_add PASSED
tests/test_calculator.py::test_subtract PASSED
tests/test_calculator.py::test_multiply PASSED
tests/test_calculator.py::test_divide PASSED
tests/test_calculator.py::test_divide_by_zero PASSED
============================== 5 passed in 0.01s ===============================

$ ./build.sh
Build completed successfully.
$ ls build/
build-info.txt  calculator.py

$ docker build -t calculator-app:ci-test .
Successfully built ... Successfully tagged calculator-app:ci-test

$ printf "10 + 5\nq\n" | docker run -i --rm calculator-app:ci-test
Enter calculation (e.g., 10 + 5): Result: 15.0
```

All three things the pipeline automates — test, build, Docker image — work
correctly on their own, so the workflow is running real, already-verified
steps rather than hoping they work for the first time in CI.

## Pipeline execution screenshot

**Not captured** — this session doesn't push commits to GitHub (handled
separately per your instruction), and GitHub Actions only runs on a real
push/PR/dispatch against the hosted repo. Once this is pushed:

1. Go to the repo's **Actions** tab → you'll see "Final CI Pipeline" run
   automatically on the push.
2. All 4 jobs should go green (test → build & security-check in parallel →
   docker-build-push).
3. The `calculator-build` artifact and the pushed `ghcr.io/.../calculator-app`
   image will both be visible from that run's summary page.
4. Screenshot that green run and drop it in this folder as
   `pipeline-run-screenshot.png` to complete this deliverable.
