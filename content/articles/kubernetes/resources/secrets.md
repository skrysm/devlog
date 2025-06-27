---
title: Secrets - Kubernetes Resources
description: Overview of Secrets in Kubernetes
date: 2025-08-01
topics:
- kubernetes
---

**Secrets** are a [built-in resource type](overview.md) in Kubernetes. They are similar to [ConfigMaps](configmaps.md) but they **store *confidential* data** in key-value pairs.

Pods can consume Secrets the same way as ConfigMaps - as environment variables, command-line arguments, or as configuration files in a volume.

> [!WARNING]
> While Secrets are designed to store confidential data, by default they are **no more secure than ConfigMaps** - unless you manually increase their security (see [](#security) below).
>
> **Instead of using Secrets directly, you should consider using [alternatives to Secrets](secrets-alternatives.md).**

See also: [Official Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)

## Resource YAML

> [!WARNING]
> **Do *not* store Secret resource YAML files in Git!!!**
>
> I'll just show their structure here in YAML so that you know how they're constructed. You *may* use them for testing purposes before using [other ways to store the secrets in Git](secrets-alternatives.md).

A Secret can be defined as string secret or binary secret.

**String Secret** - via `stringData`:

```yaml {hl_lines="6"}
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
stringData:
  DB_PASSWORD: super-secret-password
```

**Binary Secret** - via `data` (Base64 encoded):

```yaml {hl_lines="6"}
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  DB_PASSWORD: c3VwZXItc2VjcmV0LXBhc3N3b3Jk
```

> [!WARNING]
> Even though this secret looks garbled - **it is not encrypted!!!** It's [Base64](https://en.wikipedia.org/wiki/Base64) encoded - but that's just so that Secrets can support arbitrary binary data.

The type of these secrets is **Opaque** - meaning they can contain arbitrary data (i.e. their values are not interpreted by Kubernetes).

However, there are [other Secret types](https://kubernetes.io/docs/concepts/configuration/secret/#secret-types) that have special meaning in Kubernetes. Their values must conform to a predefined format (e.g. certain JSON structure) that's dictated by the type.

## Using Secrets

You can use Secrets just like you would use [ConfigMaps](configmaps.md#using).

Secrets just use different field names (basically you replace `configMap` with `secret`):

```yaml {hl_lines="15,20-21"}
apiVersion: v1
kind: Pod
metadata:
  name: secret-example
spec:
  containers:
    - name: nginx
      image: nginx:1.26.0
      volumeMounts:
        - name: secret-base64-data
          mountPath: /etc/config
      env:
        - name: ENV_VAR_FROM_SECRET
          valueFrom:
            secretKeyRef:
              name: base64-data
              key: foo
  volumes:
    - name: secret-base64-data
      secret:
        secretName: base64-data
```

> [!NOTE]
> Even though Secrets are internally stored Base64 encoded, Kubernetes will automatically decode them for the containers. So the **containers will see the actual value - not the Base64 encoded one**.

> [!TIP]
> If possible, it's recommended to **use Secrets mounted as file instead of as environment variable**. Because the values of all environment variables will be visible to anyone who has access to the `/proc` directory.

## Commands

List all existing Secrets:

```sh
kubectl get secrets                 # for the current namespace
kubectl get secrets -n <namespace>  # for a different namespace
kubectl get secrets -A              # for all namespaces
```

To see the keys and their Base64 encoded values of a Secrets:

```sh
kubectl get secret <config-map-name> -o yaml
```

To decode any secret:

```sh
kubectl get secret <secret-name> -o yaml | yq '.data.<key>' | base64 -d
```

## Security of Secrets inside the Cluster {#security}

> [!NOTE]
> This section talks about securing Secrets inside the Kubernetes cluster. It's *not* about how to securely store Secrets in Git.

As mentioned above, Secrets add very little in terms of security over ConfigMaps:

1. They are not stored encrypted on disk by default - but this can be enabled.
1. Anyone with read access to Secrets can decrypt them. (Since they are stored Base64 encoded, this at least prevents casual reading of secrets.)
1. Anyone who can create Pods can read all Secrets available to the Pod (by mounting them into the Pod).
1. Anyone who can execute into Pods can read all Secrets mounted into the Pod.

Regarding **point 1**, you can enable [**encryption at rest**](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) but it's a rather lengthy process. Alternatively, you could also use **full disk encryption (FDE)** for all Kubernetes servers - which is probably easier.

Regarding **point 2-4**, you can employ [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) to restrict which users read Secrets or create Pod. You can also restrict users to certain [Namespaces](namespaces.md).

You should probably also determine if you actually need any of these security mechanisms:

* **Encryption at Rest:**
  * If you have a Kubernetes cluster from a cloud provider, this may already be enabled - or you may not have the choice to enable it, if your provider doesn't support this.
  * In an on-premises cluster:
    * Is there a risk that someone is stealing just the server's data disks (but not the whole server that contains the encryption/decryption key)?
    * When replacing the server's data disks, do you shredder the old ones (physically or via a shred software) before disposing them?
* **RBAC:**
  * Do you have more than one user in your cluster? (If you just have one admin, they can read the secrets anyways.)

For more information, see also: [Good practices for Kubernetes Secrets](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
