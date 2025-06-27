---
title: Pods - Kubernetes Resources
description: Overview of Pods in Kubernetes
date: 2025-07-22
topics:
- kubernetes
- containers
---

**Pods** are a [built-in resource type](overview.md) in Kubernetes. They are **the foundation** of all applications deployed in Kubernetes.

A Pod can contain one or more [containers](https://kubernetes.io/docs/concepts/containers/). Different Pods can run on different nodes (meaning: machines) but the containers of a single Pod will always **run on the same machine**.

Pods are often cited as the "smallest deployable unit" in Kubernetes - meaning, if you need to deploy a container, you need to "wrap" it in a Pod.

To access the services in a Pod from outside of the Pod, you need to define a [Service](services.md) for this Pod.

**Concept Hierarchy:**

1. **Pods**
1. [ReplicaSets](replica-sets.md)
1. [Deployments](deployments.md)

> [!NOTE]
> Except for educational purposes, you will never create Pods directly - instead you will use [deployments](deployments.md).
>
> However, you still need to understand what Pods are and how they work because Pods are used by deployments.

**Internal DNS name**: `<pod-ip-address>.<namespace>.pod.cluster.local` (not really useful because you need the Pod's ip)

**Official documentation:** <https://kubernetes.io/docs/concepts/workloads/pods/>

## The Word "Pod"

For those whose primary language isn't English, the word "pod" may be confusing.

The word "pod" in this context means "a group of fish" - or "a group of whales" - extending Docker's whale analogy where a whale is a container.

## Containers

In its simplest/most common form, a Pod contains just one container.

It is, however, possible to have *multiple* containers within a single Pod. These containers will then all run on the same machine.

Often, additionally to the primary container, the following "helper" containers are used:

* [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/): They run before the primary container is started.
* [Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/): They run alongside the primary container.

As a distinction, the "regular" containers are called "app containers". Also, you can have multiple app containers in a Pod.

### Multiple Containers or Multiple Pods?

To decide whether all your application containers should be in the same Pod or in different Pods, ask yourself:

> Will these two containers still work properly if they're running on *different* machines?

If the answer is yes, put them in different Pods.

If the answer is no, put them in the same Pod.

### Containers and Processes

It's normally best practice to have **one process per container**. However, it's technically possible to have multiple processes within the same container.

As far as Kubernetes (or Docker) is concerned, it only monitors the main process - which is the process with PID 1.

To see which process is the main process of a certain container, run:

```sh
kubectl exec -it <pod> -c <container> -- readlink /proc/1/exe
```

### Pods and Container Crashes

If the main process of a container crashes or exits, Kubernetes will (usually; see below) restart the container. It will **only restart *this* container**. If there are multiple containers within the Pod, the other containers will remain unchanged.

To see the crash count of a Pod (look for the column `RESTARTS`):

```sh
kubectl get pod <pod_name>
```

To see the status and start times of all containers in a Pod, use (look for the `Containers:` section):

```sh
kubectl describe pod <pod_name>
```

Whether Kubernetes actually restarts the container, depends on the Pod's `restartPolicy`:

| Policy      | Exit Code 0 | Exit Code non-zero | Crash      |
| ----------- | ----------- | ------------------ | ---------- |
| `Always`    | Restart     | Restart            | Restart    |
| `OnFailure` | No restart  | Restart            | Restart    |
| `Never`     | No restart  | No restart         | No restart |

If no `restartPolicy` has been defined, Kubernetes will use `Always`.

> [!NOTE]
> The Pod's `restartPolicy` only applies to app containers and init containers. Sidecar containers always have `Always` as restart policy.

To see the `restartPolicy` of a Pod:

```sh
kubectl get pod <pod_name> -o yaml | grep restartPolicy
```

**Official documentation:** <https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy>

## Commands

List all existing Pods:

```sh
kubectl get pods                 # for the current namespace
kubectl get pods -o wide         # also show nodes where Pods run on
kubectl get pods -n <namespace>  # for a different namespace
kubectl get pods -A              # for all namespaces
```

List containers inside a Pod:

```sh
kubectl get pod <pod-name> -o jsonpath="{range .spec.containers[*]}{.name}{'\n'}{end}"
```

See Pod logs:

```sh
k logs <pod-name>
```

Exec into a Pod/container:

```sh
kubectl exec -it <pod-name> -c <container-name> -- bash
kubectl debug -it <pod-name> --image=<debug-image> -- bash
```

### Forwarding Ports from Pods

You can forward ports from a single Pod to your local machine which these commands:

```sh
kubectl port-forward <container-name> <port>  # same port in container and host
kubectl port-forward <container-name> <localhost-port>:<container-port>
```

This port forwarding works even if `kubectl` is executed from within a [DevContainer](devcontainers.md).

> [!NOTE]
> If you try to forward a non-existing port (i.e. no service is listening on this port), you'll get a **connection refused** error when you try to use this port for the first time.

## Resource YAML

Apply via `kubectl apply -f <filename>`.

Helpful links:

* [Which defaults should be overridden?](https://github.com/BretFisher/podspec)

### Minimal Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx  # Pod name
spec:
  containers:
    - name: nginx  # container name
      image: nginx:1.29.0
```

> [!TIP]
> For details on container images, see the section [](#container-images) below.

### Extended Example

The extended example is based on: <https://github.com/BretFisher/podspec>

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: nginx
  namespace: my-namespace  # Which namespace to put this Pod into

spec:
  containers:
    - name: nginx
      image: nginxinc/nginx-unprivileged:1.29.0

      ports:  # Ports used by this container; this is mainly for documentation purposes
        - containerPort: 8080  # Is 8080 instead of 80 because Pod runs as non-root
          protocol: TCP

      readinessProbe:  # Tells Kubernetes when the container is ready
        httpGet:
          path: /
          port: 8080

      resources:
        requests:
          memory: "25Mi"  # Scheduler finds a node where 25MB RAM is available
          cpu: 0.25       # Scheduler finds a node where 0.25 CPU cores are available
        limits:
          memory: "50Mi"  # If the container more than 50MB RAM, it may get killed
          cpu: 2          # The container can use up to 2 CPU cores

      # Per-container security context
      securityContext:
        allowPrivilegeEscalation: false  # prevent sudo, etc.
        privileged: false                # prevent acting like host root

  terminationGracePeriodSeconds: 600 # default is 30, but you may need more time

  # Per-Pod security context
  securityContext:
    # Restrict system calls for containers. RuntimeDefault is the recommended option.
    seccompProfile:
      type: RuntimeDefault

    # Run containers as non-root
    runAsNonRoot: true
    runAsUser: 1001
    runAsGroup: 1001
```

## Resource Requests And Limits

For both requests and limits, you can specify `memory` and/or `cpu`.

### Resource Requests

**Resource requests** tell the Pod scheduler the minimum resources a container requires. The scheduler will only put the Pod on a node where these resources are free. (For this, it sums up all requests of all containers in the Pod.)

The scheduler won't put a Pod on a node where the Pods resource requests exceed the available resources. The available resources are reduced by the resource request amount of each Pod scheduled on that node.

To see the resource capacity (max resource amount) and the allocated resources (used resource amount), use:

```sh
# Look for "Capacity" and "Allocated resources"
kubectl describe node <node-name>
```

> [!NOTE]
> When scheduling a new Pod, the **scheduler *only* looks at resource *requests* - *not* at the *actual usage***. This is primarily important for `memory` because the amount of requested memory may not be available on a node (if the actual memory usage of the Pods running on this node far exceed their requested memory).

### Resource Limits

**Resource limits** are enforced by the Linux kernel and specify which resource limits must not be exceeded by the container.

A container can't exceed its cpu limit - the kernel prevents that by throttling the process(es) in the container.

If a container exceeds its memory limit, the kernel may kill it - if there is memory pressure on the node.

### Official documentation

* [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
* [CPU resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu)
* [Memory resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-memory)

## Container Images {#container-images}

Images for containers are pulled (=downloaded) from container registries.

Where the container images are pulled from exactly depends on the [container runtime](https://kubernetes.io/docs/setup/production-environment/container-runtimes/) used by Kubernetes. K3s and most other Kubernetes distributions use [containerd](https://containerd.io/) (by default) - which pulls images from [Docker Hub](https://hub.docker.com/) (by default).

### Image Names

Generally, image names are specified like this:

```
[REGISTRYHOST/]REPOSITORY[:TAG]
```

**Examples:**

```
nginx
nginx:latest
nginx:1.25
portainer/portainer-ce
mcr.microsoft.com/devcontainers/base:ubuntu
```

**Components:**

| Component      | Description
| -------------- | -----------
| `REGISTRYHOST` | Optional. The hostname of the container registry (e.g. `docker.io`, `ghcr.io`, `mcr.microsoft.com`).
| `REPOSITORY`   | Required. Typically formatted as `user/image-name` or just `image-name`.
| `TAG`          | Optional. Specifies the version and/or variant (e.g. `latest`, `v1.25`, `alpine`).

If no `REGISTRYHOST` is specified, the default registry is used. Which one this is, depends on the container runtime (see above). However, most of the time, Docker Hub is used (which is `docker.io` under the hood).

If no `TAG` is specified, `latest` is used.

The value for `REPOSITORY` is `group/image-name` for most registries - except for Docker Hub, which also accepts just `image-name` (which are the so called [official images](https://hub.docker.com/u/library)).

### Image Pull Policy

Whether an image is pulled from a container registry before running a Pod, depends on the `.spec.containers.imagePullPolicy` field.

It can have one of these three values: `Always`, `IfNotPresent`, and `Never`

The default value for `imagePullPolicy` is:

* `Always` for the `:latest` tag
* `IfNotPresent` for any other tag

> [!WARNING]
> This behavior is different from Docker. Docker never automatically pulls a `:latest` image once it has been downloaded. Kubernetes, on the other hand, always pulls a `:latest` image - even if it has already been downloaded.

### Diagnosing ImagePullBackOff and ErrImagePull

To figure out what the problem is when a Pod has the status `ImagePullBackOff` or `ErrImagePull`, use:

```sh
kubectl describe pod <pod-name>
```

In the **Events:** section you can see what's happening.

## Pod Execution

Pods - or their containers, to be more precise - are executed/started/stopped by the [kubelet process](../internals/kubelet-cri.md) running the Pod's node.

The kubelet process is also responsible for executing and monitoring the readiness and health probes for Pods running on its node.

## Pod Placement {#pod-placement}

Pods are assigned to their nodes by the [Kubernetes Scheduler](../internals/kubelet-cri.md#scheduler).

If you need to limit (or expand) the nodes, your Pod can be placed on, Kubernetes provides various ways to do this:

| Field                | Effect                                                            | Documentation
| -------------------- | ----------------------------------------------------------------- | -------------
| `.spec.nodeName`     | Place the Pod on a specific node.                                 | -
| `.spec.nodeSelector` | Place the Pod on nodes with specific labels.                      | [Assign Pods to Nodes](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/)
| `.spec.affinity`     | Attract the Pod to certain nodes or other pods - or the opposite. | [Affinity and anti-affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)
| `.spec.tolerances`   | Override Pod repelling rules.                                     | [Taints and Tolerances](../taints.md)
