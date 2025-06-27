---
title: kube-controller-manager - Kubernetes Services
description: A quick overview of the kube-controller-manager
date: 2025-07-30
topics:
- kubernetes
---

The **kube-controller-manager** is the application/service in Kubernetes that **runs the [controllers](resources/overview.md#controllers) for all [built-in resources](resources/overview.md#built-in-resources)**.

It is part of the so called [control plane](terminology.md).

Normally, it runs as a [Pod](resources/pods.md) in the "kube-system" [Namespace](resources/namespaces.md). However, in K3s it runs directly in the K3s process (and not as Pod).

## High Availability Setup

The kube-controller-manager runs on *every* control plane node.

If there is more than one control plane node, kube-controller-manager uses [Kubernetes leader election](leader-election.md) so that **only one instance is active** (i.e. the leader) and all other instances are on standby.

## Time Zone {#time-zone}

The [CronJob resource](resources/cronjobs.md) uses the time zone of the *active/leading* kube-controller-manager instance, if no time zone has been configured explicitly for the CronJob.

This happens because the CronJob controller runs in the kube-controller-manager process.

The kube-controller-manager process gets its time zone from its environment:

* If the kube-controller-manager runs **inside a Pod/container** (regular Kubernetes clusters), its **time zone is UTC** - because its container is explicitly set to UTC.
* In **K3s**, on the other hand, kube-controller-manager **inherits its time zone from the machine** it's running on (since it doesn't run inside a container).
