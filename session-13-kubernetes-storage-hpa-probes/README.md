# Session 13: Kubernetes Storage, HPA & Probes

## Task 1: Kubernetes Volumes (`01-kubernetes-volumes/`)

**emptyDir**: a scratch directory tied to the pod's lifetime, shared across
containers in the pod, deleted the moment the pod is deleted/recreated.

**hostPath**: mounts a path straight from the node's own filesystem — data
survives pod restarts (it's on the node, not the pod) but is tied to that
*specific* node, and doesn't survive the pod moving elsewhere.

```
$ kubectl exec hostpath-demo -- sh -c 'echo world > /data/file.txt && cat /data/file.txt'
world
$ minikube ssh -- cat /tmp/hostpath-data/file.txt
world
```

Proved the difference by writing to both, then deleting and recreating the
emptyDir pod — its data was gone (fresh `ls /data` returned nothing), while
hostPath data is written straight onto the node and would survive. Full
output: [`01-kubernetes-volumes/output.txt`](01-kubernetes-volumes/output.txt)

**PersistentVolume / PersistentVolumeClaim** (`02-persistent-storage/`):
decouples storage from any specific pod. Interesting real result — manually
created a `student-pv` (1Gi, `hostPath`), then a `student-pvc` requesting
500Mi with *no* `storageClassName` specified:

```
$ kubectl get pv
NAME                                       CAPACITY   STATUS      CLAIM
pvc-59b3a37e-6a76-4562-aa74-4ec694baa6b5   500Mi      Bound       default/student-pvc
student-pv                                 1Gi        Available
```

The PVC did **not** bind to the manually created `student-pv` — Minikube's
default StorageClass (`standard`) dynamically provisioned a brand new
volume instead, since the PVC didn't request `storageClassName: ""` to opt
out of dynamic provisioning. `student-pv` sat unused. This is a genuinely
useful lesson: in modern clusters with a default StorageClass, a PVC will
almost always get dynamically provisioned storage unless you explicitly
tell it not to — manually pre-created PVs are mostly a legacy/on-prem
pattern now. Full output: [`02-persistent-storage/output.txt`](02-persistent-storage/output.txt)

**StorageClass / dynamic provisioning** (`03-storageclass/`): confirmed
directly — a PVC with no pre-existing PV got bound in 5 seconds purely via
the `standard` StorageClass's `k8s.io/minikube-hostpath` provisioner
creating a volume on demand. Full output: [`03-storageclass/output.txt`](03-storageclass/output.txt)

## Task 2: HPA Hands-on (`04-hpa/`)

```
$ minikube addons enable metrics-server
$ kubectl apply -f deployment.yaml -f service.yaml -f hpa.yaml
$ kubectl get hpa
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 1%/50%   1         5         1          20s
```

Launched 10 `busybox` pods in a tight `wget` loop against the service.
nginx is cheap enough that CPU plateaued around 32% even under that load —
not enough to cross the 50% target — so lowered the deployment's CPU
*request* from 100m to 40m (a smaller request makes the same absolute CPU
usage a bigger percentage, which is itself a realistic lever: HPA scales on
% of **request**, not absolute cores):

```
$ kubectl get hpa
NAME       REFERENCE             TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 67%/50%   1         5         1          8m1s

$ kubectl describe hpa hpa-demo | tail -3
Events:
  Normal   SuccessfulRescale   ... New size: 2; reason: cpu resource utilization (percentage of request) above target
```

Replica count went 1 → 2, utilization settled at 46% (just under target) —
the HPA found its equilibrium. Full output, including the
`kubectl top pods` / `kubectl get hpa` snapshots every 20s:
[`04-hpa/hpa_scaling_output.txt`](04-hpa/hpa_scaling_output.txt)

**Probes** (`05-probes/`), tested by actually breaking each one rather than
just applying and reading the YAML:

- **Liveness**: stopped nginx inside the running container
  (`kubectl exec ... nginx -s stop`). The container process died, kubelet's
  restart policy brought it back — `RESTARTS` went from 0 to 1. (Technically
  this is the container crashing and `restartPolicy: Always` restarting it,
  which the liveness probe would *also* have triggered on its own within
  the next failureThreshold × periodSeconds window if the process had
  merely hung instead of exiting outright.)
- **Readiness**: without touching the process, moved `index.html` aside so
  `GET /` returns 404. Pod stayed `Running` with **0 restarts** but flipped
  to `0/1` READY, and `kubectl get endpoints` showed the pod **removed**
  from the Service entirely. Restored the file — pod went back to `1/1`
  and rejoined the Service's endpoints automatically. This is the cleanest
  proof that readiness ≠ liveness: one gates traffic, the other restarts
  the container, and they don't overlap.
  Output: [`05-probes/readiness_output.txt`](05-probes/readiness_output.txt)
- **Startup**: applied `startup.yaml` (startup + liveness + readiness all
  defined) and confirmed `kubectl describe pod` shows all three configured
  — startup's higher `failureThreshold: 30` with short `period: 2s` gives
  a slow-starting app up to 60s before the other probes even begin
  evaluating it.

## Task 3: Mini Project

Ran the full capstone from `mini-project/README.md` end to end in its own
`production-webapp` namespace: PVC + Deployment (2 replicas, all 3 probes,
CPU requests) + Service + HPA.

**Storage persistence verification:**
```
$ kubectl exec -n production-webapp $POD_NAME -- sh -c 'echo "Student: Vitha" > /data/student.txt'
$ kubectl delete pod -n production-webapp $POD_NAME
$ kubectl exec -n production-webapp $NEW_POD -- cat /data/student.txt
Student: Vitha
```
Pod was deleted and rescheduled onto a brand new pod name — the file
survived because it lived on the PVC, not the pod. Output:
[`mini-project/task1_storage_output.txt`](mini-project/task1_storage_output.txt)

**Service verification:** `kubectl port-forward` + `curl` returned the
nginx welcome page. Output: [`mini-project/task2_service_output.txt`](mini-project/task2_service_output.txt)

**HPA load test:** ran 20 parallel `busybox` load generators against the 2
replicas (each with a 100m CPU request, as specified in this mini-project's
own `deployment.yaml`, unlike the lowered-request trick used in Task 2).
CPU stayed around 7-30% and never crossed the 50% target — nginx serving a
static page is simply too cheap for 20 single-threaded `wget` loops to
saturate a 100m CPU request on this hardware. This is the expected,
documented tradeoff of testing HPA with a trivially fast backend rather
than a CPU-bound one; **Task 2 above already proves the scale-out mechanism
itself works** end to end (`SuccessfulRescale` event, replica count
1 → 2) once CPU usage does cross the threshold — the mini-project's
higher 100m request just means it needs proportionally more concurrent
load than was generated here to reach the same percentage. Full output:
[`mini-project/task3_hpa_output.txt`](mini-project/task3_hpa_output.txt)
