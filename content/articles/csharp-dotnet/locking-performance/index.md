---
title: .NET Locking Performance
date: 2012-10-04
topics:
- dotnet
- performance
aliases:
- /2012/10/04/net-locking-performance/
- /2012/10/net-locking-performance/
---

Just a quick overview of the different lock types and their performance in .NET.

For this test, the following method was called as fast as possible for 4 seconds:

```c#
private void TestMethod() {
  lock (this) { // this locking is replaced depending on the locking type
    counter++;
  }
}
```

Here are the results:

| Locking Type                                                          | Calls per second  | Factor |
| --------------------------------------------------------------------- | ----------------- | ------ |
| No locking (fastest possible)                                         | 470,972,276       | 19.61  |
|`Interlocked.CompareExchange`                                          | 62,439,529        | 2.60   |
|`lock` keyword                                                         | 37,554,119        | 1.56   |
|`SpinLock` (without owner tracking)                                    | 34,489,245        | 1.44   |
|`ReaderWriterLockSlim` with `LockRecursionPolicy.NoRecursion`          | 25,214,451        | 1.05   |
|`ReaderWriterLockSlim` with `LockRecursionPolicy.SupportsRecursion`    | 24,013,488        | 1.00   |

Full source code: [](Program.cs)
