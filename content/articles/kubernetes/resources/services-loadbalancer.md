---
title: LoadBalancer - Services - Kubernetes Resources
description: Overview of LoadBalancer Services in Kubernetes
date: 2025-07-28
topics:
- kubernetes
---

**LoadBalancer** is one of four [Service types](services.md) in Kubernetes.

* [ClusterIP](services-clusterip.md)
* [NodePort](services-nodeport.md)
* **LoadBalancer**
* [ExternalName](external-services.md)

A LoadBalancer Service is the primary way of getting external traffic into a Kubernetes cluster.

Conceptually, a LoadBalancer Service creates a NodePort Service and then instructs an external load balancer to load balance network traffic across all Nodes in the cluster.

This also means that Kubernetes does *not* provide an implementation of the external load balancer. The idea here is that the load balancer is provided by the cloud provider (Google Cloud, AWS, Azure, ...) and the LoadBalancer resource is just the interface to the cloud provider.

After you've created a LoadBalancer Service, an external load balancer will be provisioned automatically. Once this is done, it will provide one or more external IP addresses for the Service:

```sh
$ kubectl get svc
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
echo-server-lb          LoadBalancer   10.43.222.141   212.2.241.35     5678:31898/TCP   5m
```

While the new external load balancer is not yet fully created, the external IP address will be listed as "pending":

```sh
$ kubectl get svc
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
echo-server-lb          LoadBalancer   10.43.222.141   <pending>        5678:31898/TCP   6s
```

If a Kubernetes cluster isn't configured to support an external load balancer, the service's external IP address will be stuck in `<pending>` indefinitely. This problem mainly exists in on-premises clusters.

> [!NOTE]
> Some external load balancers do not create NodePorts but work directly with Pods.

See also:

* [Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)
* [](../network-encryption.md)

## Resource YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: echo-server-lb
spec:
  type: LoadBalancer
  selector:
    app: echo-server
  ports:
    - port: 5678
```

This creates a load balancer for TCP port 5678.
