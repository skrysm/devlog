---
title: Network Encryption in Kubernetes
description: Details what network traffic is encrypted in Kubernetes by default
date: 2025-07-31
topics:
- kubernetes
- networking
- security
---

In Kubernetes, **not all network traffic is encrypted** by default. What is actually encrypted depends on the Kubernetes cluster you're using.

| Traffic Type              | Encrypted by Default | Notes
| ------------------------- | -------------------- | -----
| `kubectl` ↔ API Server    | ✅ Yes               | Always TLS (unencrypted HTTP support was [removed in v1.21](https://github.com/kubernetes/kubernetes/issues/91506))
| API Server ↔ Kubelets     | ✅ Yes               | Most likely via TLS (couldn't find any information on this)
| Pod ↔ Pod (across nodes)  | ❌ No                | Depends on CNI plugin
| Node ↔ Node               | ❌ No                | Depends on CNI plugin
| etcd                      | ✅/❌ Varies         | Often TLS

> [!TIP]
> See [](terminology.md) for some of those names.
