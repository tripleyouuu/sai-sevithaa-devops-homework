# Session 8 — Docker Networking & Volumes

## Task 1 — Container networking

Three containers across three networks, backend joined to two of them.

```
$ docker network create net1
$ docker network create net2
$ docker network create net3

$ docker run -d --name frontend --network net1 nginx:alpine
$ docker run -d --name database --network net2 -e MYSQL_ROOT_PASSWORD=root mysql:8.0
$ docker run -d --name backend --network net1 nginx:alpine
$ docker network connect net2 backend

$ docker network inspect net1 --format '{{range .Containers}}{{.Name}} {{end}}'
frontend backend

$ docker network inspect net2 --format '{{range .Containers}}{{.Name}} {{end}}'
database backend
```

Full output: [task1_setup_output.txt](task1_setup_output.txt)

Backend can reach both neighbors since it's on both networks. Frontend (net1 only) can't resolve database (net2 only):

```
$ docker exec frontend ping -c 2 backend
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.133 ms

$ docker exec backend ping -c 2 database
64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.084 ms

$ docker exec frontend ping -c 2 database
ping: bad address 'database'
```

Full output: [task1_connectivity_output.txt](task1_connectivity_output.txt)

## Task 2 — Host network

```
$ docker pull httpd
$ docker run -d --name apache-host --network host httpd
$ curl http://localhost:80/
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html><head><title>It works! Apache httpd</title></head>...
```

`--network host` skips Docker's own network namespace and binds directly to the host, so no `-p` mapping is needed.

Full output: [task2_host_network_output.txt](task2_host_network_output.txt) · Screenshot: [task2_screenshot.png](task2_screenshot.png)

## Task 3 — Bind mount

```
$ mkdir bindmount-demo
$ echo "Hello students" > bindmount-demo/index.html
$ docker run -d --name bindmount-nginx -p 8090:80 \
    -v $(pwd)/bindmount-demo:/usr/share/nginx/html nginx:alpine
$ curl http://localhost:8090/
Hello students
```

Screenshot: [task3_before_screenshot.png](task3_before_screenshot.png)

Edited the file on the host, no restart:

```
$ echo "Hello students - updated without restart" > bindmount-demo/index.html
$ curl http://localhost:8090/
Hello students - updated without restart
```

Screenshot: [task3_after_screenshot.png](task3_after_screenshot.png)

A bind mount shares the same inode as the host path, so edits show up immediately in both directions — unlike `COPY`, which bakes a snapshot in at build time.

## Task 4 — Overlay networks (research)

An overlay network is Docker's multi-host driver — it encapsulates container traffic in VXLAN and tunnels it between Docker daemons on different machines, so containers on separate hosts can talk as if on the same network. Bridge networks (used above) only work within one host. Overlay networks are Swarm's default network type, and the same problem is what a CNI plugin (Calico, Flannel) solves for Kubernetes pod-to-pod traffic across nodes.

Not demoed hands-on — needs a multi-node Swarm cluster. Kubernetes' own cross-node networking (Session 9 onward) is the practical equivalent used for the rest of this course.
