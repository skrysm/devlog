---
title: Services - Kubernetes Resources
description: Overview of Services in Kubernetes
date: 2025-07-24
topics:
- kubernetes
---

The resource type **Service** is a [built-in resource type](overview.md) in Kubernetes. It's purpose is to route network traffic to Pods.

Services work on **layer 4** of the [network stack](https://en.wikipedia.org/wiki/OSI_model) - i.e. at the TCP/UDP level. The [Ingress](ingress.md) resource, on the other hand, works on **layer 7** - specifically with HTTP(S).

There are four **Service types**:

* [ClusterIP](services-clusterip.md) - load balanced IP address, only reachable from within the cluster.
* [NodePort](services-nodeport.md) - exposes the service on each Node at a static port.
* [LoadBalancer](services-loadbalancer.md) - integrates with cloud providers to provision external load balancers.
* [ExternalName](external-services.md) - provides an in-cluster DNS name for an external DNS name (less commonly used).

This list is hardcoded into Kubernetes and can't be extended by plugins.

**Internal DNS name**: `<service-name>.<namespace>.svc.cluster.local`

**Official Documentation:** <https://kubernetes.io/docs/concepts/services-networking/service/>

## Commands

List all existing Services:

```sh
kubectl get services            # for the current namespace
kubectl get svc                 # same; abbreviated name
kubectl get svc -n <namespace>  # for a different namespace
kubectl get svc -A              # for all namespaces
```

List all existing [Endpoints](#endpoints):

```sh
kubectl get endpoints          # for the current namespace
kubectl get ep                 # same; abbreviated name
kubectl get ep -n <namespace>  # for a different namespace
kubectl get ep -A              # for all namespaces
```

## Ports

No matter what Service type, Service resources *always* require **at least one port**.

**Simplest form:**

```yaml
apiVersion: v1
kind: Service
...
spec:
  ...
  ports:
    - port: 8080  # same external and Pod port
```

Here, the external port and the Pod port are the same; i.e. you can access this service via TCP port 8080 and it'll connect to port 8080 inside the Pod backed by this service.

**Different ports:**

```yaml
apiVersion: v1
kind: Service
...
spec:
  ...
  ports:
    - port: 8080        # external port
      targetPort: 5678  # Pod port
```

Here, the external port is still TCP 8080, but this port will map to port 5678 inside the Pod.

**UDP port:**

```yaml
apiVersion: v1
kind: Service
...
spec:
  ...
  ports:
    - port: 1234
      protocol: UDP
```

By default, ports are TCP. Here, you specify an UDP port.

**Multiple ports:**

```yaml
apiVersion: v1
kind: Service
...
spec:
  ...
  ports:
  ports:
    - name: http   # name is required
      port: 80
    - name: https  # name is required
      port: 443
```

If you specify multiple port, each port requires a name. The name must be lower-case.

## Endpoints {#endpoints}

Kubernetes ([normally](external-services.md#ClusterIP-with-ManualEndpoint)) automatically creates Endpoints for each Service. The Endpoints for a Service are **the actual list of Pods** the Service is connected to.

The name of the Endpoint resource must/will always match the name of the Service resource it belongs to.

See this example:

```sh
$ kubectl get services
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)     AGE
echo-server-clusterip   ClusterIP      10.43.139.219   <none>            8080/TCP    10s

$ kubectl get endpoints
NAME                    ENDPOINTS                                         AGE
echo-server-clusterip   10.42.0.56:5678,10.42.1.71:5678,10.42.1.72:5678   21s
```

When you just query the Services, you don't see which Pods the Services connect to. However, when you query the Endpoints, you see exactly that the Service `echo-server-clusterip` is backed by three Pods.

> [!TIP]
> The Endpoints API is helpful, for example, if you accidentally specified the **wrong selector** in your Service definition.
>
> In this case, the Service exists but can't be accessed because it's not backed by any Pods:
>
> ```sh
> $ kubectl get endpoints
> NAME                    ENDPOINTS     AGE
> echo-server-clusterip   <none>        4s
> ```

### EndpointSlices

When you read the official documentation, you may encounter the word **EndpointSlice**.

The EndpointSlice resource is basically an improved and more efficient version of the Endpoint resource.

Nowadays, Kubernetes will actually *not* create Endpoints anymore but will create EndpointSlices instead.

However, the Endpoints API still works (and probably will continue to work in the foreseeable future); each returned Endpoint is simply a read-only view of the actual EndpointSlice.

You can query EndpointSlices with `kubectl`. Here's a comparison with Endpoints:

```sh
$ kubectl get endpoints
NAME                    ENDPOINTS                                         AGE
echo-server-clusterip   10.42.0.56:5678,10.42.1.71:5678,10.42.1.72:5678   12m

$ kubectl get endpointslices
NAME                          ADDRESSTYPE   PORTS     ENDPOINTS                          AGE
echo-server-clusterip-x58dv   IPv4          5678      10.42.0.56,10.42.1.71,10.42.1.72   12m
```

See also: [Official Documentation](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)
