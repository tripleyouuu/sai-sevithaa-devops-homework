# Session 13 — Kubernetes Storage, HPA & Probes

## Task 1 — Volumes

**emptyDir** — scratch directory tied to the pod's lifetime, gone the moment the pod is deleted/recreated.

**hostPath** — mounts a path from the node's own filesystem, survives pod restarts but is tied to that node.

```
$ kubectl exec hostpath-demo -- sh -c 'echo world > /data/file.txt && cat /data/file.txt'
world
$ minikube ssh -- cat /tmp/hostpath-data/file.txt
world
```

Deleted and recreated the emptyDir pod — its data was gone. hostPath data is written straight onto the node and survives. Full output: [01-kubernetes-volumes/output.txt](01-kubernetes-volumes/output.txt)

**PersistentVolume / PersistentVolumeClaim** — manually created a 1Gi `student-pv`, then a PVC requesting 500Mi with no `storageClassName`:

```
$ kubectl get pv
pvc-59b3a37e-...   500Mi   Bound       default/student-pvc
student-pv         1Gi     Available
```

The PVC didn't bind to the manual PV — Minikube's default StorageClass dynamically provisioned a new volume instead, since the PVC never opted out. `student-pv` sat unused. Useful lesson: with a default StorageClass in play, a PVC gets dynamic storage unless told otherwise — manually pre-created PVs are mostly a legacy pattern now. Full output: [02-persistent-storage/output.txt](02-persistent-storage/output.txt)

**StorageClass** — confirmed directly: a PVC with no pre-existing PV bound in 5 seconds via the `standard` StorageClass's provisioner. Full output: [03-storageclass/output.txt](03-storageclass/output.txt)

## Task 2 — HPA

```
$ minikube addons enable metrics-server
$ kubectl apply -f deployment.yaml -f service.yaml -f hpa.yaml
$ kubectl get hpa
hpa-demo   Deployment/hpa-demo   cpu: 1%/50%   1   5   1
```

10 `busybox` pods hammering the service with `wget` only got CPU to ~32% — nginx is too cheap. Lowered the CPU request from 100m to 40m (HPA scales on % of request, so a smaller request makes the same usage a bigger percentage):

```
$ kubectl get hpa
hpa-demo   Deployment/hpa-demo   cpu: 67%/50%   1   5   1

$ kubectl describe hpa hpa-demo | tail -3
Normal   SuccessfulRescale   New size: 2; reason: cpu resource utilization above target
```

Replicas went 1 → 2, utilization settled at 46%. Full output: [04-hpa/hpa_scaling_output.txt](04-hpa/hpa_scaling_output.txt)

**Probes**, tested by actually breaking each one:

- **Liveness** — stopped nginx inside the container (`nginx -s stop`); kubelet restarted it, `RESTARTS` went 0 → 1.
- **Readiness** — moved `index.html` aside without touching the process, so `GET /` returns 404. Pod stayed `Running` with 0 restarts but flipped to `0/1` and got pulled from the Service's endpoints. Restored the file, it rejoined automatically. Clean proof readiness gates traffic while liveness restarts — they don't overlap. Output: [05-probes/readiness_output.txt](05-probes/readiness_output.txt)
- **Startup** — applied all three probes together; startup's higher `failureThreshold` with a short period gives a slow app up to 60s before the others start evaluating it.

## Task 3 — Mini Project

Ran the full brief end to end in its own `production-webapp` namespace: PVC + Deployment (2 replicas, all 3 probes) + Service + HPA.

```
$ kubectl exec -n production-webapp $POD_NAME -- sh -c 'echo "Student: Vitha" > /data/student.txt'
$ kubectl delete pod -n production-webapp $POD_NAME
$ kubectl exec -n production-webapp $NEW_POD -- cat /data/student.txt
Student: Vitha
```

Pod rescheduled onto a new pod name, file survived — it lived on the PVC. Output: [mini-project/task1_storage_output.txt](mini-project/task1_storage_output.txt)

Service verification (`kubectl port-forward` + `curl`): [mini-project/task2_service_output.txt](mini-project/task2_service_output.txt)

HPA load test: 20 `busybox` generators against 2 replicas at the brief's own 100m CPU request. CPU stayed at 7-30%, never crossed 50% — nginx is too cheap for the load generated at this request size. Task 2 above already proves the scale-out mechanism itself works; this just needed more concurrent load to reach the same percentage at a higher request. Full output: [mini-project/task3_hpa_output.txt](mini-project/task3_hpa_output.txt)
