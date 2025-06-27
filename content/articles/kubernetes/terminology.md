---
title: Kubernetes Terminology
description: Glossary with Kubernetes Terms
date: 2025-07-30
topics:
- kubernetes
---

This page lists terms used in Kubernetes whose meaning may not be immediately clear to software developers with average coding skills.

Control Plane
: Basically means "Kubernetes server". It's a set of Kubernetes services/processes required to run a Kubernetes cluster (e.g. the [kube-controller-manager](kube-controller-manager.md)). See the [official documentation](https://kubernetes.io/docs/concepts/overview/components/) for more details.

Controller
: Adopts the Kubernetes cluster to a resource. See [controllers](resources/overview.md#controllers) for more details.

EndpointSlice
: An improved resource type to store [Kubernetes endpoints](resources/services.md#endpoints). Can usually be used as synonym for "endpoint".

etcd
: The default storage service used to store Kubernetes objects.

Kubelet
: An agent that runs on each node in the cluster. The kubelet receives [Pod](resources/pods.md) specifications and ensures that the containers described in those specifications are running and healthy. See the [official documentation](https://kubernetes.io/docs/concepts/architecture/#kubelet) for more details.

Lease
: A resource type used in [leader election](leader-election.md).

Pod
: A grouping of one or more containers. See [Pods](resources/pods.md) for more details.
