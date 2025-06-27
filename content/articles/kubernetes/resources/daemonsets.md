---
title: DaemonSets - Kubernetes Resources
description: Overview of DaemonSets in Kubernetes
date: 2025-07-31
topics:
- kubernetes
---

**DaemonSets** are a [built-in resource type](overview.md) in Kubernetes. They allow you to **run [Pods](pods.md) on every node** in the cluster.

Use cases for DaemonSets include:

* **Logging agents** -- Collect logs from all Pods on a node and forward them to a centralized logging system. (e.g., Fluentd, Vector, Logstash)
* **Metrics collectors / monitoring agents** -- Gather CPU, memory, disk, and network stats per node. (e.g., Prometheus Node Exporter, Datadog Agent, Zabbix Agent)
* **Security agents** -- Watch for suspicious syscalls or processes on the node. (e.g., Falco, OSSEC, Sysdig Agent)

> [!NOTE]
> DaemonSets respect [node taints](../taints.md) - which means that by default, DaemonSets will **only run on worker nodes** - not on control plane nodes (unless you run K3s as cluster). However, this can be overruled by using [tolerations](../taints.md).

See also: [Official Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)

## Resource YAML

DaemonSet are specified similar to [ReplicaSets](replica-sets.md):

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
        - name: fluentd
          image: fluentd:v1.18-1
```

> [!TIP]
> You can control which nodes the DaemonSet runs on. See [Pod Placement](pods.md#pod-placement) for more details.

## Commands

List all existing DaemonSets:

```sh
kubectl get daemonsets         # for the current namespace
kubectl get ds                 # same; abbreviated name
kubectl get ds -n <namespace>  # for a different namespace
kubectl get ds -A              # for all namespaces
```
