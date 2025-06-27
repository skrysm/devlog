---
title: PersistentVolumes and PersistentVolumeClaims - Kubernetes Resources
description: Overview of PersistentVolumes (PV) and PersistentVolumeClaims (PVC) in Kubernetes
date: 2025-08-01
topics:
- kubernetes
---

**PersistentVolumes** (PV) and **PersistentVolumeClaims** (PVC) are a [built-in resource types](overview.md) in Kubernetes. They are used to **store persistent data**.

A *PersistentVolume* is a piece of storage in the cluster that has been provisioned either manually (by an administrator) or dynamically (by a PersistentVolumeClaim). The PersistentVolume can be backed by various storage systems, like host paths, NFS, iSCSI, or a cloud-provider-specific storage system. Which one is used, is defined by the *StorageClass* (either specified when manually creating the PV or as field in a PVC when dynamically creating the PV).

A *PersistentVolumeClaim* is a request for a piece of storage (i.e. *not* the storage itself). Kubernetes will then assign a PersistentVolume to the PersistentVolumeClaim - based on the various criteria such as volume size. Workload resources (i.e. [Pods](pods.md), [Deployments](deployments.md) but mainly [StatefulSets](stateful-sets.md)) use this resource type (instead of PersistentVolume) to get their storage.

See also: [Official Documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

## Manually Provisioning a Volume

You normally do *not* manually provision a volume. I just show this here so that you can see the structure of a PersistentVolume and how it differs from a PersistentVolumeClaim.

The primary example for manually provisioning a volume is when you already have existing data on a node.
