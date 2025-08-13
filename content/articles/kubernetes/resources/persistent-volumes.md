---
title: PersistentVolumes and PersistentVolumeClaims - Kubernetes Resources
description: Overview of PersistentVolumes (PV) and PersistentVolumeClaims (PVC) in Kubernetes
date: 2025-08-01
topics:
- kubernetes
---

**PersistentVolumes** (PV) and **PersistentVolumeClaims** (PVC) are a [built-in resource types](overview.md) in Kubernetes. They are used to **store persistent data**, meaning the stored data will survive container restarts and Pod recreations.

A *PersistentVolume* is a piece of storage in the cluster that has been provisioned either manually (by an administrator) or dynamically (by a PersistentVolumeClaim). The PersistentVolume can be backed by various storage systems, like host paths, NFS, iSCSI, or a cloud-provider-specific storage system. Which one is used, is defined by the which `.spec` field is used (e.g. `.spec.local`, `.spec.csi`, `.spec.nfs`).

A *PersistentVolumeClaim* is a request for a piece of storage (i.e. *not* the storage itself). Kubernetes will then assign a PersistentVolume to the PersistentVolumeClaim - based on the various criteria such as volume size. Workload resources (i.e. [Pods](pods.md), [Deployments](deployments.md) but mainly [StatefulSets](stateful-sets.md)) primarily use this resource type (instead of PersistentVolume) to get their storage.

See also:

* [Official Documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
* [Kubernetes Volumes](../internals/volumes.md)

## Dynamically Provisioned Volumes {#dynamical-pv}

In most cases, you will **dynamically provision** a volume:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dyn-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi  # volume size
```

This will give you a volume of 100 MB of space - anywhere.

"Dynamically provisioned" means that the PersistentVolume for the claim is created automatically. This only happens if there is no existing, available PV in the cluster that matches the claim.

> [!NOTE]
> Whether the PersistentVolume for a PersistentVolumeClaim is provisioned *immediately*, is defined by the "volume binding mode" of the storage class (see [below](#storage-classes)).
>
> It can be:
>
> * `Immediate` - provisions the volume immediately.
> * `WaitForFirstConsumer` - provisions the volume when the first Pod is created that uses the claim.
>
> See also: [Official Documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode)

### How to interpret the spec

The PersistentVolumeClaim spec means: **I need *at least* this.**

But the PersistentVolume you'll get ***may* have more**; for example more storage than requested or it may support more access modes than requested. However, this normally only happens if your claim is bound to an already existing PersistentVolume.

In most cases, you'll get a dynamically provisioned PV - and then it's spec usually matches the spec of the PVC.

Note also that **you'll always need to specify**:

* at least one access mode in `.spec.accessModes`
* and the `.spec.resources.requests.storage` field.

> [!NOTE]
> Even if you want to **claim an already existing PersistentVolume** just by name (`.spec.volumeName`), you still need to specify these two values.

### Storage Classes {#storage-classes}

All PersistentVolumeClaims require a **storage class**. If you don't specify one (via `.spec.storageClassName`), the **default storage class** will be used.

You can see which storage classes are available in your cluster with:

```sh
$ kubectl get storageclasses
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  47d
```

When a PersistentVolumeClaim is fulfilled by **the provisioner of the selected storage class**, this provisioner will **create a PersistentVolume** for the claim.

> [!NOTE]
> The provisioner of a storage class can either be a CSI driver (listed via `kubectl get csidrivers`) or a built-in provisioner (like the `rancher.io/local-path` provisioner in K3s clusters).

You can get the name of the dynamically provisioned volume with (in the `VOLUME` column):

```sh
kubectl get pvc
```

If you're interested, you can then get the details of this PersistentVolume with:

```sh
kubectl get pv <persistent-volume-name> -o yaml
```

> [!TIP]
> You can also **create custom storage classes**, if the existing ones don't meet your requirements; for example, if the default [reclaim policy](#reclaim-policy) of the existing storage class is not what you want. See the official documentation for more details.

See also: [Official Documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/)

### Access Modes

Kubernetes supports four access modes for volumes:

* **ReadWriteOnce** - the volume can be mounted as read-write by a single node. This is how block devices (a.k.a. disks) behave. *Note:* It's possible for the volume to be mounted into multiple Pods running on the same node. For single pod access, use *ReadWriteOncePod*.
* **ReadWriteOncePod** - the volume can be mounted as read-write by a single Pod.
* **ReadOnlyMany** - the volume can be mounted as read-only by many nodes. This is used by storage providers that support concurrent reads but can't deconflict concurrent writes.
* **ReadWriteMany** - the volume can be mounted as read-write by many nodes. This is usually something like NFS shares; as such, the read/write performance may be worse than a *ReadWriteOnce* volume.

Kubernetes will only dynamically provision PersistentVolumes if the storage class' provisioner supports the requested access mode. For example, the `local-path` storage class in a K3s cluster only supports `ReadWriteOnce`. So you can't request a `ReadWriteMany` volume from it. (The PVC will stay in status "Pending" indefinitely.)

*Side note:* In a PVC, you can specify **more than one access mode**. In this case, this claim will match any volume that supports *all* of the requested access modes. However, you will probably never need this.

See also: [Official Documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)

### Using PVCs in Pods {#using-in-pods}

You can use a PersistentVolumeClaim in a Pod:

```yaml {lineNos=true,hl_lines="10-11,13,15"}
apiVersion: v1
kind: Pod
metadata:
  name: dyn-pvc-pod
spec:
  containers:
    - name: nginx
      image: nginx:1.26.0
      volumeMounts:
        - name: storage
          mountPath: /some/mount/path
  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: dyn-pvc
```

This will mount the PersistentVolume for the PersistentVolumeClaim `dyn-pvc` inside the `nginx` container at `/some/mount/path`.

> [!WARNING]
> If you're using PersistentVolumeClaims with [ReplicaSets](replica-sets.md), [Deployments](deployments.md), or [DaemonSets](daemonsets.md), note that **all Pods will share the same volume** (because all Pods will use exactly the same PVC).
>
> This first requires the access mode to be `ReadWriteMany` (or else only one of the Pods can get the volume and all others will stay in Pending state indefinitely).
>
> Also, PersistentVolumes are often bound to a specific node. So **all Pods would end up on the same node**.
>
> [StatefulSets](stateful-sets.md), on the other hand, use PersistentVolumeClaim *templates*. Through this, they can create a separate PersistentVolumeClaim for each Pod - meaning each Pod gets its own PersistentVolume.

### Using PVCs in StatefulSets

**StatefulSets** are the intended/primary way of consuming PersistentVolumeClaims (and thereby running stateful application).

Instead of `.spec.volumes.persistentVolumeClaim` they use `.spec.volumeClaimTemplates`.

See the [page on StatefulSets](stateful-sets.md) for more details.

## Manually Provisioned Volumes {#manual-pv}

You normally do *not* manually provision a volume. However, there are some corner cases where this can be necessary - primarily if you already have existing data sitting somewhere and you want a Pod to be able to use this data.

For this example, we will manually provision a PersistentVolume that maps to **a certain local path on a specific node**:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: manual-pv
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 100Mi
  storageClassName: manually-provisioned  # doesn't need to match any existing storage class
  local:
    path: /Applications/test  # Path on the node
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - node01  # Name of the node where "path" above is located
```

This will give Pods access to `/Applications/test` on `node01`.

To actually use this PersistentVolume, you need a **matching PersistentVolumeClaim**:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: manual-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: manually-provisioned
  volumeName: manual-pv
```

There are couple of notes here:

* Even though you specify the `volumeName`, the access mode, size request and storage class must still match the manually provisioned PersistentVolume. If any of them don't match the PersistentVolume, the claim won't be bound to the volume.
* There is a slight race condition here. If there is another unbound PersistentVolumeClaim that matches the manually provisioned PersistentVolume, Kubernetes may bind this other claim to the volume - making it unavailable for our claim.
* The `storageClassName` must match the `storageClassName` of the PersistentVolume. In this case, it has no other meaning - unlike with dynamically provisioned volumes where the storage class determines which kind of volume is created. It especially doesn't need to match any storage classes that exist in the cluster. On the other hand, it *can* match an existing storage class without any problems - the storage class' provisioner won't be invoked for this PV/PVC.

After you've created the PersistentVolumeClaim, you can simply [use it in Pods](#using-in-pods) like any PVC.

> [!TIP]
> If you don't mind the lesser separation of concerns, you *may* instead want to use one of the `.spec.volumes` fields in the Pod spec directly for this. This supports the same storage backends (see [below](#storage-backends)) as PersistentVolumes (except for `local`).

### Volume Binding

A fully provisioned PersistentVolume can be **available**, **bound**, or **released**.

A newly provisioned PersistentVolume starts in the state **"available"**.

When a PersistentVolume is claimed by a PersistentVolumeClaim, it changes its state from **"available" to "bound"**.

When the PersistentVolumeClaim of a bound PersistentVolume is deleted, the PersistentVolume changes its state from **"bound" to "released"** (if its [reclaim policy](#reclaim-policy) is set to "Retain").

> [!NOTE]
> The states **"available" and "released" are different**. An available volume is supposed to be empty, while a released volume is usually not empty.
>
> Because of this, PersistentVolumeClaim will *not* claim volumes in state "released".

The relationship between a PersistentVolume and a PersistentVolumeClaim is a 1-to-1 relationship; i.e. one claim can only bind one volume and one volume can only be bound by one claim.

**Once a PersistentVolume is bound to a PersistentVolumeClaim, this binding is permanent** - until the PersistentVolumeClaim is deleted. This way, when a Pod is rescheduled/recreated, it will get the exact same volume - because it uses the same PersistentVolumeClaim.

Available volumes can freely be bound to any claim they fit. For example, if there is a claim for a 100 MB volume and there is an available 150 MB volume in the cluster, the claim can be bound to this volume.

Normally, you won't see volumes in the "available" state because they need to be manually provisioned by the cluster admin. You'll also normally won't see volumes in the "released" state because dynamically provisioned volumes usually use "Delete" as reclaim policy.

## Storage Backends for Volumes {#storage-backends}

Above we've seen a PersistentVolume that maps to a local path on the node. However, PersistentVolumes also support other storage backends - depending on which field you use:

| Storage Backend Field | Description
| --------------------- | -----------
| `local`               | Maps to a local path on a node; required node affinity
| `hostPath`            | Like `local` but does not require a node affinity (see [below](#local-vs-hostpath))
| `csi`                 | The volume is provided via a [CSI](https://kubernetes.io/docs/concepts/storage/volumes/#csi) driver; see also: `kubectl get csidrivers`
| `fc`                  | Volume is provided over Fibre Channel
| `iscsi`               | Volume is provided over iSCSI
| `nfs`                 | Volume is provided over NFS

There are many more storage backends in the spec but they are all deprecated because they were moved into external CSI drivers.

All of these fields are **mutually exclusive**, meaning each PersistentVolume can only use one of this fields.

You can see all supported storage backends via:

```sh
kubectl explain PersistentVolume.spec
```

*Side note:* Every dynamically provisioned PersistentVolume must also adhere to the PersistentVolume spec - meaning it must use one of the supported storage backends.

### local vs. hostPath {#local-vs-hostpath}

The storage backends `local` and `hostPath` are very similar - they both map to a local path on the node.

The main difference: The `local` storage backend requires you specify a node affinity so that the volume is bound to a specific node. The `hostPath`, on the other hand, does *not* require a node affinity.

```yaml {lineNos=true,hl_lines="8-15"}
apiVersion: v1
kind: PersistentVolume
...
spec:
  ...
  local:
    path: /Applications/test  # Path on the node
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - node01  # Name of the node where "path" above is located
```

If you try to create a PV with the `local` storage backend but no node affinity, you get the following error:

> The PersistentVolume "manual-pv" is invalid: spec.nodeAffinity: Required value: Local volume requires node affinity

For the `hostPath` storage backend, you *can* use a node affinity - this way it behaves exactly the same as a `local` volume.

But what happens if you don't specify a node affinity for a `hostPath` volume? Let's test it:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: manual-pv-hostpath
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 100Mi
  storageClassName: hostpath-storage
  hostPath:
    path: /Applications/test
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hostpath-test-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Mi
  storageClassName: hostpath-storage
  volumeName: manual-pv-hostpath
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hostpath-test
spec:
  replicas: 5
  selector:
    matchLabels:
      app: hostpath-test
  template:
    metadata:
      labels:
        app: hostpath-test
    spec:
      containers:
        - name: nginx
          image: nginx:1.29.0
          volumeMounts:
            - name: storage
              mountPath: /some/mount/path
      volumes:
        - name: storage
          persistentVolumeClaim:
            claimName: hostpath-test-pvc
```

When you apply this, you will see that the Pods are distributed across your cluster:

```sh
$ kubectl get pods -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP            NODE
hostpath-test-8b6bfdcd7-5f66f   1/1     Running   0          74s   10.42.1.111   node02
hostpath-test-8b6bfdcd7-759dp   1/1     Running   0          74s   10.42.0.147   node01
hostpath-test-8b6bfdcd7-d997b   1/1     Running   0          74s   10.42.1.110   node02
hostpath-test-8b6bfdcd7-sl58z   1/1     Running   0          74s   10.42.0.148   node01
hostpath-test-8b6bfdcd7-wnwd5   1/1     Running   0          74s   10.42.1.112   node02
```

This means: In each Pod, the volume `storage` maps to the `/Applications/test` **directory of the node the Pod is running on**.

This can be fine, if that's what you want (may be useful for [DaemonSets](daemonsets.md)). But if you want to store your database files in this "persistent volume", things can go horribly wrong, because each Pod will get a random data directory every time it's rescheduled.

## Reclaim Policy {#reclaim-policy}

The **reclaim policy** defines what should happen to a PersistentVolume when its PersistentVolumeClaim is deleted.

There are two options:

* **Delete** - the volume and all of its data is deleted. This is the default for [dynamically provisioned volumes](#dynamical-pv).
* **Retain** - the volume and all of its data is *not* deleted. This is the default for [manually provisioned volumes](#manual-pv).

The reclaim policy is part of the PersistentVolume spec - not of the PersistentVolumeClaim spec.

Like mentioned above, if you **manually provision a PV** and don't specify a reclaim policy, the reclaim policy will be "Retain".

You can see the reclaim policy with (see `RECLAIM POLICY` column):

```sh
$ kubectl get pv
NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS       VOLUMEATTRIBUTESCLASS   REASON   AGE
manual-pv   100Mi      RWO            Retain           Bound    testing/manual-pvc   manually-created   <unset>                          2s
```

If you **dynamically provision a PV**, the PV will get its reclaim policy from its [storage class](#storage-classes):

```sh
$ kubectl get sc
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  47d
```

To change the reclaim policy for a dynamically (or manually) provisioned PV, you need to edit the PV resource (see [below](#change-reclaim-policy-on-pv)).

To change the reclaim policy for a PVC, you need to use (and create) another storage class. See the [official documentation on storage classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) for more details.

See also: [Official Documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming)

### Changing the Reclaim Policy on an Existing PV {#change-reclaim-policy-on-pv}

To change the reclaim policy on an existing volume, use:

```sh
kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

Or interactively:

```sh
kubectl edit pv <pv-name>
```

Then modify:

```yaml
spec:
  persistentVolumeReclaimPolicy: Retain  # or Delete
```

## Commands

List all existing PersistentVolumes:

```sh
kubectl get persistentvolumes  # for the current namespace
kubectl get pv                 # same; abbreviated name
kubectl get pv -n <namespace>  # for a different namespace
kubectl get pv -A              # for all namespaces
```

List all existing PersistentVolumesClaims:

```sh
kubectl get persistentvolumeclaims  # for the current namespace
kubectl get pvc                     # same; abbreviated name
kubectl get pvc -n <namespace>      # for a different namespace
kubectl get pvc -A                  # for all namespaces
```

List all existing storage classes:

```sh
kubectl get storageclasses
kubectl get sc
```
