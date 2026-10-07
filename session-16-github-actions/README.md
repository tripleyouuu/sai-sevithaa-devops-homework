# Session 16 — CI/CD & GitHub Actions

`final-cicd-pipeline/` — a small Python calculator app with a GitHub Actions pipeline.

## CI vs CD

CI: every push/PR runs the test suite and builds the app — `test`, `build`, `security-check` jobs. CD: once CI passes, package and publish a deployable artifact — `docker-build-push` builds the Docker image and pushes it to GHCR.

## Pipeline

```
push/PR to main
   -> test
        -> build          -\
        -> security-check  -> docker-build-push
```

- Workflow triggers on `push`/`pull_request` to `main`, plus `workflow_dispatch`
- 4 jobs, each on its own `ubuntu-latest` runner
- `docker-build-push` logs into GHCR with `secrets.GITHUB_TOKEN`, scoped via the workflow's `permissions:` block
- `build` uploads `build/` as an artifact via `actions/upload-artifact`
- `test` runs `pytest -v`

## Verified locally first

```
$ pytest -v
tests/test_calculator.py::test_add PASSED
tests/test_calculator.py::test_subtract PASSED
tests/test_calculator.py::test_multiply PASSED
tests/test_calculator.py::test_divide PASSED
tests/test_calculator.py::test_divide_by_zero PASSED
5 passed in 0.01s

$ ./build.sh
Build completed successfully.

$ docker build -t calculator-app:ci-test .
Successfully built ... Successfully tagged calculator-app:ci-test

$ printf "10 + 5\nq\n" | docker run -i --rm calculator-app:ci-test
Result: 15.0
```

## Pipeline execution screenshot

Not captured — this session doesn't push to GitHub, and Actions only runs on a real push. Once pushed, the Actions tab will show "Final CI Pipeline" go green across all 4 jobs.
