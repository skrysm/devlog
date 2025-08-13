---
title: Deployments - Kubernetes Resources
description: Overview of Deployments in Kubernetes
date: 2025-07-22
topics:
- kubernetes
---

**Deployments** are a [built-in resource type](overview.md) in Kubernetes. They extend [ReplicaSets](replica-sets.md) - they allow you to change/update the Pod's of the ReplicaSet *after* the ReplicaSet has been created (e.g. update the container image version).

**Concept Hierarchy:**

1. [Pods](pods.md)
1. [ReplicaSets](replica-sets.md)
1. **Deployments**

You will very rarely create Pods or ReplicaSets directly. Instead, almost always, you'll create Deployments.

**Internal DNS name**: no

**Official documentation:** <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>

## Relation to ReplicaSets

In its simplest form, the definition of a Deployment is mostly the same as the definition of a ReplicaSet.

**ReplicaSet:**

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx    # matches label below
  template:
    metadata:
      labels:
        app: nginx  # matches selector above
    spec:
      containers:
        - name: nginx
          image: nginx:1.29.0
```

**Deployment:**

```yaml {lineNos=true,hl_lines="2"}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx    # matches label below
  template:
    metadata:
      labels:
        app: nginx  # matches selector above
    spec:
      containers:
        - name: nginx
          image: nginx:1.29.0
```

In this minimal example, they only differ in their `kind`.

> [!NOTE]
> As with ReplicaSets, the `spec.selector` field is required. See [Selector - necessary or not?](replica-sets.md#selector) for more details.

Unlike ReplicaSets, however, you *can* change the Pod template (for example, change the container image version). In this case, Kubernetes will **create a new ReplicaSet and delete the old one**.

## Rollouts and Rollbacks

Deployments extend ReplicaSets with the concepts of **rollouts**.

Whenever apply changes to a Deployment, a **new rollout** is created. Each rollout creates a new ReplicaSet.

When a new/different rollout becomes active, Kubernetes gradually scales up the new ReplicaSet to the desired number of `replicas` while decreasing the replicas of the previous ReplicaSet in parallel. This is called a **rollover**.

A **rollback** is simply a rollover to a previous rollout.

You can see a rollover in action by running this command (requires an existing Deployment):

```sh
kubectl rollout restart deployment nginx && watch -n 1 "kubectl get pods"
```

This will create a new rollout of the specified Deployment without changing any resource definition. When you execute this, you'll see how gradually new Pods will get created while existing Pods (of the old rollout) get deleted.

> [!TIP]
> You can also watch the rollout with this command:
>
> ```sh
> kubectl rollout status deployment -w nginx
> ```

Previous rollouts (=ReplicaSets) are kept within the cluster - but with "Desired" set to zero:

```sh
$ kubectl get rs --sort-by='{.metadata.creationTimestamp}'
NAME               DESIRED   CURRENT   READY   AGE
nginx-5cbcc95d7    0         0         0       29s
nginx-96c495969    0         0         0       16s
nginx-6b74df49c8   3         3         3       7s
```

Here, the `nginx` Deployment has 3 rollouts.

By default, Kubernetes **keeps 10 rollouts** per Deployment; this value can be changed via `.spec.revisionHistoryLimit` on the Deployment.

To rollback to the previous rollout, call:

```sh
kubectl rollout undo deployment nginx
```

When you now look at the ReplicaSets, you'll that the previous one is now being used again:

```sh
$ k get rs --sort-by='{.metadata.creationTimestamp}'
NAME               DESIRED   CURRENT   READY   AGE
nginx-5cbcc95d7    0         0         0       2m23s
nginx-96c495969    3         3         3       2m10s
nginx-6b74df49c8   0         0         0       2m1s
```

You can also see the history of a Deployment with:

```sh
$ kubectl rollout history deployment nginx
deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
3         <none>
4         <none>
```

You can then using the revision to roll back to a specific revision:

```sh
kubectl rollout undo deployment nginx --to-revision=3
```

### Rollover Details

When Kubernetes detects an update to an existing Deployment, the old ReplicaSet needs to be scaled down.

To determine whether an old ReplicaSet needs to be scaled down, Kubernetes checks all existing ReplicaSets for those whose:

* `.spec.selector` matches the `.spec.selector` of the Deployment
* but whose `.spec.template` does not match the `.spec.template` of the Deployment (anymore).

Note that the `.spec.selector` value of both Deployments and ReplicaSets is immutable (i.e. can't be changed after the Deployment/ReplicaSet has been created).

When rolling over, Kubernetes ensures that only a certain number of Pods are down while they are being updated. By default, it ensures that at least 75% of the desired number of Pods are up (25% max unavailable).

Kubernetes also ensures that only a certain number of Pods are created *above* the desired number of Pods. By default, it ensures that at most 125% of the desired number of Pods are up.

Often this means that Kubernetes first creates a new Pod, then deletes an old Pod, and then creates another new one. It does not kill old Pods until a sufficient number of new Pods have come up, and does not create new Pods until a sufficient number of old Pods have been killed.

For example, in case of a Deployment with 4 replicas, the overall number of Pods for that Deployment would be between 3 and 5.

Sources:

* [Official Documentation: Updating a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)
* [Official Documentation: Rollover](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rollover-aka-multiple-updates-in-flight)

## Commands

List all existing Deployments:

```sh
kubectl get deployments            # for the current namespace
kubectl get deploy                 # same; abbreviated name
kubectl get deploy -n <namespace>  # for a different namespace
kubectl get deploy -A              # for all namespaces
```

This will print something like:

```
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   3/3     3            3           3m16s
```

Similar to ReplicaSets, the Pods of a Deployment get two random "hashes" appended to their name - one for the Deployment and one for the ReplicaSet:

```sh
> kubectl get pods
NAME                    READY   STATUS    RESTARTS   AGE
nginx-5cbcc95d7-cqrzz   1/1     Running   0          5m3s
nginx-5cbcc95d7-mp9kx   1/1     Running   0          5m3s
nginx-5cbcc95d7-rnkx6   1/1     Running   0          5m3s
```

Restart a deployment:

```sh
kubectl rollout restart deployment <deployment-name>
```

Rollback to previous rollout:

```sh
kubectl rollout undo deployment <deployment-name>
kubectl rollout undo deployment <deployment-name> --to-revision=<revision>
```
