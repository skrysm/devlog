---
title: Jobs - Kubernetes Resources
description: Overview of Jobs in Kubernetes
date: 2025-07-28
topics:
- kubernetes
---

**Jobs** are a [built-in resource type](overview.md) in Kubernetes. They allow you to run a Pod/container to completion, e.g. some kind of task that only runs once and then finishes. Jobs also support retries in case of errors, and executing tasks multiple times - both sequentially and in parallel.

To run Jobs periodically, use [CronJobs](cronjobs.md).

See also: [Official Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/)

## Resource YAML

```yaml {lineNos=true,hl_lines="8-13"}
apiVersion: batch/v1
kind: Job
metadata:
  generateName: print-date-  # instead of "name"; use with
                             # "kubectl create" instead of "kubectl apply"
spec:
  template:
    spec:
      containers:
        - name: echo
          image: busybox
          command: ["date"]
      restartPolicy: Never  # required
```

Like with a [ReplicaSet](replica-sets.md) and [Deployment](deployments.md), the highlighted lines are **a regular [Pod](pods.md) spec**.

Note also that a Job requires you to define the **restartPolicy** - with either `Never` (probably fine in most cases) or `OnFailure`.

To execute this Job, run ([reason](#rerun-job)):

```sh
kubectl create -f job.yml
```

There are also other helpful fields in the Job spec:

```yaml {lineNos=true,hl_lines="6-11"}
apiVersion: batch/v1
kind: Job
metadata:
  generateName: print-date-extended-
spec:
  parallelism: 2  # runs up to two Pods in parallel
  completions: 2  # runs the Pods until there are two successful
  activeDeadlineSeconds: 100  # seconds before Kubernetes kills the Job
  backoffLimit: 1  # number of retries if the Pod fails before the Job is marked
                   # as failed; default is 6
  ttlSecondsAfterFinished: 3600  # delete Job and Pod 1 hour after completion;
                                 # if not set, never delete Job or Pod
  template:
    spec:
      containers:
        - name: echo
          image: busybox
          command: ["date"]
      restartPolicy: Never
```

### Running a Job Again {#rerun-job}

When you define a Job - rather than a CronJob - you most likely want to **run the Job on-demand**. This usually also means that you want to **run the Job again after it has already run in past**.

To achieve this, we use `.metadata.generateName` (with `kubectl create -f`) instead of `.metadata.name` (with `kubectl apply -f`).

If you use `.metadata.name`, the Job would only run once - and then *never* again. If you try to re-run this Job, you get (and the Job won't be executed again):

```sh
$ kubectl apply -f job.yml
job.batch/print-date unchanged
```

However, if you use `.metadata.generateName`, the Job gets a new name on every call and thus can re-run:

```sh
$ kubectl create -f job.yml
job.batch/print-date-6wchh created

$ kubectl create -f job.yml
job.batch/print-date-nvpgx created
```

> [!TIP]
> You probably also want to **specify `.spec.ttlSecondsAfterFinished`** with an appropriate value - so that Jobs and their Pods don't stay in your cluster forever.

## Commands

List all existing Jobs:

```sh
kubectl get jobs                 # for the current namespace
kubectl get jobs -n <namespace>  # for a different namespace
kubectl get jobs -A              # for all namespaces
```

This will print something like:

```
NAME         STATUS     COMPLETIONS   DURATION   AGE
print-date   Complete   1/1           8s         9s
```

The Pod(s) created by a Job get a random "hash" appended to their name (to avoid naming conflicts):

```sh
$ kubectl get pods
k get pods
NAME                          READY   STATUS      RESTARTS   AGE
print-date-chcm7              0/1     Completed   0          22s
```

## Comparison to Pods {#comparison-to-pods}

Theoretically, you can use a regular [Pod](pods.md) to run a one-off job:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: print-date
spec:
  containers:
    - name: echo
      image: busybox
      command: ["date"]
  restartPolicy: OnFailure
```

However, Jobs have some feature that Pods don't have:

* Jobs are resistant against Node crashes.
* Jobs allow you to easily run the job Pod multiple times in parallel and/or sequentially.
* Jobs and their Pods can be cleaned up automatically after the Jobs has completed.
* [CronJobs](cronjobs.md) require Jobs as underlying resource.
