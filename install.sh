#!/usr/bin/env bash

# Stable entry point kept at the repository root for discoverability.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/scripts/install/install.sh" "$@"
