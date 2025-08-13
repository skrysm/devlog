---
title: Namespaces - Kubernetes Resources
description: Overview of Namespaces in Kubernetes
date: 2025-06-27
topics:
- kubernetes
---

**Namespaces** are a [built-in resource type](overview.md) in Kubernetes. They provide a mechanism to **group resources** within a cluster. You typically group resources that belong to the same application into a Namespace.

Many ([but not all](#without-namespace)) Kubernetes resources lives within a Namespace.

> [!TIP]
> While it's possible to put all resources in the default Namespace (see [below](#initial-namespaces)), it's not recommended - because you would end up with lots and lots of resources in that Namespace and that makes it harder to understand the applications running in the cluster.

> [!NOTE]
> Namespace are ***not* a security/isolation mechanism**; i.e. containers of one Namespace can communicate with containers in other Namespaces without problems.

**Official documentation:** <https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/>

## Commands

List all existing Namespaces:

```sh
kubectl get namespace
kubectl get namespaces
kubectl get ns
```

Get current Namespace (requires [kubens](https://github.com/ahmetb/kubectx)):

```sh
kubens
```

Switch the current Namespace (requires [kubens](https://github.com/ahmetb/kubectx)):

```sh
kubens <namespace_name>
```

See resources in a Namespace:

```sh
kubectl get <resource_type> -n <namespace_name>
```

Create Namespace without yaml file:

```sh
kubectl create namespace <namespace_name>
```

Delete Namespace - **and all the resources in it**:

```sh
kubectl delete namespace <namespace_name>
kubectl delete -f <namespace_resource>.yaml
```

## Resource YAML

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-new-namespace
```

Apply via `kubectl apply -f <filename>`.

## Initial Namespaces

There are 4 initial Namespaces:

* `default`
* `kube-node-lease`
* `kube-public`
* `kube-system`

The `default` Namespace just exists so that you can deploy Namespaces without the need to first create a Namespace.

The other 3 Namespaces are system Namespaces that contain Pods/resources required by Kubernetes itself.

## Resources without Namespaces {#without-namespace}

Most Kubernetes resources belong to a namespace - but not all of them.

For example:

* **Namespaced** - Pods, Deployments, PersistentVolumes
* **Not namespaced** - Nodes, Namespaces, StorageClasses, CsiDrivers

Whether a resource type is namespaced or not (see `NAMESPACED` column):

```sh
kubectl api-resources
```
