---
title: Change Commit and Author Date in Git
description: How to change the commit and/or author date for a Git commit.
topics:
- git
date: 2025-08-28
---

This article shows how to change both the **commit date** and the **author date** for the last commit.

**Linux/Bash:**

```sh
GIT_COMMITTER_DATE="2025-08-11T14:30:00" git commit --amend --no-edit --date="2025-08-11T14:30:00"
```

**Windows (cmd.exe):**

```cmd
set GIT_COMMITTER_DATE=2025-08-11T14:30:00
git commit --amend --no-edit --date="2025-08-11T14:30:00"
```

**PowerShell:**

```powershell
$env:GIT_COMMITTER_DATE="2025-08-11T14:30:00"
git commit --amend --no-edit --date="2025-08-11T14:30:00"
```

> [!WARNING]
> This does rewrite the Git history of the current branch. So don't do this if the last commit has already been pushed, unless you know what you're doing.
