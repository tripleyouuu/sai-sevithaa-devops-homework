# Session 6-7: Docker Hello World Applications

Six minimal "Hello World" web apps, each in its own folder with its own
`Dockerfile`, built and run via Docker (Colima as the engine on this Mac).

| App | Folder | Port | Image base |
|---|---|---|---|
| Node.js (Express) | `nodejs-app/` | 3000 | `node:24-alpine` |
| Python (Flask) | `python-app/` | 5050→5000 | `python:3.11-slim` |
| Java (plain `HttpServer`) | `java-app/` | 8000 | `eclipse-temurin` (multi-stage) |
| Apache | `Apache-app/` | 8081→80 | `httpd:latest` |
| React (Vite) | `React-app/` | 8082→80 | `node:24-alpine` build → `nginx:latest` serve |
| Nginx | `nginx-app/` | 8083→80 | `nginx:latest` |

Python's host port is remapped to 5050 because macOS reserves port 5000 for
its own AirPlay Receiver service, which intercepted the request before it
reached Docker's port mapping.

## Build + run

```bash
docker build -t nodejs-app ./nodejs-app
docker build -t python-app ./python-app
docker build -t java-app ./java-app
docker build -t apache-app ./Apache-app
docker build -t react-app ./React-app
docker build -t nginx-app ./nginx-app

docker run -d --name nodejs-app -p 3000:3000 nodejs-app
docker run -d --name python-app -p 5050:5000 python-app
docker run -d --name java-app -p 8000:8000 java-app
docker run -d --name apache-app -p 8081:80 apache-app
docker run -d --name react-app -p 8082:80 react-app
docker run -d --name nginx-app -p 8083:80 nginx-app
```

## `docker ps` output

```
$ docker ps
CONTAINER ID   IMAGE        COMMAND                  CREATED              STATUS              PORTS                                         NAMES
5881a9809530   python-app   "python app.py"          About a minute ago   Up About a minute   0.0.0.0:5050->5000/tcp, [::]:5050->5000/tcp   python-app
5d05e9e6cb36   nginx-app    "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:8083->80/tcp, [::]:8083->80/tcp       nginx-app
18077d56ddcd   react-app    "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:8082->80/tcp, [::]:8082->80/tcp       react-app
1acadbd0d466   apache-app   "httpd-foreground"       About a minute ago   Up About a minute   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp       apache-app
315de7d0a288   java-app     "/__cacert_entrypoin…"   About a minute ago   Up About a minute   0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp   java-app
40c4110ebe9a   nodejs-app   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp   nodejs-app
```

## Verification screenshots

Each app's own folder has a `screenshot.png` of the live page.

- [nodejs-app/screenshot.png](nodejs-app/screenshot.png)
- [python-app/screenshot.png](python-app/screenshot.png)
- [java-app/screenshot.png](java-app/screenshot.png)
- [Apache-app/screenshot.png](Apache-app/screenshot.png)
- [React-app/screenshot.png](React-app/screenshot.png)
- [nginx-app/screenshot.png](nginx-app/screenshot.png)
