---
title: ClusterIP - Services - Kubernetes Resources
description: Overview of ClusterIP Services in Kubernetes
date: 2025-07-24
topics:
- kubernetes
---

**ClusterIP** is one of four [Service types](services.md) in Kubernetes.

* **ClusterIP**
* [NodePort](services-nodeport.md)
* [LoadBalancer](services-loadbalancer.md)
* [ExternalName](external-services.md)

ClusterIPs make your Pods available to other [Pods](pods.md) in your cluster.

It does this by providing an **internal, stable, load-balanced IP address and DNS name** for a set of Pods (most of the time for a [Deployment](deployments.md)):

* *Internal:* the IP address is only reachable from within the cluster.
* *Stable:* the IP address is long-lived and won't change - unlike the IP addresses of Pods which are short-lived and may change.
* *Load-balanced:* the network traffic to this IP address is distributed equally across all Pods that belong to the ClusterIP-Service.

See also:

* [Official Documentation - Overview](https://kubernetes.io/docs/concepts/services-networking/service/#type-clusterip)
* [Official Documentation - Service ClusterIP allocation](https://kubernetes.io/docs/concepts/services-networking/cluster-ip-allocation/)
* [](../network-encryption.md)

## Resource YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: echo-server-clusterip  # DNS name
spec:
  type: ClusterIP
  selector:
    app: echo-server
  ports:
    - protocol: TCP
      port: 8080        # Port for ClusterIP
      targetPort: 5678  # Port inside the Pod
```

With this resource definition, Kubernetes will:

* create a *random*, **virtual IP address** inside the cluster
* that routes the network traffic for **port 8080**
* to **port 5678**
* of any Pod that has the label `app: echo-server`.

Kubernetes will also make this IP address available under the DNS name `echo-server-clusterip.<namespace>.svc.cluster.local`. For Pods within the same [Namespace](namespaces.md), the IP address will also be available under the DNS name `echo-server-clusterip`.

If you make changes to the resource YAML and then re-apply it, the IP address will *not* change.

Multiple ClusterIP services can have the same port (here: `8080`).

## ClusterIP Load Balancing {#load-balancing}

A ClusterIP load-balances **network connections**.

This means, the target Pod is chosen for each new TCP/UDP/ICMP/... connection. Packets that belong to the same connection will always be routed to the same pod. A connection is identified by this 5-tuple (where `protocol` is TCP, UDP, ICMP, ...):

    (source IP, source port, destination IP, destination port, protocol)

By default, the load balancing choses a **random** Pod as target - but this can be configured at the cluster level.

### Load Balancing Details (kube-proxy)

For your regular work with Kubernetes you do *not* need to know how the ClusterIP load balancing works internally. If this doesn't interest you, you can skip this section.

Most Kubernetes clusters use [kube-proxy](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/) to implement ClusterIP load balancing.

For each new ClusterIP, kube-proxy configures the Linux kernel via [iptables](https://en.wikipedia.org/wiki/Iptables) (usually the default) or [IVPS](https://en.wikipedia.org/wiki/IP_Virtual_Server) to do a load balanced routing.

> [!NOTE]
> Despite the word "proxy" in "kube-proxy", network traffic does *not* go through the kube-proxy process. Routing is done by the Linux kernel.

This routing works via **Destination NAT** (DNAT): For each packet of a connection to the ClusterIP address, the kernel changes the destination IP address from the ClusterIP address to the IP address of the target Pod.

> [!NOTE]
> Yes, this uses the IP address of the target *Pod* - not the target *Node*.
>
> In Kubernetes, every Pod is directly reachable via its IP address through the [*pod network*](https://kubernetes.io/docs/concepts/services-networking/) (a.k.a. cluster network).
>
> This pod network is implemented via the magic of [CNI](https://github.com/containernetworking/cni) (Container Network Interface).

The target Pod is **chosen randomly**.

For a given ClusterIP-Service, you can see this yourself by ssh-ing into any node of your cluster.

Say, you have a ClusterIP-Service with name `echo-server-clusterip` in the `testing` namespace (for an example, [see below](#demo-app)). You can then run:

```sh
iptables -t nat -L -n | grep KUBE-SVC
```

You should see a line like (notice `testing/echo-server-clusterip` in the line):

```
KUBE-SVC-EF6QQNEDGUCXH6TD  6    --  0.0.0.0/0            10.43.134.253        /* testing/echo-server-clusterip cluster IP */ tcp dpt:8080
```

With this, you can run:

```sh
$ iptables -t nat -L KUBE-SVC-EF6QQNEDGUCXH6TD -n --line-numbers
Chain KUBE-SVC-EF6QQNEDGUCXH6TD (1 references)
num  target     prot opt source               destination
1    KUBE-MARK-MASQ  6    -- !10.42.0.0/16         10.43.134.253        /* testing/echo-server-clusterip cluster IP */ tcp dpt:8080
2    KUBE-SEP-OCROO4CKUGE2RS3Z  0    --  0.0.0.0/0            0.0.0.0/0            /* testing/echo-server-clusterip -> 10.42.0.49:5678 */ statistic mode random probability 0.33333333349
3    KUBE-SEP-BVKDY2MCK3ZCK2TS  0    --  0.0.0.0/0            0.0.0.0/0            /* testing/echo-server-clusterip -> 10.42.1.63:5678 */ statistic mode random probability 0.50000000000
4    KUBE-SEP-XTMO5XT2DVXLF33I  0    --  0.0.0.0/0            0.0.0.0/0            /* testing/echo-server-clusterip -> 10.42.1.64:5678 */
```

At the end of lines 2 and 3 (the `num` column) you'll see:

* Line 2: `statistic mode random probability 0.33333333349`
* Line 3: `statistic mode random probability 0.50000000000`

These lines are executed in order. So this means:

1. Line 2 (Pod 1) is chosen for 33% of all connections. (3 pods to choose from)
1. If line 2 wasn't chosen, line 3 (Pod 2) is chosen for 50% of all connections. (2 pods to choose from)
1. If line 3 wasn't chosen, line 4 (Pod 3) is used. (1 pod to choose from)

This means, each Pod gets roughly 33% of all connections.

### Load Balancer Test Deployment {#demo-app}

To test this yourself, you can apply this resource file to your cluster:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: echo-server
  template:
    metadata:
      labels:
        app: echo-server
    spec:
      containers:
        - name: echo-server
          image: hashicorp/http-echo
          args:
            - "-text=Hello from $(POD_NAME) at $(POD_IP)"
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: echo-server-clusterip
spec:
  type: ClusterIP
  selector:
    app: echo-server
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 5678
```

You then execute a helper pod to get you inside the cluster:

```sh
kubectl run nettools-pod -it --rm --image=skrysm/nettools
```

This will give you a command line. You then run:

```sh
curl http://echo-server-clusterip:8080
```

If you execute this command multiple times, you'll see how you get a response from a random Pod.

When you're done, hit Ctrl+D to terminate the helper pod.

## Headless Service: ClusterIP without IP address {#headless-service}

A headless Service allows a client to connect to whichever Pod it prefers, directly.

You can create a headless Service by setting `spec.clusterIP` to `None`:

```yaml {hl_lines="7"}
apiVersion: v1
kind: Service
metadata:
  name: echo-server-clusterip
spec:
  type: ClusterIP
  clusterIP: None  # must be "None" - not "none"!
  selector:
    app: echo-server
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 5678
```

With this, the ClusterIP-Service no longer gets a load-balanced IP address:

```sh
$ kubectl get services
NAME                    TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
echo-server-clusterip   ClusterIP   None         <none>        8080/TCP   88s
```

However, the **DNS response for the service name changes.**

For a regular ClusterIP, the DNS server returns a single IP address - the ClusterIP:

```sh
$ host echo-server-clusterip
echo-server-clusterip.testing.svc.cluster.local has address 10.43.134.253
```

For a headless service, the DNS server returns the IP addresses of all Pods backing the ClusterIP-Service:

```sh
$ host echo-server-clusterip
echo-server-clusterip.testing.svc.cluster.local has address 10.42.1.68
echo-server-clusterip.testing.svc.cluster.local has address 10.42.0.54
echo-server-clusterip.testing.svc.cluster.local has address 10.42.1.67
```

This can be useful for clients that need to do **DNS based load balancing** or for tools that need to **access all pods** of a Service (for example for collecting metrics from all Pods).

In most cases, however, headless Services are used together with [StatefulSets](stateful-sets.md). With StatefulSets (but not with [Deployments](deployments.md) or [ReplicaSets](replica-sets.md)), you can even query the IP address of individual Pods:

```
<pod-name>.<headless-service>.<namespace>.svc.cluster.local
```

> [!NOTE]
> ClusterIPs can also be used to [integrate external services in Kubernetes](external-services.md). For this, you need to remove the `.spec.selector` field.

See also: [Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)

## Static ClusterIP

You can use the `.spec.clusterIP` to assign a fixed ClusterIP to a ClusterIP-Service.

However, in almost all cases **you do *not* use a fixed ClusterIP**.

I'm just mentioning this here for the sake of completeness.

You can read more about this topic in the [official documentation](https://kubernetes.io/docs/concepts/services-networking/cluster-ip-allocation/).
