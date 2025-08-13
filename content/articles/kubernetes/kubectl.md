---
title: kubectl
description: Overview of kubectl
date: 2025-06-27
topics:
- kubernetes
---

`kubectl` is the primary command line interface to interact (i.e. create [resources](resources/overview.md), view logs, ...) with a Kubernetes cluster.

Base format:

```sh
kubectl <command> <type> -n <namespace> -o <format>
```

`<type>` is a [resource type](resources/overview.md) and can specified in either:

* singular form (`kubectl get namespace`)
* plural form (`kubectl get namespaces`)
* [abbreviated form](https://kubernetes.io/docs/reference/kubectl/#resource-types) (`kubectl get ns`)

If `-n <namespace>` isn't specified, the [current namespace](resources/namespaces.md) is used.

With `-o` you can specify if you want the output as JSON or YAML.

Examples:

```sh
kubectl get nodes
kubectl get pods
kubectl apply -f <file>
```

> [!TIP]
> Many people create an `alias k=kubectl` for their machine so that they can say `k get pods` instead of `kubectl get pods`.

## Connecting to a Cluster {#kube-config}

Which Kubernetes cluster `kubectl` connects to is define in the **kubeconfig file**.

The location of this file is (unless overridden via the `$KUBECONFIG` environment variable or the `--kubeconfig` parameter):

    ~/.kube/config

The kubeconfig file contains:

* **Clusters** – definitions of one or more clusters (API server URL and TLS certificate info)
* **Users** – authentication info for connecting to those clusters (private and public certificate key, username and password, bearer token, ...)
* **Contexts** – combinations of a cluster and a user (and optionally a [namespace](resources/namespaces.md)).
* **Current context** – tells kubectl which context to use.

To check the current context:

```sh
kubectl config current-context
```

To list all contexts:

```sh
kubectl config get-contexts
```

To switch context:

```sh
kubectl config use-context <context-name>
```

See also:

* [Official Documentation - Organizing Cluster Access Using kubeconfig Files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)
* [Official Documentation - Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
* [Official Documentation - kubeconfig specification](https://kubernetes.io/docs/reference/config-api/kubeconfig.v1/)
* [Official Documentation - Authenticating](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)

### How kubectl chooses the cluster

1. **Checks the current context** in the kubeconfig file:

   ```yaml
   current-context: my-cluster-context
   ```

1. **Finds the context** by name in the contexts list:

   ```yaml
   contexts:
   - name: my-cluster-context
     context:
       cluster: my-cluster
       user: my-user
   ```

1. **Finds the matching cluster and user**:

   ```yaml
   clusters:
   - name: my-cluster
     cluster:
       server: https://192.168.1.100:6443
       certificate-authority: /path/to/ca.crt

   users:
   - name: my-user
     user:
       client-certificate: /path/to/user.crt
       client-key: /path/to/user.key
   ```

So, the active **context** points to a **cluster** and a **user**, which defines where and how `kubectl` connects.

## Links

* [Official documentation](https://kubernetes.io/docs/reference/kubectl/)
* [Installing kubectl](https://kubernetes.io/docs/tasks/tools/)
