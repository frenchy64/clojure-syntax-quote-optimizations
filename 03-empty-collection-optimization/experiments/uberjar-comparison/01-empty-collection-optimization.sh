#!/bin/bash
# Experiment: Empty Collection Optimization Impact Measurement
#
# HYPOTHESIS: Optimizing syntax-quote to return empty collections directly instead of
# (apply vector (seq (concat))) etc. will reduce the size of the AOT-compiled
# direct-linked Clojure uberjar by eliminating unnecessary construction bytecode.
#
# This wrapper script calls the shared uberjar comparison script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBPROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$SUBPROJECT_ROOT/.." && pwd)"
SHARED_SCRIPT="$REPO_ROOT/shared/compare-uberjar.sh"
BUILD_SCRIPT="$SUBPROJECT_ROOT/build-optimized-uberjar.sh"
RESULTS_DIR="$SCRIPT_DIR/results/01-empty-collection-optimization"

if [ ! -x "$SHARED_SCRIPT" ]; then
    echo "ERROR: Shared comparison script not found or not executable: $SHARED_SCRIPT"
    exit 1
fi

exec "$SHARED_SCRIPT" "empty-collection" "Empty Collection Optimization" "$BUILD_SCRIPT" "$RESULTS_DIR"
