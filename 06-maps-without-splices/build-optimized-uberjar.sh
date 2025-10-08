#!/bin/bash
set -euo pipefail

# Wrapper script for building maps-without-splices-optimized Clojure uberjar
#
# Usage: ./build-optimized-uberjar.sh [output_dir]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_SCRIPT="$REPO_ROOT/shared/build-optimized-uberjar.sh"
PATCH_FILE="$SCRIPT_DIR/maps-without-splices.patch"
OUTPUT_DIR="${1:-$SCRIPT_DIR/build}"

if [ ! -x "$SHARED_SCRIPT" ]; then
    echo "ERROR: Shared build script not found or not executable: $SHARED_SCRIPT"
    exit 1
fi

exec "$SHARED_SCRIPT" "maps-without-splices" "$PATCH_FILE" "$OUTPUT_DIR"
