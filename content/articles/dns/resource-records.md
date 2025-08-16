---
title: DNS Resource Records
description: An overview of DNS resource records (RR).
topics:
- dns
date: 2025-08-16
---

**Resource records (RRs)** are at the core of DNS. They are what DNS clients request. Most of the time, you ask for a record that maps a domain name to an IP address (an A or AAAA record), but there are many other record types. On DNS servers, resource records are typically defined in a [zone file](zone-files.md).

## Basic Structure

For example, a resource record mapping `wikipedia.org` to its IP address looks like this (output from `dig wikipedia.org`):

```zone
wikipedia.org.          13      IN      A       185.15.59.224
```

A resource record consists of the following fields, in order:

| Name       | Meaning      | Here
| ---------- | ------------ | ----------
| **NAME**   | Domain name  | `wikipedia.org.`
| **TTL**    | Time to live (in seconds); specifies how long a DNS client should cache this record before querying the server again. | `13`
| **CLASS**  | Group/Namespace of the *record type*; usually `IN` (Internet). Other classes exist but are rare. | `IN`
| **TYPE**   | Record type (e.g., `A` for IPv4 address, `AAAA` for IPv6 address, `MX` for mail server) | `A`
| **RDATA**  | Type-specific data (e.g., an IPv4 address for `A`, mail server name for `MX`). Can be more than one value. | `185.15.59.224`

> [!NOTE]
> The **record name** `wikipedia.org.` ends with a dot (`.`), which represents the **root domain** (above `.com`, `.net`, etc.). See [DNS resolving](overview.md#root-domain) for details.
>
> A name ending with a dot is **absolute**. Names without a trailing dot are **relative** and appear mainly in configuration files (such as [zone files](zone-files.md)). **On the wire, all names are absolute.**

## Record Types

The `IN` resource class [defines many record types](https://en.wikipedia.org/wiki/List_of_DNS_record_types). In practice, you'll most often encounter these:

| Record&nbsp;Type  | Description
| ----------------- | -----------
| `A`               | Maps a DNS name to an IPv4 address
| `AAAA`            | Maps a DNS name to an IPv6 address
| `CNAME`           | Maps a DNS name to another DNS name (alias)
| `MX`              | Specifies the SMTP server for a domain or subdomain
| `TXT`             | Stores free-form text for a DNS name; used for things like the [ACME DNS01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)
| `SOA`             | "Start of authority"; contains administrative info about a [DNS zone](overview.md#dns-zones). Each zone must have one.
| `NS`              | Specifies an [authoritative DNS server](overview.md#authoritative-servers) for a DNS zone. This is always a DNS name, never an IP address. Each zone should have at least one `NS` record, or it may be considered "broken".

> [!TIP]
> You can query any record type with: `dig <domain-name> <record-type>`

## Time to Live (TTL)

The **TTL** field specifies how many seconds a DNS client should cache this record before querying the DNS server again.

When you get a resource record directly from an [authoritative DNS server](overview.md#authoritative-servers), its TTL has the original value.

On the other hand, when you get a resource record from a cache (for example, from a recursive resolver or stub resolver), the TTL value will be reduced by the number of seconds the record has been in the cache.
