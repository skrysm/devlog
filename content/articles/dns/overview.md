---
title: DNS Overview
description: An overview of the DNS.
topics:
- dns
date: 2025-08-16
---

The Domain Name System (DNS) is often described as the "phonebook of the Internet", translating human-friendly domain names into machine-readable IP addresses.

This article explains how DNS works in practice.

## DNS Requests and Responses {#protocol}

A DNS request asks the DNS server for [resource records](resource-records.md) of a certain record type (e.g., `A`, `AAAA`, `MX`).

The request contains the following fields:

* **QNAME** - Domain name
* **QTYPE** - Record type (e.g., `A`, `AAAA`, `MX`)
* **QCLASS** - Record class, usually `IN` (Internet)

The response can be one of three types:

* **Authoritative Answer** - a list of resource records for the requested record type. Note that for certain record types, you may get multiple results (e.g., multiple IP addresses, multiple `NS` records).
* **Referral** - the server doesn't know the answer but it knows a DNS server that might.
* **Error** - an error, for example `NXDOMAIN` if the domain name doesn't exist.

For the difference between "authoritative answer" and "referral", see [](#dns-resolving) below.

The DNS protocol uses both UDP and TCP on port 53. DNS clients first try to use UDP but fall back to TCP if the response is too large.

## Walking the DNS Hierarchy {#dns-resolving}

When a recursive DNS resolver (see [below](#recursive-resolvers)) tries to resolve a domain name, for example `wikipedia.org`, it first checks its cache.

If the requested domain (or, more precisely, the requested [resource record](resource-records.md)) is in its cache, it returns the record immediately.

If it's not cached, the resolver **walks the DNS hierarchy** - starting at the root domain (see [below](#root-domain)).

At each step, the resolver asks the DNS server for the requested record (e.g., the IP address for `wikipedia.org`). The response is either the exact answer or a referral to a DNS server for a subdomain of the current domain.

1. DNS resolver → root DNS server: "Give me the IP address for `wikipedia.org`."
1. DNS resolver ← root DNS server: "I don't know it but the DNS server of `.org` might know." (referral)
1. DNS resolver → `.org` DNS server: "Give me the IP address for `wikipedia.org`."
1. DNS resolver ← `.org` DNS server: "I don't know it but the DNS server of `wikipedia.org` might know." (referral)
1. DNS resolver → `wikipedia.org` DNS server: "Give me the IP address for `wikipedia.org`."
1. DNS resolver ← `wikipedia.org` DNS server: "I know it. Here is the IP address." (authoritative answer)

> [!NOTE]
> The `.org` DNS server only knows which DNS server is responsible for `wikipedia.org` (the `NS` record). It does not know the actual IP address of `wikipedia.org` (the `A` or `AAAA` record). To get the IP address, you must ask the DNS server for `wikipedia.org` itself. (This is because `wikipedia.org` is a [child zone](#child-zones) of `.org`, and so `.org` is not "authoritative" for `wikipedia.org`.)

## The Root Domain {#root-domain}

The **root domain** is the top of the DNS hierarchy, represented by a single dot (`.`). Every fully qualified domain name (FQDN) technically ends with this dot, even though it's usually omitted (e.g., `wikipedia.org.`).

**But how does a recursive resolver know the IP address of the root DNS servers?**

It uses the *"root hints file"* (usually built into recursive resolvers). This file contains the IP addresses and DNS names for all root domain servers:

* [Root servers as HTML page](https://www.iana.org/domains/root/servers)
* [Root servers as zone file](https://www.internic.net/domain/named.root)

There are 13 root servers (`a.root-servers.net` to `m.root-servers.net`). Each address is actually an [**anycast address**](https://en.wikipedia.org/wiki/Anycast), meaning there are dozens of servers behind each IP address.

Since these IP addresses are critical for the Internet, they **rarely change**, and changes are communicated months in advance. Even when they do change, recursive resolvers use "priming" to obtain an up-to-date list of all root server addresses.

Recursive resolvers often keep statistics about which root server has the best response time and select faster servers over slower ones.

See also:

* [Root server addresses - Wikipedia](https://en.wikipedia.org/wiki/Root_name_server#Root_server_addresses)
* [Root Files - iana.org](https://www.iana.org/domains/root/files)

## DNS Clients and Servers

When resolving a domain name to an IP address, various DNS software components are involved. All of them speak the [DNS protocol](#protocol), but they **use it differently** depending on their role.

### Stub Resolver (a.k.a. DNS Client) {#stub-resolvers}

**Lives in:** Your operating system (Windows, Linux, macOS, iOS, Android).

**Role:**

* Checks local caches (and hosts file).
* If it doesn't have the answer, it forwards the query to the DNS server configured in your operating system's network settings (usually your router).

**How it speaks DNS:** Sends a recursive query (`RD = 1`), essentially saying: *"Please do all the work and give me the final answer."*

**Key point:** The stub resolver never walks the DNS hierarchy itself — it always relies on someone else.

### Forwarders {#dns-forwarders}

**Lives in:** Consumer routers, some enterprise DNS appliances.

**Role:**

* Accepts queries from clients (stub resolvers).
* Does not do recursion itself. Instead, it forwards queries to an upstream recursive resolver (usually the ISP or a public resolver).
* Often caches answers locally for faster responses inside the LAN.

**How it speaks DNS:** Forwards requests upstream.

**Key point:** Think of it as a DNS "proxy". It looks like a resolver to clients but delegates the real work to someone else.

### Recursive Resolver: The Workhorse {#recursive-resolvers}

**Lives in:** ISP DNS servers, public DNS (Google `8.8.8.8`, Cloudflare `1.1.1.1`, etc.), or enterprise infrastructure.

**Role:**

* Accepts recursive queries from stubs or forwarders.
* If the answer is not cached, it walks the DNS hierarchy (see above).
* Caches results to speed up future lookups.

**How it speaks DNS:**

* Accepts recursive queries.
* Issues iterative queries (`RD = 0`) upstream.

**Key point:** This is the component that actually "does the legwork" of DNS resolution.

### Authoritative DNS Server: The Source of Truth {#authoritative-servers}

**Lives in:** DNS hosting providers, registrars, or self-managed DNS infrastructure.

**Role:**

* Stores and serves the official [records](resource-records.md) for a domain (A, AAAA, MX, etc.).
* Responds to queries with authoritative answers.
* Does not perform recursion.

**How it speaks DNS:**

* Replies with authoritative answers (`AA = 1`) for domains it manages.
* If asked about something outside its zone, it responds with either:
  * a referral — pointing to another nameserver (for a subdomain) that might have the answer.
  * or an error (`NXDOMAIN`) — indicating the name does not exist in its zone.

**Key point:** Authoritative servers never chase down other domains — they only know what they're authoritative for.

### Hybrid Configurations

In enterprise or homelab setups, you often see **split-brain or hybrid DNS**:

* The local DNS server (often Active Directory DNS, BIND, or Unbound) is **authoritative** for internal zones (e.g., `corp.local`, `internal.example.com`).
* For everything else (like `wikipedia.org`), the same server acts as a **forwarder or recursive resolver**.

This dual behavior allows:

* Control of internal name resolution.
* Seamless access to the public DNS system without requiring users to configure different resolvers.

### Putting It All Together

When resolving `example.com` on a home network:

1. **Stub Resolver (your OS)** - asks the DNS server set in your network config.
1. **Forwarder (home router)** - receives the query, checks local cache, and forwards it upstream.
1. **Recursive Resolver (ISP or public)** - walks the DNS hierarchy until it finds the answer.
1. **Authoritative Server (for example.com)** - provides the official IP address.

## DNS Zones

A DNS zone is the **list of all [DNS resource records](resource-records.md)** that belong to a certain domain (or subdomain).

A DNS zone may include child zones for one or more of its subdomains, but this is not required. The contents of a child zone do *not* count toward the parent zone; they're considered separate zones.

Each DNS zone must have at least one authoritative DNS server, but it's considered good practice to have at least two. Each DNS server is identified via its `NS` resource record (both in the zone itself and in the parent zone).

Historically, each DNS zone was simply defined by a [zone file](zone-files.md). So, two zone files = two zones.

### Primary and Secondary Servers

Each DNS zone has at least one authoritative DNS server, specified via the `SOA` [resource record](resource-records.md). This server is the *primary* DNS server.

Every other DNS server in the DNS zone - defined by `NS` resource records - is considered a *secondary*.

This distinction, however, only exists for the administrators of the DNS zone: They update the zone information only on the *primary* server, and all *secondary* servers get a copy of the zone information via a *zone transfer* (see below).

Recursive resolvers will only get a list of DNS servers and choose any of them. They don't care which is the primary and which is a secondary.

### Zone Transfers

A **zone transfer** is the mechanism by which *secondary* DNS servers synchronize themselves with their *primary* server.

Zone transfers only happen if a DNS zone has more than one DNS server.

When zone administrators want to update the DNS zone (e.g., add or change a resource record), they only update the primary server. All secondary servers then automatically download the DNS zone from the primary.

The secondary DNS servers find their primary by looking at the `SOA` resource record of the DNS zone. The first field in the resource data identifies the name of the primary DNS server.

Secondary DNS servers then get their copy of the DNS zone via a "regular" DNS request for resource records:

* **`AXFR` (Authoritative Transfer)** → This is a **full zone transfer**. \
  The secondary asks the primary for an `AXFR` record type, and the primary replies with the complete set of resource records for the zone.
* **`IXFR` (Incremental Transfer)** → This is an **incremental zone transfer**. \
  The secondary asks the primary for an `IXFR`, specifying the serial number it currently has. The primary replies with only the changes since that serial. If the primary can’t provide a differential update, it falls back to a full AXFR.

The process is usually triggered by a **NOTIFY** message:

* When the zone changes, the primary sends a **NOTIFY** (a special DNS message, not a record type) to secondaries.
* The secondary then queries the SOA record of the zone to check the **serial number**.
* If the serial is higher on the primary, the secondary starts a transfer (IXFR if possible, otherwise AXFR).

> [!NOTE]
> You can request these zone transfer records with `dig`:
>
> ```sh
> $ dig @<dns-server> <zone> AXFR
> $ dig @<dns-server> <zone> IXFR=<serial>
> ```
>
> Note, however, that most DNS servers **do not allow AXFR to arbitrary clients** — they restrict it to trusted secondaries (by IP, TSIG keys, etc.) for security reasons.

### Child Zones

A DNS zone may include child zones for one or more of its subdomains.

**A subdomain has its own child zone if it has its own `NS` record(s).**

For example, consider this `example.com` zone file:

```zone
; in-bailiwick child zone with glue records
sub1     IN NS   ns1.sub1.example.com.
sub1     IN NS   ns2.sub1.example.com.

ns1.sub1 IN A    203.0.113.10
ns2.sub1 IN A    203.0.113.11

; out-of-bailiwick child zone
sub2     IN NS   ns1.otherdns.net.
sub2     IN NS   ns2.otherdns.net.

; regular subdomain without child zone
sub3     IN A    203.0.113.12
```

Here, the subdomains `sub1.example.com` and `sub2.example.com` are both child zones, but `sub3.example.com` is not (it belongs to the parent zone).

When a child zone is defined:

* Your server will **stop being authoritative** for anything under `xyz.example.com` (except the NS and glue records).
* Queries for `something.xyz.example.com` will be referred to the nameservers listed in the NS records.
* The child zone will have its own zone file and SOA record on the other DNS server.

For child zones, there is also a distinction between **in-bailiwick** and **out-of-bailiwick** child zones (see [below](#bailiwick) for details on this word):

* **in-bailiwick** - The nameservers of the child zone are *inside* the parent domain. In this case, A/AAAA records for these nameservers must be provided in the parent zone (because NS records only map to domain names, not IP addresses). These A/AAAA records are called **glue records**.
* **out-of-bailiwick** - The nameservers of the child zone are *outside* the parent domain. No glue records are required/allowed.

When a recursive resolver asks the nameserver of the parent zone for a record in one of its child zones, the nameserver of the parent zone returns the NS records (and glue records) for that child zone. This response is called a **referral**, and the process of defining child zones is called **delegation**.

### Bailiwick {#bailiwick}

When reading about or working with DNS, you may run into the term **bailiwick**.

This is an actual English word meaning "district or jurisdiction of a bailiff".

In DNS, a domain name is **in-bailiwick** when it's a direct or indirect subdomain of another domain. The opposite is **out-of-bailiwick**. Both terms are defined in [RFC 7719: DNS Terminology](https://datatracker.ietf.org/doc/html/rfc7719).

For example, both `www.wikipedia.org` and `example.org` are **in-bailiwick** of `.org` - but `example.com` is not (it's in-bailiwick of `.com`).

The term "bailiwick" is used in two places:

* **Child zones** - The nameservers of child zones can be in-bailiwick or out-of-bailiwick.
* **Bailiwick checking** - A security measure: authoritative nameservers are only allowed to return in-bailiwick records ([more details](https://textbook.cs161.org/network/dns.html#325-dns-security-bailiwick)).

## Negative Caching {#negative-caching}

**Negative caching** is about remembering failures.

When you ask a DNS resolver for something that doesn't exist:

```sh
dig doesnotexist.example.com
```

... the resolver queries the [authoritative server](overview.md#authoritative-servers), which replies:

```
NXDOMAIN
```

By default, the resolver could immediately forget that result — but that would mean *every* time someone asks again, it would have to re-check with the authoritative server.

Negative caching says: "Let's remember that **this name doesn't exist** for a little while, so we don’t waste time asking again."

The negative caching TTL is defined by the [SOA record](zone-files.md#soa-record) of a DNS zone.
