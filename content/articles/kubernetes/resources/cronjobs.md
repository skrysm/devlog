---
title: CronJobs - Kubernetes Resources
description: Overview of CronJobs in Kubernetes
date: 2025-07-28
topics:
- kubernetes
---

**CronJobs** are a [built-in resource type](overview.md) in Kubernetes. They allow you to run [Jobs](jobs.md) periodically. In fact, a CronJob creates a new Job resource every time it executes.

CronJobs are meant for performing regular scheduled actions such as backups, report generation, and so on.

Unlike Jobs, CronJobs clean up old Jobs by default.

See also: [Official Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

## Resource YAML

A CronJob resource wraps a [Job](jobs.md) resource (highlighted lines):

```yaml {lineNos=true,hl_lines="11-18"}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: print-date-periodic
spec:
  schedule: "* * * * *"
  timeZone: "UTC"
  successfulJobsHistoryLimit: 3  # Number of successful jobs to keep (default: 3)
  failedJobsHistoryLimit: 1      # Number of failed jobs to keep (default: 1)
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: echo
              image: busybox
              command: ["date"]
          restartPolicy: Never  # required
```

How often the Job is executed is specified in the `.spec.schedule` field.

The value of this field is **a regular Cron string**. For example, `* * * * *` means: every minute.

For creating or interpreting Cron strings, I recommend: **<https://crontab.guru/>**

### Time Zone

By default, the `.spec.schedule` will run in the [time zone of kube-controller-manager](../kube-controller-manager.md#time-zone) - which may or may not be UTC.

However, you can also specify the time zone explicitly via `.spec.timeZone`.

Besides `UTC`, you can also specify time zones like `Europe/Berlin` or `America/Chicago`.

For a list of possible time zone values, see: [TZ identifier list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)

If you try to use an **unsupported time zone**, you'll get an error when creating/updating the CronJob:

```sh
$ kubectl apply -f cronjob.yml
The CronJob "print-date-periodic" is invalid: spec.timeZone: Invalid value: "UTC23": unknown time zone UTC23
```

### Suspending a CronJob

CronJobs can be suspended.

Whether a CronJob is suspended, can be seen via:

```sh
kubectl get cronjobs
```

However, there is no (simple) commandline call to do this.

Instead you need to edit the CronJob's resource YAML and set `.spec.suspend` to `true`.

## Commands

List all existing CronJobs:

```sh
kubectl get cronjobs           # for the current namespace
kubectl get cj                 # same; abbreviated name
kubectl get cj -n <namespace>  # for a different namespace
kubectl get cj -A              # for all namespaces
```

To run a CronJob now (e.g. for debugging purposes), you can create a Job from a CronJob:

```sh
kubectl create job --from=cronjob/<cronjob-name> <name-for-new-job>
```

The new Job will execute immediately. Just remember to clean up the new job afterwards.

> [!NOTE]
> There is *no* commandline call to display the *next* execution of a CronJob.
