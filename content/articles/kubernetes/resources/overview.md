---
title: Kubernetes Resources
description: Overview of resources in Kubernetes
date: 2025-06-27
topics:
- kubernetes
---

Kubernetes is built around resources, like Pods, Deployments, Services, etc.

## Overview

Most of the time, you define resources as YAML files:

```yaml
apiVersion: v1
kind: Pod  # resource type
metadata:
  name: nginx  # resource name
spec:  # resource specification
  containers:
    - name: nginx
      image: nginx:1.29.0
```

You then created or updated the resource in your cluster with [`kubectl`](../kubectl.md):

```sh
kubectl apply -f <resource-file>
```

Resources can also be deleted this way:

```sh
kubectl delete -f <resource-file>
```

> [!NOTE]
> Resources can be created both via a yaml file (using `kubectl apply`) and via the command line (using `kubectl create`). It is, however, recommended to use yaml files so that they can be versioned in Git.

To get the YAML definition of an existing resource:

```sh
kubectl get <resource-type> <resource-name> -o yaml
```

Kubernetes has a built-in way to show all supported fields for a resource:

```sh
kubectl explain <resource-type>
```

For example:

```sh
kubectl explain namespaces
kubectl explain namespaces.metadata
```

Each resource type can be queried on the commandline via:

```sh
kubectl get <resource-type>
```

For example:

```sh
kubectl get namespaces
kubectl get pods
```

To get a list of all resource types in your cluster:

```sh
kubectl api-resources                                     # unsorted
kubectl api-resources | (head -n 1 && tail -n +2 | sort)  # sorted
```

> [!NOTE]
> Resource **names must be unique** (within their [namespace](namespaces.md)). See [Object Names and IDs](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) for more details.
>
> This is how `kubectl apply -f` and `kubectl delete -f` determine which resource to create/alter/delete.

## Naming Convention

The Kubernetes documentation uses capitalized names for resources, e.g. "Pod" instead of "pod", or "Deployment" instead of "deployment". We'll follow this convention here.

## Resource Files

Most of the time, resources in Kubernetes are defined via YAML files - like this:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.29.0
```

> [!TIP]
> Kubernetes supports **multiple documents per YAML file**. You separate documents with `---`. See [this section](services-clusterip.md#demo-app) for an example.

## Built-in Resources

Kubernetes provides the following built-in resources (ordered from basic to advanced):

* **Organization:**
  * [Namespaces](namespaces.md)
* **Workload Types:**
  * [Pods](pods.md)
  * [ReplicaSets](replica-sets.md) - builds on top of Pods
  * [Deployments](deployments.md) - builds on top of ReplicaSets
  * [DaemonSets](daemonsets.md)
  * [StatefulSet](daemonsets.md) - builds on top of PersistentVolumes
* **Networking:**
  * [Services](services.md)
    * [ClusterIP](services-clusterip.md)
    * [NodePort](services-nodeport.md)
    * [LoadBalancer](services-loadbalancer.md)
    * [External Services](external-services.md.md)
* **Storage:**
  * [PersistentVolumes and PersistentVolumeClaims](persistent-volumes.md)
  * [Ephemeral Volumes](pods-ephemeral-volumes.md)
* **Jobs:**
  * [Jobs](jobs.md)
  * [CronJobs](cronjobs.md) - builds on top of Jobs
* **Configuration:**
  * [ConfigMaps](configmaps.md)
  * [Secrets](secrets.md) - similar to ConfigMaps
  * [Alternatives To Secrets](secrets-alternatives.md)

## Custom Resources {#custom-resources}

Kubernetes can be extended with custom resources.

To see all custom resources installed in your cluster:

```sh
kubectl get crds
```

Each entry is a single custom resource definition for a specific "kind". The name of the CRD is based on:

```
<kind_plural>.<group>
```

So, the kind:

```yaml
apiVersion: hub.traefik.io/v1alpha1
kind: API
```

maps to:

```
apis.hub.traefik.io
^^^^ ^^^^^^^^^^^^^^
kind      group
```

You also get this information - including the api version(s) - via:

```sh
kubectl explain <crd-name>
```

For example:

```sh
kubectl explain apis.hub.traefik.io
```

## Controllers {#controllers}

Conceptually, for each resource there is a controller in Kubernetes.

For example, there is a deployment controller that manages the resource [Deployment](deployments.md).

Controllers continually watch for new or changed resources in the Kubernetes cluster and make sure, the desired state described in the resource matches the clusters actual state. And if it doesn't match, they (try to) rectify it.

For example, if you have a deployment with 3 replicas, the deployment controller makes sure that they are always 3 replicas running. If there are less, it starts new replicas until the desired replica count matches the actual replica count.

Controllers for [custom resources](#custom-resources) usually run inside their own [Pod](pods). The controllers for the built-in resources run inside the [kube-controller-manager](../kube-controller-manager.md).

> [!TIP]
> Most of the time, it's not important to understand how controllers work exactly - but it may be helpful to know that controllers exist in Kubernetes and what they do in general.
