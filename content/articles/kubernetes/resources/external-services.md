---
title: Integrate External Services with Kubernetes
description: Describes how to integrate external services with Kubernetes
date: 2025-07-28
topics:
- kubernetes
---

Kubernetes provides two way to integrate external services into your Kubernetes cluster.

An external service is a service that doesn't run within your cluster; for example, a database provided by your database team or cloud provider.

"Integrate" means that you specify an in-cluster DNS name for that external service, for example: `external-db.default.svc.cluster.local`.

If you have the exact IP addresses of your external service and you have more than one IP address, Kubernetes can also do load balancing for this external service.

What Kubernetes resource you use, depends on what you have:

* **DNS name:** If you have a DNS name for your external service, you use [](#ExternalName).
* **IP address(es):** If you have one or more IP addresses, you use [](#ClusterIP-with-ManualEndpoint).

## ExternalName: Map DNS Name {#ExternalName}

If you have a DNS name for an external service, you use **ExternalDNS** to map this name to an in-cluster DNS name:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.example.com
  ports:
    - port: 5432
```

This will make `db.example.com` available under the DNS name `external-db`.

For example, with this, you can easily select the database address depending on your environment - without needing to change the application:

* `db.dev.example.com` in dev
* `db.example.com` in prod

See also: [Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/#externalname)

## ClusterIP with Manual Endpoint: Map IP Addresses {#ClusterIP-with-ManualEndpoint}

If you have the IP address (or addresses) for you external service, you use [**ClusterIP**](services-clusterip.md) to map them to an in-cluster DNS name and, optionally, a ClusterIP.

The important thing here is that you **do *not* specify a `.spec.selector`** for the ClusterIP.

You also need to manually define an Endpoint resource.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-api
spec:
  ports:
    - port: 80
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-api  # must match the Service name above
subsets:
  - addresses:
      - ip: 203.0.113.1  # only IP addresses are allowed here, no DNS names
      - ip: 203.0.113.2
    ports:
      - port: 80
```

With this resource definition, you get a **ClusterIP that [load balances](services-clusterip.md#load-balancing) all TCP connections** across the specified IP addresses. You also get a DNS name (here: `external-api`) for that ClusterIP.

Alternatively, you can also define the **ClusterIP as [headless service](services-clusterip.md#headless-service)** (by settings  `spec.clusterIP` to `None`). In this case, you only get a DNS name but when you query it, you get back all the IP addresses specified in the Endpoint resource.

> [!NOTE]
> Normally, Kubernetes creates Endpoint resources automatically. It doesn't do so in this case, because we didn't specify a selector for the ClusterIP. Because of this, we have to specify the Endpoint manually here.
>
> Kubernetes matches Endpoints with their Services by their name (here: `external-api`).
>
> Also note that Endpoints *without* Services make no sense in Kubernetes.
