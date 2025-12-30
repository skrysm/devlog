---
title: Starter template for a Bash script
date: 2025-12-30
topics:
- bash
---

```sh
#!/usr/bin/env bash

#
# General notes:
#
# * $(...) removes all trailing line breaks.
# * $SECONDS is a special shell variable that contains the seconds since the shell has started.
#

# Exit immediately if any command exits with non-zero status
set -e
# Exit if an undefined variable is used
set -u
# Fail if any command in a pipeline fails (not just the last one)
set -o pipefail

# Print line at which the script failed, if it failed (due to "set -e").
trap 'print_error "Script failed at line $LINENO"' ERR

# Configuration
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output (optional)
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

print_error() {
    echo -e "${RED}$*${NC}" >&2
}

print_warn() {
    echo -e "${YELLOW}$*${NC}" >&2
}

print_title() {
    echo -e "${CYAN}$*${NC}"
    echo
}

###########################################################################################
#
# Main Script
#
###########################################################################################
```
