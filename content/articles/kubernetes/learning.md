---
title: Learning Kubernetes
description: How to learn Kubernetes
date: 2025-07-03
topics:
- kubernetes
---

This page gives a few pointers on how to learn Kubernetes.

## Kubernetes Crash Course

I've created several articles that teach you the basics of Kubernetes. I recommend you read them in the following order:

1. [Overview of Kubernetes resources](resources/overview.md)
1. [Overview of `kubectl`](kubectl.md)
1. [](resources/namespaces.md)
1. [](resources/pods.md)
1. [](resources/replica-sets.md) - builds on top of Pods
1. [](resources/deployments.md) - builds on top of ReplicaSets
1. [](resources/services.md)
1. [](resources/services-clusterip.md)
1. [](resources/services-nodeport.md) - builds on top of ClusterIPs
1. [](resources/services-loadbalancer.md) - builds on top of NodePorts
1. [](resources/external-services.md)
1. [](resources/persistent-volumes.md)
1. [](resources/stateful-sets.md)
1. [](resources/jobs.md)
1. [](resources/cronjobs.md) - builds on top of Jobs
1. [](taints.md)
1. [](resources/daemonsets.md)
1. [](resources/configmaps.md)
1. [](resources/secrets.md)
1. [](resources/secrets-alternatives.md)

## Other Learning Resources

### Complete Kubernetes Course - From BEGINNER to PRO

The articles in my Kubernetes Crash Course started out as course notes of this excellent Kubernetes course on YouTube:

[Complete Kubernetes Course - From BEGINNER to PRO](https://www.youtube.com/watch?v=2T86xAtR6Fo) \
By DevOps Directive (about 6 hours)

### Kubernetes The Hard Way

The "Kubernetes The Hard Way" repo takes you through the steps of manually setting up a Kubernetes cluster - thereby learning all the basics.

You can find the repo on GitHub: [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
