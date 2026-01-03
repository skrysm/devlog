---
title: YAML Basics (for people how know JSON)
date: 2026-01-03
oldContentWarning: false
topics:
- yaml
---

For most software developers, JSON is easy to understand. YAML, on the other hand, is sometimes a little bit unintuitive (my guess: YAML has some ambiguities that JSON has not). This document tries to shed some light on those "problems".

## Links

* [Official website](https://yaml.org/)
* [YAML 1.2 Spec](https://yaml.org/spec/1.2/spec.html)

## Advantages over JSON

YAML is a superset of JSON. Meaning: every valid JSON document can also be written in YAML without losing any information.

YAML has some bells and whistles that JSON documents don't have. The most important advantage is (IMHO):

**Support for comments (pure JSON does *not* allow for comments).**

## Sequences

**Sequences** in YAML lingo are **lists**.

```yaml
- Mark McGwire
- Sammy Sosa
- Ken Griffey
```

JSON equivalent:

```json
[ "Mark McGwire", "Sammy Sosa", "Ken Griffey" ]
```

## Mappings

**Mappings** in YAML lingo are **objects**.

```yaml
hr:  65    # Home runs
avg: 0.278 # Batting average
rbi: 147   # Runs Batted In
```

JSON equivalent:

```json
{
    "hr": 65,
    "avg": 0.278,
    "rbi": 147
}
```

## Documents

YAML allows you to have multiple "documents" inside a single file/stream.

Documents are separated by `---`.

```yaml
---
- Mark McGwire
- Sammy Sosa
- Ken Griffey

---
- Chicago Cubs
- St Louis Cardinals
```

## Strings and Quotes

YAML doesn't differentiate between strings and scalars in general. However, YAML allows for single and double quotes.

Double quotes allow escape sequences like `\n`.

Single quotes are useful for forcing a string when the first characters would have another meaning otherwise (like `"` or `#`).

```yaml
- Some string
- 'Also some string'
- "Yet another\nstring"
- '"Howdy!" he cried.' # Single quote use case 1
- '# Not a ''comment''.' # Single quote use case 2
```

## Multiline Strings

### Literal Style

In **literal** style (`|`), newlines are preserved.

```yaml
description: |
  \//||\/||
  // ||  ||__
```

becomes:

    \//||\/||
    // ||  ||__

### Folded Style

In **folded** style (`>`), newlines are replaced with spaces - unless it ends an empty or a more-indented line.

```yaml
description: >
  Mark McGwire's
  year was crippled
  by a knee injury.
```

becomes:

    Mark McGwire's year was crippled by a knee injury.

```yaml
description: >
  Sammy Sosa completed another
  fine season with great stats.

    63 Home Runs
    0.288 Batting Average

  What a year!
```

becomes:

```
Sammy Sosa completed another fine season with great stats.

    63 Home Runs
    0.288 Batting Average

What a year!
```

### Trim and Extra

YAML also supports trimming and keeping extra **final newlines**:

| Notation | Meaning | Example
| --- | --- | ---
| `>`, `\|` | Preserve final newline | `"a text\n"`
| `>-`, `\|-` | Trim final newline | `"a text"`
| `>+`, `\|+` | Keep all final newlines | `"a text\n\n\n"`

**Example YAML:**

```yaml
fold_keep: >
  a
  b

fold_strip: >-
  a
  b

fold_extra: >+
  a
  b


lit_keep: |
  a
  b

lit_strip: |-
  a
  b

lit_extra: |+
  a
  b


# End comment
```

**Test with `yq`:**

```sh
yq '.fold_keep' test.yaml   # "a b\n"
yq '.fold_strip' test.yaml  # "a b"
yq '.fold_extra' test.yaml  # "a b\n\n\n"
yq '.lit_keep' test.yaml    # "a\nb\n"
yq '.lit_strip' test.yaml   # "a\nb"
yq '.lit_extra' test.yaml   # "a\nb\n\n\n"
```
