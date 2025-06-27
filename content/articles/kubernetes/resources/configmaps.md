---
title: ConfigMaps - Kubernetes Resources
description: Overview of ConfigMaps in Kubernetes
date: 2025-07-31
topics:
- kubernetes
---

**ConfigMaps** are a [built-in resource type](overview.md) in Kubernetes. They **store non-confidential data in key-value pairs**.

Pods can consume ConfigMaps as environment variables, command-line arguments, or as configuration files in a volume.

With ConfigMaps you can decouple environment-specific configuration from your container images, so that your applications are easily portable between environments (e.g. production and staging).

> [!WARNING]
> **ConfigMaps do not provide secrecy or encryption.** If you need to store confidential/secret data, use a [Secret](secrets.md) instead.

*Additional notes:*

* A ConfigMap is not designed to hold large chunks of data. The data stored in a ConfigMap cannot exceed 1 MiB.
* Multiple Pods can reference the same ConfigMap.

See also: [Official Documentation](https://kubernetes.io/docs/concepts/configuration/configmap/)

## Resource YAML

There are two primary styles how to define a ConfigMap.

**Property-like keys:**

```yaml {hl_lines="6-8"}
apiVersion: v1
kind: ConfigMap
metadata:
  name: property-like-keys
data:
  NAME: MyApp
  VERSION: 1.2.3
  AUTHOR: Me
```

Here each key (`NAME`, `VERSION`, `AUTHOR`) maps to a simple value.

**File-like keys:**

``` {hl_lines="6-12"}
apiVersion: v1
kind: ConfigMap
metadata:
  name: file-like-keys
data:
  game.properties: |
    enemy.types=aliens,monsters
    player.maximum-lives=5
  user-interface.properties: |
    color.good=purple
    color.bad=yellow
    allow.textmode=true
```

Here, each key (`game.properties`, `user-interface.properties`) maps to a multi-line string (think: file contents).

The **property-like** style is mainly used, if the container uses environment variables or command-line arguments for configuration.

The **file-like** style is mainly used, if the container uses config files for configuration.

If needed, you can also mix both styles inside the same ConfigMap (see [an example](https://kubernetes.io/docs/concepts/configuration/configmap/#configmaps-and-pods)).

> [!NOTE]
> **Kubernetes does not parse the values** inside a ConfigMap. It especially doesn't interpret the values of file-like keys. It only handles/interprets the keys. (This becomes clear when we look at how ConfigMaps are used in Pods below.)

## Using ConfigMaps {#using}

There are three ways to consume a ConfigMap:

* **Environment variables**  -- The container is configured via environment variables.
* **Files**                  -- The container is configured via config files.
* **Command-line arguments** -- The container is configured via command-line arguments.

### As Environment Variables {#using-env}

The simplest way to use a ConfigMap as environment variables is like this - via `.spec.containers.envFrom`:

```yaml {hl_lines="9-11"}
apiVersion: v1
kind: Pod
metadata:
  name: configmap-example
spec:
  containers:
    - name: nginx
      image: nginx:1.26.0
      envFrom:
        - configMapRef:
            name: my-config-map
```

This will simply **map every key from `my-config-map`** to an environment variable.

> [!TIP]
> It's recommended to use **property-like keys** for environment variables.
>
> You *could* use file-like keys but they almost always contain line breaks - and when the values contain line breaks, things will get weird.

You can also **select only certain keys** from the ConfigMap (and even rename them) - via `.spec.containers.env.valueFrom`:

```yaml {hl_lines="9-15"}
apiVersion: v1
kind: Pod
metadata:
  name: configmap-example
spec:
  containers:
    - name: nginx
      image: nginx:1.26.0
      env:
        - name: PLAYER_INITIAL_LIVES # Notice that the case is different here
                                     # from the key name in the ConfigMap.
          valueFrom:
            configMapKeyRef:
              name: my-config-map       # The ConfigMap this value comes from.
              key: player_initial_lives # The key to fetch.
```

> [!NOTE]
> If you change the ConfigMap while the consuming Pod is running, **changes will *not* propagate into the Pod**. You need to restart the Pod to get the updated values.

> [!TIP]
> To see all environment variables, execute `printenv` inside the container.

### As Files {#using-volume}

For this, you first define a volume with the config map as source (lines 14-17) and then map this volume into the container (lines 9-12):

```yaml {lineNos=true,hl_lines="9-12,14-17"}
apiVersion: v1
kind: Pod
metadata:
  name: configmap-example
spec:
  containers:
    - name: nginx
      image: nginx:1.26.0
      volumeMounts:
        - name: config
          mountPath: /config
          readOnly: true
  # You define volumes at the Pod level, then mount them into containers inside that Pod.
  volumes:
    - name: config
      configMap:
        name: my-config-map
```

This will **mount every key as a file** with with its value as content - under the directory `/config` inside the `nginx` container.

> [!TIP]
> It's recommended to use **file-like keys** for this - but property-like keys work fine as well (the files will just have one line).

You can also **select only certain keys** from the ConfigMap - but you have to define their path/filename in this case:

```yaml {lineNos=true,hl_lines="11-15"}
apiVersion: v1
kind: Pod
metadata:
  name: configmap-example
spec:
  ...
  volumes:
    - name: config
      configMap:
        name: my-config-map
        items:
          - key: "game.properties"  # key from ConfigMap
            path: "game.properties"  # file name on "disk"
          - key: "user-interface.properties"
            path: "user-interface.properties"
```

> [!TIP]
> Unlike with environment variables, **changes to the ConfigMap will propagate into the Pod** while the Pod is running.
>
> However, there is a "significant" delay before the files are updated. This **delay is up to 1 minute** - defined by the [Kubelet's `syncFrequency` setting](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration).

### As Command-Line Arguments {#using-cli-args}

To use a ConfigMap for command-line arguments, you **first need to map the ConfigMap [as environment variables](#using-env)**. You can then reference these environment variables in the containers `command` or `args` field.

**Command** and shell expands `LOG_LEVEL`:

```yaml {lineNos=true,hl_lines="4,6,17,20"}
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-example
data:
  LOG_LEVEL: Error
---
apiVersion: v1
kind: Pod
metadata:
  name: configmap-command-example
spec:
  restartPolicy: Never
  containers:
    - name: myapp
      image: busybox
      command: ["sh", "-c", "echo Starting with log level $LOG_LEVEL"]
      envFrom:
        - configMapRef:
            name: configmap-example
```

**Args** and Kubernetes expands `LOG_LEVEL`:

```yaml {lineNos=true,hl_lines="4,6,18,21"}
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-example
data:
  LOG_LEVEL: Error
---
apiVersion: v1
kind: Pod
metadata:
  name: configmap-command-example
spec:
  restartPolicy: Never
  containers:
    - name: myapp
      image: busybox
      command: ["echo"]
      args: ["Starting with log level $(LOG_LEVEL)"]
      envFrom:
        - configMapRef:
            name: configmap-example
```

## Commands

List all existing ConfigMaps:

```sh
kubectl get configmaps         # for the current namespace
kubectl get cm                 # same; abbreviated name
kubectl get cm -n <namespace>  # for a different namespace
kubectl get cm -A              # for all namespaces
```

To see the keys and their values of a ConfigMap:

```sh
kubectl get configmap <config-map-name> -o yaml
```

## The "kube-root-ca.crt" ConfigMap

Kubernetes automatically creates a ConfigMap named `kube-root-ca.crt` in every [Namespace](namespaces.md).

This ConfigMap contains a single key - `ca.crt` - that contains the TLS root certificate used by Kubernetes to secure all communication with its API server.

It's intended to be file mounted by Pods that need to communicate with the Kubernetes API server (for example custom resource controllers).
