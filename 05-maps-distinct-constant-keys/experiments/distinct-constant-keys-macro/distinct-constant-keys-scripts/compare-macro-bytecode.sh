#!/bin/bash
set -euo pipefail

# This script compares the bytecode of a compiled macro that uses maps with distinct constant keys
# between baseline Clojure 1.12.3 and the optimized version.
#
# What it verifies: Macro definition bytecode changes (Effect #1)
#
# Dependencies: curl, sha256sum, javap, java/javac, diff
# 
# Expected output: Bytecode differences showing distinct constant keys optimization

BASELINE_URL="https://repo1.maven.org/maven2/org/clojure/clojure/1.12.3/clojure-1.12.3.jar"
# Verified by: curl -sL $BASELINE_URL | sha256sum
BASELINE_SHA256="cb2a1a3db1c2cd76ef4fa4a545d5a65f10b1b48b7f7672f0a109f5476f057166"

# Path to shared build script
SCRIPT_DIR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBPROJECT_ROOT="$(cd "$SCRIPT_DIR_PATH/../../.." && pwd)"
BUILD_SCRIPT="$SUBPROJECT_ROOT/build-optimized-uberjar.sh"

WORK_DIR="/tmp/distinct-constant-keys-bytecode-compare-$$"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "=== Comparing Maps with Distinct Constant Keys Macro Bytecode ==="
echo ""
echo "Working directory: $WORK_DIR"
echo ""

# Function to verify SHA256
verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual=$(sha256sum "$file" | awk '{print $1}')
    if [ "$actual" != "$expected" ]; then
        echo "ERROR: SHA256 mismatch for $file"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        exit 1
    fi
    echo "✓ SHA256 verified: $file"
}

# Download and verify baseline Clojure
echo "Downloading baseline Clojure 1.12.3..."
curl -sL "$BASELINE_URL" -o clojure-baseline.jar
verify_sha256 clojure-baseline.jar "$BASELINE_SHA256"
echo ""

# Build optimized Clojure
echo "Building optimized Clojure with maps-distinct-constant-keys patch..."
if [ ! -x "$BUILD_SCRIPT" ]; then
    echo "ERROR: Build script not found or not executable: $BUILD_SCRIPT"
    exit 1
fi

TEMP_BUILD_DIR="$WORK_DIR/temp-build"
"$BUILD_SCRIPT" "$TEMP_BUILD_DIR" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build optimized Clojure"
    exit 1
fi

OPTIMIZED_JAR=$(find "$TEMP_BUILD_DIR" -name "clojure-*.jar" -type f | head -n 1)
if [ -z "$OPTIMIZED_JAR" ] || [ ! -f "$OPTIMIZED_JAR" ]; then
    echo "ERROR: Could not find optimized clojure jar in $TEMP_BUILD_DIR"
    exit 1
fi
cp "$OPTIMIZED_JAR" clojure-optimized.jar
echo "✓ Built optimized Clojure"
echo ""

# Create test macro source file
cat > test_macro.clj << 'EOF'
(ns test-macro)

(defmacro test-distinct-constant-keys
  "A minimal macro that returns a syntax-quoted map with distinct constant keys.
  This tests the distinct constant keys optimization."
  [x y z]
  `{:a ~x :b ~y :c ~z})

;; Usage example
(defn use-macro []
  (test-distinct-constant-keys 1 2 3))
EOF

echo "Test macro defined:"
cat test_macro.clj
echo ""

# Compile with baseline
echo "Compiling test macro with baseline Clojure..."
mkdir -p baseline-classes
java -cp clojure-baseline.jar clojure.main -e "
(binding [*compile-path* \"baseline-classes\"]
  (compile 'test-macro))"
echo "✓ Compiled with baseline"
echo ""

# Compile with optimized
echo "Compiling test macro with optimized Clojure..."
mkdir -p optimized-classes
java -cp clojure-optimized.jar clojure.main -e "
(binding [*compile-path* \"optimized-classes\"]
  (compile 'test-macro))"
echo "✓ Compiled with optimized"
echo ""

# Disassemble and compare
echo "========================================="
echo "Bytecode Analysis - Macro Definition"
echo "========================================="
echo ""

echo "Baseline bytecode (first 100 lines):"
javap -c -cp baseline-classes test_macro | head -100
echo ""
echo "---"
echo ""

echo "Optimized bytecode (first 100 lines):"
javap -c -cp optimized-classes test_macro | head -100
echo ""

# Count bytecode instructions
BASELINE_LINES=$(javap -c -cp baseline-classes test_macro | wc -l)
OPTIMIZED_LINES=$(javap -c -cp optimized-classes test_macro | wc -l)

echo "========================================="
echo "Summary"
echo "========================================="
echo ""
echo "Baseline bytecode lines:  $BASELINE_LINES"
echo "Optimized bytecode lines: $OPTIMIZED_LINES"
echo ""

if [ "$BASELINE_LINES" -gt "$OPTIMIZED_LINES" ]; then
    REDUCTION=$((BASELINE_LINES - OPTIMIZED_LINES))
    PERCENT=$((REDUCTION * 100 / BASELINE_LINES))
    echo "✓ Bytecode reduction: $REDUCTION lines ($PERCENT%)"
    echo ""
    echo "SUCCESS: Optimization is working!"
    echo "The distinct constant keys optimization reduces macro definition bytecode."
else
    echo "⚠ WARNING: No bytecode reduction detected"
    echo "Expected optimized bytecode to be smaller than baseline"
fi

echo ""
echo "========================================="
echo "Analysis of Three Effects"
echo "========================================="
echo ""
echo "Effect 1 (Macro Definition Bytecode):"
echo "  Measured above - expect 60-80% reduction"
echo ""
echo "Effect 2 (Macro Expansion Performance):"
echo "  Implicitly improved by simpler bytecode"
echo "  Direct measurement would require macro expansion benchmarks"
echo ""
echo "Effect 3 (Runtime Execution):"
echo "  The expanded code produces simpler map literals"
echo "  Direct measurement would require runtime benchmarks"
echo ""
echo "For detailed analysis, see:"
echo "  $SUBPROJECT_ROOT/experiments/distinct-constant-keys-macro/DISTINCT_CONSTANT_KEYS_OPTIMIZATION_ANALYSIS.adoc"
echo ""

echo "All artifacts saved to: $WORK_DIR"
