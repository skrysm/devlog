---
title: DNS Zone Files
description: A text file format for defining DNS zones.
topics:
- dns
date: 2025-08-17
---

A **DNS zone file** defines a [DNS zone](overview.md#dns-zones). The format for zone files is specified by [RFC 1035](https://www.rfc-editor.org/rfc/rfc1035.html), which defines DNS.

## Basic Structure

Here's an example of a zone file:

```zone
example.com.  3600  IN  SOA   ns.example.com. admin.example.com. (
    2025081301 ; serial
    3600       ; refresh
    900        ; retry
    1209600    ; expire
    60         ; minimum
)

example.com.        3600  IN  NS    ns.example.com.

example.com.        3600  IN  A     192.0.2.1
example.com.        3600  IN  AAAA  2001:db8:10::1
ns.example.com.     3600  IN  A     192.0.2.2
ns.example.com.     3600  IN  AAAA  2001:db8:10::2

www.example.com.    3600  IN  CNAME example.com.
```

Each line is a [resource record](resource-records.md).

Resource records (or parts of it) can span multiple lines when wrapped in `( ... )`.

Comments start with `;`.

The first resource record must be the `SOA` record.

Note how, in this example, all DNS names end with a `.` - this marks them as absolute names (with `.` being the [root domain](overview.md#root-domain)).

### The SOA Record {#soa-record}

Each [DNS zone](overview.md#dns-zones) must have an `SOA` record. SOA stands for "Start of Authority".

The fields in its value have the following meanings (in order):

1. Primary DNS server
1. Admin email address - with `@` replaced by `.`
1. Serial number - newer versions of the zone file must have a higher number; usually the date followed by a counter
1. Refresh, Retry, Expire - timing (in seconds) for secondary servers to check for updates
1. Minimum - TTL in seconds for [negative caching](overview.md#negative-caching)

All these fields - except for the admin email address and minimum - are used by secondary DNS servers for [zone transfers](overview.md#zone-transfers). (They are *not* used by recursive resolvers.)

The admin email address is informational only and isn't used by DNS.

## Shorthands

The zone file format allows for various shorthands to make zone files easier to write and read.

The zone file above could also be written like this:

```zone {lineNos=true}
$ORIGIN example.com.
$TTL 3600
@  IN  SOA   ns   admin (
    2025081301 ; serial
    3600       ; refresh
    900        ; retry
    1209600    ; expire
    60         ; minimum
)

@  IN  NS    ns
       A     192.0.2.1
       AAAA  2001:db8:10::1

ns     A     192.0.2.2
       AAAA  2001:db8:10::2

www    CNAME @
```

Several shorthands are used here:

* `@` represents the value of `$ORIGIN`.
* Relative names (names without a `.` at the end, e.g. `ns`, `www`) are relative to `$ORIGIN`. For example, `www` (line 18) will resolve to `www.example.com.`.
  * This also applies to the nameserver and admin email address values in the `SOA` record.
* If you leave the name field blank (lines 12, 13, and 16), the name from the previous resource record is used (i.e., `@` for lines 12 and 13, and `ns` for line 16).
* The same applies to the record class field (i.e., `IN`).
* If the TTL field is blank, the value from `$TTL` is used.

## Syntax Checking

You can check if your zone file is correct with `named-checkzone` (Debian/Ubuntu package: `bind9utils`):

```sh
named-checkzone <zone-domain> <zone-file>
```

For example:

```sh
named-checkzone example.com example.com.zone
```

If correct, you'll see something like:

```
zone example.com/IN: loaded serial 2025081301
OK
```
