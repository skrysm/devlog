---
title: dig - DNS Tool
description: Decrypting dig output.
topics:
- dns
date: 2025-08-18
---

The output of `dig` (Domain Information Groper) can appear cryptic if you're not familiar with DNS. This article breaks down each part of the output to help you understand what it means.

> [!TIP]
> On Debian/Ubuntu, install the `dnsutils` package to get the `dig` command.

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
* **Global options:** Any extra flags you passed (e.g., `+trace`).

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
