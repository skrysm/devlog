---
title: Volumes in Kubernetes
description: Details about how volumes materialize inside containers in Kubernetes
date: 2025-08-12
topics:
- kubernetes
- containers
- container-volumes
---

Volumes are a central component of Kubernetes workflows.

See also: [Official Documentation](https://kubernetes.io/docs/concepts/storage/volumes/)

## Volume Types and Volume Lifetimes

There are two lifetime "models" for volumes:

* *Ephemeral volumes* - they only live as long as the Pod they belong to.
* *Persistent volumes* - their lifetime is managed separately; i.e. it's *not* tied to the lifetime of Pod.

You'll use volumes through these resources in Kubernetes:

| Volume Type                                                                           | Lifetime
| ------------------------------------------------------------------------------------- | ----------
| [PersistentVolumes and PersistentVolumeClaims](../resources/persistent-volumes.md)    | persistent
| [ConfigMaps](../resources/configmaps.md)                                              | ephemeral
| [Secrets](../resources/secrets.md)                                                    | ephemeral
| [Explicit Ephemeral Volumes](../resources/pods-ephemeral-volumes.md)                  | ephemeral

## Bind Mounts

Kubernetes makes volumes available to containers with so called **bind mounts**.

Bind mounts are like symlinks - but instead of symlinks they use the mount system (which is implemented at the kernel level).

Bind mounts can be created like this:

```sh
mount --bind /var/data/app /mnt/app
```

With this, the contents of directory `/var/data/app` are also available inside the directory `/mnt/app`.

## Kubernetes and Bind Mounts

Kubernetes uses bind mounts to bring volumes into containers.

This means, Kubernetes first sets up the volume **in a local directory on the node** (under `/var/lib/kubelet/pods/`) where the consuming Pod will be running - and then bind mounts this directory into the container(s) of the Pod.

Actually, Kubernetes does *not* create the bind mount itself. Instead, it instructs the [container runtime](kubelet-cri.md) to create the bind mount - via the [`Mount` message](https://github.com/kubernetes/cri-api/blob/master/pkg/apis/runtime/v1/api.proto):

```proto
service RuntimeService {
    ...
    rpc CreateContainer(CreateContainerRequest) returns (CreateContainerResponse) {}
    ...
}
message CreateContainerRequest {
    ...
    ContainerConfig config = 2;
    ...
}
message ContainerConfig {
    ...
    repeated Mount mounts = 7;
    ...
}
message Mount {
    // Path of the mount within the container.
    string container_path = 1;
    // Path of the mount on the host.
    string host_path = 2;
    // If set, the mount is read-only.
    bool readonly = 3;
    ...
}
```

Here, the `Mount.host_path` field specifies the path on the node itself where Kubernetes created the volume.

> [!NOTE]
> There is an additional volume type called "[image volumes](https://kubernetes.io/docs/tasks/configure-pod-container/image-volumes/)" - but, at the time of writing, it's still in beta and *not* enabled by default.

To see all volumes mounted into Kubernetes containers on a node, run:

```sh
findmnt | grep /var/lib/kubelet/pods/
```

As you can see, the Kubernetes creates volumes under:

```
/var/lib/kubelet/pods/<pod-uid>/volumes/<volume-type>/<volume-name>
```

To get the UID of a Pod:

```sh
kubectl get pod <pod-name> -o jsonpath='{.metadata.uid}'
```

### Why Only Bind Mounts?

Container runtimes (e.g. containerd) may support mounting types other than "bind mounts". So why does Kubernetes only uses bind mounts?

The anser is: Simplicity.

By only using bind mounts, Kubernetes (or the [kubelet](kubelet-cri.md) to be precise) does all the heavy lifting of getting the volumes mounted in the node's file system. The container runtime then doesn't need to know or support any of this - it just needs to bind mount the specified path.

## PersistentVolume Location

For any given (dynamically provisioned) [PersistentVolume](../resources/persistent-volumes.md), you can actually see the host path on the node that's used as source for the bind mount:

```sh
kubectl get pv <persistent-volume-name> -o yaml
```

This will give you something like this:

```yaml {lineNos=true,hl_lines="7"}
apiVersion: v1
kind: PersistentVolume
...
spec:
  ...
  local:
    path: /var/lib/rancher/k3s/storage/pvc-74ccace2-85e5-432b-ae...
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - central
  ...
```

Note also the `nodeAffinity` that binds the PersistentVolume to a certain node - which is required since the `path` is only available on that single node.

Alternatively, the PersistentVolume provider may decide to use one of the other storage backends available on a PersistentVolume: `csi` (CSI provisioned volume), `fc` (Fibre Channel), `hostPath`, `iscsi`, or `nfs`.

For Kubernetes clusters hosted by a cloud provider, CSI provisioned volumes are often attached as block devices through the underlying hyper-visor - instead of using a special storage-over-network driver (e.g. iSCSI) inside the system.
