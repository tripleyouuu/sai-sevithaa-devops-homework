# Session 7 — Docker Multi-Stage Build

**Name:** Vitha
**Enrollment number:** 24bcs10145

## Task 1 & 2: Multi-stage Dockerfile

`Dockerfile` has two stages: `builder` installs full dependencies and copies
source, `production` reinstalls only non-dev dependencies and copies just
`server.js` from the builder stage — the pattern that keeps a multi-stage
image from carrying build-only artifacts into the runtime image.

```bash
docker build -t multistage-app .
docker run -d --name multistage-app -p 8080:8080 multistage-app
```

Verified the app responds with the expected text, on port 8080:

```
$ curl http://localhost:8080/
<h1>Hello World from Docker multi-stage build</h1>
```

Screenshot: [screenshot.png](screenshot.png)

`docker ps` confirming the container on port 8080:

```
$ docker ps --filter "name=multistage-app"
CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS         PORTS                                         NAMES
03b5d2e42566   multistage-app   "docker-entrypoint.s…"   2 seconds ago   Up 2 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp   multistage-app
```

## Task 3: Deploy 3 more application types

Reused the Node.js, Python, and Java images from Session 6 and ran them
alongside the multi-stage app to have 4 different app types live at once:

```
$ docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS          PORTS                                         NAMES
a21b8c5cf2ae   java-app         "/__cacert_entrypoin…"   7 seconds ago    Up 7 seconds    0.0.0.0:8001->8000/tcp, [::]:8001->8000/tcp   task3-java
b88b881b5893   python-app       "python app.py"          7 seconds ago    Up 7 seconds    0.0.0.0:5051->5000/tcp, [::]:5051->5000/tcp   task3-python
bd65c29bc4f6   nodejs-app       "docker-entrypoint.s…"   7 seconds ago    Up 7 seconds    0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp   task3-nodejs
03b5d2e42566   multistage-app   "docker-entrypoint.s…"   25 seconds ago  Up 24 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp   multistage-app
```

Full output: [task3_docker_ps_output.txt](task3_docker_ps_output.txt)
