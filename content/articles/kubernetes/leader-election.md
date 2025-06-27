---
title: Kubernetes Leader Election
description: A quick overview of Kubernetes' leader election mechanism
date: 2025-07-30
topics:
- kubernetes
---

Some services running in Kubernetes' control plane use leader election in a high availability setup (i.e. when there is more than one control plane node).

> [!NOTE]
> I couldn't find any official documentation on this topic (see also [issue #51735](https://github.com/kubernetes/website/issues/51735) for this). The information in this article were mainly provided by ChatGPT. And while they make sense to me, I was not able to verify them down to the last detail.

| Service                                               | Leader Election                | Notes
| ----------------------------------------------------- | ------------------------------ | -----------------------------------
| kube-apiserver                                        | ❌ No                          | No need for leader election
| etcd                                                  | ✅ Yes, via **Raft Consensus** | Not using Kubernetes-style leader election
| [kube-controller-manager](kube-controller-manager.md) | ✅ Yes                         | Only one active controller manager
| kube-scheduler                                        | ✅ Yes                         | Only one active scheduler
| cloud-controller-manager                              | ✅ Yes                         | If used; only one should manage the cloud

The Kubernetes-style leader election is based on [**Lease**](https://kubernetes.io/docs/concepts/architecture/leases/) resources.

## Leases

A Lease object is basically a claim for leadership that says: **"I am the leader."**

A trimmed down version of a Lease looks like this:

```yaml
apiVersion: coordination.k8s.io/v1
kind: Lease
spec:
  holderIdentity: kube-controller-manager-2
  acquireTime: "2025-07-29T12:00:00Z"
  renewTime: "2025-07-29T12:00:10Z"
```

Each instance that competes for leadership (e.g. `kube-controller-manager-1`, `kube-controller-manager-2`, and `kube-controller-manager-3`) will try to create a Lease for themselves - but **only one will succeed**. And this instance will become the leader.

The Lease also contains an expiry timestamp. If it's not renewed in time, it's considered **expired**, and other instances can try to take over leadership.

> [!NOTE]
> The field `acquireTime` is just informational. It changes whenever the leadership changes (not on every renewal).

## Only One Succeeds

How can Kubernetes make sure that only one write operation succeeds? It uses **resource versions**. This represents *optimistic concurrency*.

Every Kubernetes object has a resource version (stored under `.metadata.resourceVersion`). It's changed every time a change is made to the object.

Another important piece is that **write requests are ordered**. So no two processes can write/update the same object at the same time. This is ensured by the store Kubernetes uses for its objects - which normally is etcd. Etcd in particular does its own leader election (via Raft consensus) and **only the leader instance will update objects** in its store (thus preventing concurrent writes to the same object).

Now, when an instance tries to acquire a Lease (i.e. take it over from the previous owner), it includes the *current* resource version in the write request. Since write operations are ordered, the first write operation will change the object - especially the `holderIdentity` field - and also its resource version. The write operations of other instances will fail (with HTTP 409 StatusConflict) because the now current resource version no longer matches the resource version from the write request.

So, only one instance can successfully write its lease and thus only this instance can acquire the Lease.

The same mechanism is used when the Lease is initially created (i.e. for the initial leader election). Only one instance will be able to create the Lease. All other instances will fail.

You can read more on this topic in the [official documentation](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency).

> [!NOTE]
> The `.metadata.resourceVersion` field is *not* updated by the instances that issue the write requests - it's readonly. It's only update by the Kubernetes object store (e.g. etcd).

> [!TIP]
> If you're interested, you can see the `.metadata.resourceVersion` value via: `kubectl get <resource-type> <resource-name> -o yaml`
