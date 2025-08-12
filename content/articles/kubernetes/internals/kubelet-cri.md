---
title: Kubelet, CRI, Container Runtime, Scheduler - Kubernetes Internals
description: An overview of Kubelets, the CRI, the Container Runtime, and the Kubernetes Scheduler and how they connect
date: 2025-08-08
topics:
- kubernetes
- containers
---

When a [Pod](../resources/pods.md) is newly created in a cluster, Kubernetes uses the following pieces to start/run the Pod and its containers:

1. **Kubernetes Scheduler** - decides which node the Pod should run on.
1. **Kubelet** - runs on the target node and - among other things - instructs the *container runtime* (via the *CRI*) to start the containers of the Pod.
1. **CRI** - gRPC interface between *kubelet* and *container runtime*.
1. **Container runtime** - Responsible for running the containers of the Pod. In most cases, this is `containerd`.

## Kubelet {#kubelet}

The **kubelet** is a Kubernetes process that runs on every node in the cluster - both on the worker nodes and on the control plane nodes.

The purpose of the kubelet process is to ensure that the **Pods of its node are running and healthy**.

For this, the kubelet watches the Kubernetes cluster for Pods that should run on the node of the kubelet. It identifies them via the `.spec.nodeName` field in each Pod (usually assigned by the [Kubernetes Scheduler](#scheduler)).

It then reads the containers of each Pod for its node, compares them to the containers already running on the node, and then reconciles any differences.

The kubelet gets its Pod specifications from the Kubernetes API server (running on the control plane) and the container list via CRI from the container runtime (running on the node).

The kubelet also monitors the health of the containers on its node - through the readiness and health probes defined for each container, if there are any.

See also: [Official Documentation](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)

## Container Runtime Interface (CRI) {#cri}

The **container runtime interface (CRI)** is a standardized gRPC interface that allows a kubelet to communicate with its container runtime.

Kubernetes only works with container runtimes that implement the CRI.

The container runtime is the CRI server while the kubelet is the CRI client.

The CRI (not to be confused with [OCI](https://opencontainers.org/)) was designed specifically for Kubernetes. It's *not* indented to be a general-purpose container runtime interface.

See also:

* [Official Documentation](https://kubernetes.io/docs/concepts/architecture/cri/)
* [CRI gRPC API Specification](https://github.com/kubernetes/cri-api/blob/master/pkg/apis/runtime/v1/api.proto)

## Container Runtime {#container-runtime}

The **container runtime** is what starts, stops, and monitors the actual containers running on a node.

A Kubernetes-compatible container runtime must implement the CRI. At the time of writing (Aug 2025), there four main container runtimes for Kubernetes:

| Name                                  | Notes
| ------------------------------------- |------------------
| [containerd](https://containerd.io/)  | Used by most Kubernetes clusters; widely adopted by cloud providers; general-purpose (also used by Docker and Podman)
| [CRI-O](https://cri-o.io/)            | Kubernetes-only runtime; very lightweight; very niche; default in OpenShift (Red Hat ecosystem)
| Docker                                | via [`cri-dockerd` adapter](https://mirantis.github.io/cri-dockerd/); was supported out-of-the-box by Kubernetes via *dockershim* but support was removed with version 1.24
| Mirantis Container Runtime            | Commercial container runtime; formerly known as Docker Enterprise Edition; also via `cri-dockerd` adapter

The container runtime is used by Kubernetes as **"dumb" executioner** (start, stop, list containers). The CRI is designed to be as simple as possible - with most of the business logic running in the kubelet rather than the container runtime. For example:

* CRI containers only need to support bind mounts for volumes, even though the container runtime may support more mount types.
* The container runtime may support a restart policy for containers, but it's not used by Kubernetes. Container restarts are handled by kubelet.

The container runtime does, however, define the **default container registry**. This is used if you just specify a container images as `repo/name` (e.g. `envoyproxy/envoy`) instead of `host/repo/name` (e.g. `mcr.microsoft.com/devcontainers/base`).

See also: [Official Documentation](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)

## Kubernetes Scheduler {#scheduler}

The **Kubernetes Scheduler** is responsible to deciding which Pods goes on which node.

A Pod not yet assigned to a node is called "unscheduled" and the process of assigning the node is called "scheduling" (i.e. Pod A is scheduled to be on node X).

After the scheduler has decided which node that Pod will be placed on, it *binds* the Pod to the node. Although this sound like an elaborate process, it actually just means: Set `.spec.nodeName` on the Pod.

By default, Kubernetes uses **kube-scheduler** as scheduler. However, you can also provide your own scheduler (more complicated) or customize kube-scheduler via its [Scheduling Framework](https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/) (easier).

See also: [Official Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)
