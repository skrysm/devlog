---
title: Taints and Tolerances in Kubernetes
description: Overview of Taints and Tolerances in Kubernetes
date: 2025-07-31
topics:
- kubernetes
---

**Taints** allow **nodes to repel Pods** - i.e. prevent Pods from being placed on nodes. ([Node affinities](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) are the opposite and are used to *attract* Pods to nodes.)

**Tolerations** are used to ignore Taints so that Pods can still be placed on tainted nodes.

Taints and tolerations are respected by all Pod-related resources (e.g. Pods, Deployments, DaemonSets, ...).

See also: [Official Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

## Taints

There are three taint **effects**. They only affect Pods that don't [tolerate](#tolerations) (i.e. ignore) the taint:

* `NoExecute` - Pods are not placed on this node. Running Pods are immediately evicted (i.e. removed) from this node.
* `NoSchedule` - Pods are not placed on this node. Running Pods are *not* evicted.
* `PreferNoSchedule` - Same as `NoSchedule`, but the control plane will only *try* to avoid placing Pods on the node, but it is not guaranteed.

Taints can be added to a node or removed from a node with the `kubectl taint` command.

To add a taint:

```sh
kubectl taint nodes node1 key1=value1:NoSchedule  # with value
kubectl taint nodes node1 key2:NoExecute          # without value
```

To remove a taint (note the `-` at the end):

```sh
kubectl taint nodes node1 key1=value1:NoSchedule-
kubectl taint nodes node1 key2:NoExecute-
```

You can put multiple taints on a single node.

To see all taints of a node:

```sh
kubectl get node <node> -o json | jq '.spec.taints'
```

## Tolerations {#tolerations}

Tolerations allows Pods to ignore certain taints and thus be placed on such node.

Tolerations are part of the Pod specification: `.spec.tolerations`

To tolerate (i.e. ignore) a taint **with value**, use (`operator: "Equal"`):

```yaml
tolerations:
  - key: "key1"
    operator: "Equal"
    value: "value1"
    effect: "NoSchedule"
```

To tolerate a taint **without value**, use (`operator: "Exists"`):

```yaml
tolerations:
  - key: "key2"
    operator: "Exists"
    effect: "NoExecute"
```

A taint is only tolerated, if key, value, and effect of the toleration match the taint.

> [!NOTE]
> There are two special cases:
>
> * An empty `key` (together with `operator: "Exists"`) matches all keys and values.
> * An empty `effect` matches all effects.

You can put multiple tolerations on a single Pod.

If a **node has multiple taints**, Kubernetes first matches the Pod's tolerations against the taints. If any taint remains un-ignored, its effect will be used.

## Use Cases

Many Kubernetes clusters (except K3s, by default) use taints to prevent Pods from being placed on the control plane nodes.

You can find more use case examples in the [official documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#example-use-cases).
