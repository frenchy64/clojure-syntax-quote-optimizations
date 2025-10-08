#!/bin/bash
# Experiment: Maps with Distinct Constant Keys Optimization Impact Measurement
#
# HYPOTHESIS: Optimizing syntax-quote to use map literals for maps with distinct
# constant keys instead of (apply hash-map (seq (concat ...))) will reduce the 
# size of the AOT-compiled direct-linked Clojure uberjar.
#
# This wrapper script calls the shared uberjar comparison script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBPROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$SUBPROJECT_ROOT/.." && pwd)"
SHARED_SCRIPT="$REPO_ROOT/shared/compare-uberjar.sh"
BUILD_SCRIPT="$SUBPROJECT_ROOT/build-optimized-uberjar.sh"
RESULTS_DIR="$SCRIPT_DIR/results/01-maps-distinct-constant-keys-optimization"

if [ ! -x "$SHARED_SCRIPT" ]; then
    echo "ERROR: Shared comparison script not found or not executable: $SHARED_SCRIPT"
    exit 1
fi

exec "$SHARED_SCRIPT" "maps-distinct-constant-keys" "Maps with Distinct Constant Keys Optimization" "$BUILD_SCRIPT" "$RESULTS_DIR"
