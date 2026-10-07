# Session 8: Docker Networking & Volumes

## Task 1: Container networking

Three containers (frontend, backend, database) across three user-defined
networks, with backend joined to two of them.

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

Full output: [`task1_setup_output.txt`](task1_setup_output.txt)

**Connectivity check** — backend can reach both neighbors since it's on
both networks; frontend (net1 only) cannot resolve database (net2 only),
which is exactly what network-scoped DNS is supposed to do:

```
$ docker exec frontend ping -c 2 backend
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.133 ms
--- 0% packet loss ---

$ docker exec backend ping -c 2 database
64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.084 ms
--- 0% packet loss ---

$ docker exec frontend ping -c 2 database   (should fail, frontend is not on net2)
ping: bad address 'database'
```

Full output: [`task1_connectivity_output.txt`](task1_connectivity_output.txt)

## Task 2: Host network

```
$ docker pull httpd
$ docker run -d --name apache-host --network host httpd
$ curl http://localhost:80/
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html><head><title>It works! Apache httpd</title></head>...
```

With `--network host`, the container skips Docker's own network namespace
and binds directly to the host's (here, Colima's Linux VM, whose ports 80
forward straight through to `localhost` on the Mac) — no `-p` mapping
needed or possible, since there's no isolation to map through.

Full output: [`task2_host_network_output.txt`](task2_host_network_output.txt) · Screenshot: [`task2_screenshot.png`](task2_screenshot.png)

## Task 3: Bind mount

```
$ mkdir bindmount-demo
$ echo "Hello students" > bindmount-demo/index.html
$ docker run -d --name bindmount-nginx -p 8090:80 \
    -v $(pwd)/bindmount-demo:/usr/share/nginx/html nginx:alpine
$ curl http://localhost:8090/
Hello students
```

Screenshot before edit: [`task3_before_screenshot.png`](task3_before_screenshot.png)

Then, **without restarting the container**, edited the local file directly:

```
$ echo "Hello students - updated without restart" > bindmount-demo/index.html
$ curl http://localhost:8090/
Hello students - updated without restart
```

Screenshot after edit: [`task3_after_screenshot.png`](task3_after_screenshot.png)

A bind mount isn't a copy — it's the container reading/writing the exact
same inode as the host path, so any host-side edit is visible inside the
container immediately (and vice versa), unlike `COPY` in a Dockerfile which
bakes a snapshot into the image at build time.

## Task 4: Overlay networks (research)

An **overlay network** is Docker's multi-host networking driver, built for
Swarm (or Kubernetes-adjacent setups) where containers on *different
physical/virtual machines* need to talk to each other as if they were on
the same L2 network. It works by encapsulating container traffic in VXLAN
packets and tunneling them between the Docker daemons on each host, using a
distributed key-value store (Swarm's built-in Raft log) to keep every node's
view of the network consistent.

The bridge networks used in Tasks 1–3 only work within a single Docker
host — containers on different machines can't see each other over a bridge
network at all. Overlay networks exist specifically to remove that
single-host limitation, which is why they're the default network type for
Swarm services and are conceptually similar to what a CNI plugin (Calico,
Flannel) provides for Kubernetes pod-to-pod networking across nodes.

Not demoed hands-on here since it needs a multi-node Swarm cluster, which is
out of scope for this single-machine Colima setup — Kubernetes' own
cross-node pod networking (covered from Session 9 onward) is the practical
equivalent used for the rest of this course.
