---
title: NodePort - Services - Kubernetes Resources
description: Overview of NodePort Services in Kubernetes
date: 2025-07-28
topics:
- kubernetes
---

**NodePort** is one of four [Service types](services.md) in Kubernetes.

* [ClusterIP](services-clusterip.md)
* **NodePort**
* [LoadBalancer](services-loadbalancer.md)
* [ExternalName](external-services.md)

A NodePort is basically a ClusterIP that's externally accessible - by default on a random port from the NodePort range 30000 - 32767.

This port is **accessible on every Node** in the cluster - even on Nodes where no Pods of the Service are running.

You can manually select a fixed port - but it still needs to be taken from the NodePort range.

Since a NodePort is basically a ClusterIP under the hood, from inside your cluster, the NodePort Service is available on the port specified in the `.spec.ports.port` field - and it's also available under the `.spec.name` DNS name.

> [!NOTE]
> You typically don't use NodePorts. Instead, you'd use [LoadBalancers](services-loadbalancer.md).

See also:

* [Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)
* [](../network-encryption.md)

## Resource YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: echo-server-nodeport
spec:
  type: NodePort
  selector:
    app: echo-server
  ports:
    - port: 5678
```

The resource definition of a NodePort is almost identical the the resource definition of a ClusterIP. It creates a ClusterIP with TCP port 5678 and also exposes this port with a random port on every Node in the cluster.

## Use Case

For a production workload, NodePorts are **not very practical**. (However, [LoadBalancer](services-loadbalancer.md) Services build on top of NodePorts.)

The random port makes it hard to integrate them with other software and even when selecting a fixed port, it must still be in the NodePort range (by default: 30000 - 32767).

Also, NodePorts are only useful you can access the Kubernetes cluster over the network. For most cloud Kubernetes clusters, this is not normally the case.

It is, however, **useful for development, testing, or PoC scenarios** where you simply need manual access to a Deployment or Pod and don't care about the port.

## Load Balancing

Like a ClusterIP, a NodePort uses load-balancing. For more details, see [ClusterIP Load Balancing](services-clusterip.md#load-balancing).

> [!NOTE]
> When you test the load balancing with your browser, it may not work when you simply refresh the page.
>
> That's because, when just refreshing the page, your browser will **reuse the previous HTTP connection**. And since ClusterIP/NodePort load balancing works per-connection, when reusing a connection, your browser will always **connect to the same Pod**.
>
> You can usually hit Ctrl+Shift+R to force your browser to establish a new HTTP connection and then you'll get connected with a different Pod.
