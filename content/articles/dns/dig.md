---
title: dig - DNS Tool
description: Decrypting dig output.
topics:
- dns
date: 2025-08-18
---

The output of `dig` (Domain Information Groper) can appear cryptic if you're not familiar with DNS. This article breaks down each part of the output to help you understand what it means.

## Installation

### Debian/Ubuntu

Install the `dnsutils` package:

```sh
apt install dnsutils
```

### Windows

On Windows, you can download `dig` as part of the bind9 package:

<https://ftp.isc.org/isc/bind9/9.17.15/BIND9.17.15.x64.zip>

Note, however, that the bind9 project [dropped Windows support](https://ftp.isc.org/isc/bind9/9.17.16/doc/arm/html/notes.html#removed-features) with version 9.17.16.

Alternatively, you can run `dig` through [WSL (Windows Subsystem for Linux)](https://learn.microsoft.com/en-us/windows/wsl/about).

## Example Output

We'll use the following example output (from `dig example.com`) throughout this article:

```zone
; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> example.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; QUESTION SECTION:
;example.com.                  IN      A

;; ANSWER SECTION:
example.com.           86399   IN      A       93.184.216.34

;; AUTHORITY SECTION:
example.com.           172800  IN      NS      a.iana-servers.net.
example.com.           172800  IN      NS      b.iana-servers.net.

;; ADDITIONAL SECTION:
a.iana-servers.net.    172800  IN      A       199.43.135.53
b.iana-servers.net.    172800  IN      A       199.43.133.53

;; Query time: 22 msec
;; SERVER: 1.1.1.1#53(1.1.1.1) (UDP)
;; WHEN: Fri Aug 15 15:22:07 UTC 2025
;; MSG SIZE  rcvd: 138
```

## Global Structure

The output is a textual representation of a [DNS request/response message](overview.md#protocol).

Each DNS message (request or response) contains these sections:

1. **Header**
1. **Question section** - usually the request
1. **Answer section** - one of the responses
1. **Authority section** - one of the responses
1. **Additional section** - one of the responses

Each section is visible in the `dig` output.

The output format is similar to a [zone file](zone-files.md), where lines starting with `;` are comments.

## Output Sections

### 1. Banner

```zone
; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> example.com
;; global options: +cmd
```

* **Dig version:** For example, `9.18.30-0ubuntu0.24.04.2-Ubuntu`.
* **Command:** The domain you queried, here `example.com`.
* **Global options:** Any [extra flags](#options) you passed (e.g., `+trace`).

### 2. Header

```zone
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
```

* **opcode:** The type of request — usually `QUERY`.
* **status:** The result code. Common values:
  * `NOERROR`: The query was successful.
  * `NXDOMAIN`: The domain doesn't exist.
  * `SERVFAIL`: The server failed to answer.
* **id:** Transaction ID used internally to match requests and responses.

```zone
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3
```

* **flags:**
  * `qr`: Query response (as opposed to a request)
  * `rd`: Recursion desired (you asked the server to follow referrals)
  * `ra`: Recursion available (the server supports recursion)
  * Other possible flags: `aa` (authoritative answer), `ad` (DNSSEC authenticated)
* **QUERY / ANSWER / AUTHORITY / ADDITIONAL:** Number of resource records in each section.

### 3. QUESTION / ANSWER / AUTHORITY / ADDITIONAL Sections

```zone
;; QUESTION SECTION:
;example.com.                  IN      A

;; ANSWER SECTION:
example.com.           86399   IN      A       93.184.216.34

;; AUTHORITY SECTION:
example.com.           172800  IN      NS      a.iana-servers.net.
example.com.           172800  IN      NS      b.iana-servers.net.

;; ADDITIONAL SECTION:
a.iana-servers.net.    172800  IN      A       199.43.135.53
b.iana-servers.net.    172800  IN      A       199.43.133.53
```

Each section lists its [resource records](resource-records.md) in a readable format.

### 4. Footer

```zone
;; Query time: 22 msec
;; SERVER: 1.1.1.1#53(1.1.1.1) (UDP)
;; WHEN: Fri Aug 15 15:22:07 UTC 2025
;; MSG SIZE  rcvd: 138
```

* **Query time:** How long the query took to complete.
* **SERVER:** The DNS server that replied, including port (`#53`) and protocol (`UDP`).
* **WHEN:** Date and time of the query.
* **MSG SIZE rcvd:** Size of the reply in bytes.

## Reverse Lookup

To do a reverse lookup (i.e., find the domain names for an IP address):

```sh
dig -x <ip-address>
```

This queries for a [PTR record](resource-records.md).

## Useful Options {#options}

There are a few useful options.

### +short

`+short` - prints only the IP address:

```sh
$ dig wikipedia.org +short
185.15.59.224
```

### +trace

`+trace` - shows exactly who responded with what.

Each query/response ends with `;; Received xxx bytes from ...`.

```sh {lineNos=false,hl_lines="9 15 21 24"}
$ dig wikipedia.org +trace

; <<>> DiG 9.18.33-1~deb12u2-Raspbian <<>> wikipedia.org +trace
;; global options: +cmd
.                       41959   IN      NS      m.root-servers.net.
.                       41959   IN      NS      d.root-servers.net.
.                       41959   IN      NS      f.root-servers.net.
...
;; Received 1097 bytes from 192.168.0.1#53(192.168.0.1) in 20 ms

org.                    172800  IN      NS      d0.org.afilias-nst.org.
org.                    172800  IN      NS      b0.org.afilias-nst.org.
org.                    172800  IN      NS      b2.org.afilias-nst.org.
...
;; Received 782 bytes from 2001:dc3::35#53(m.root-servers.net) in 50 ms

wikipedia.org.          3600    IN      NS      ns0.wikimedia.org.
wikipedia.org.          3600    IN      NS      ns1.wikimedia.org.
wikipedia.org.          3600    IN      NS      ns2.wikimedia.org.
...
;; Received 655 bytes from 2001:500:48::1#53(b2.org.afilias-nst.org) in 30 ms

wikipedia.org.          180     IN      A       185.15.59.224
;; Received 78 bytes from 208.80.154.238#53(ns0.wikimedia.org) in 140 ms
```

> [!TIP]
> You can shorten the output with:
>
> ```sh
> dig +trace +noall +answer ...
> ```

## Error: UDP setup failed: network unreachable

**If you get:**

```
;; UDP setup with <IPv6 Address>#53 ... failed: network unreachable.
```

This means that IPv6 doesn't work on your system.

**To get rid of these errors:**

```sh
dig -4 ...
```

This limits `dig` to IPv4.
