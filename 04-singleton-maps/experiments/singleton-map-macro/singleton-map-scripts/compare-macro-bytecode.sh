#!/bin/bash
set -euo pipefail

# This script compares the bytecode of a compiled macro that uses singleton maps
# between baseline Clojure 1.12.3 and the optimized version.
#
# What it verifies: Macro definition bytecode changes (Effect #1)
#
# Dependencies: curl, sha256sum, javap, java/javac, diff
# 
# Expected output: Bytecode differences showing singleton map optimization

BASELINE_URL="https://repo1.maven.org/maven2/org/clojure/clojure/1.12.3/clojure-1.12.3.jar"
# Verified by: curl -sL $BASELINE_URL | sha256sum
BASELINE_SHA256="cb2a1a3db1c2cd76ef4fa4a545d5a65f10b1b48b7f7672f0a109f5476f057166"

# Path to shared build script
SCRIPT_DIR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBPROJECT_ROOT="$(cd "$SCRIPT_DIR_PATH/../../.." && pwd)"
BUILD_SCRIPT="$SUBPROJECT_ROOT/build-optimized-uberjar.sh"

WORK_DIR="/tmp/singleton-map-bytecode-compare-$$"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "=== Comparing Singleton Map Macro Bytecode ==="
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

# Build optimized version using shared script
echo "Building optimized Clojure..."
if [ ! -x "$BUILD_SCRIPT" ]; then
    echo "ERROR: Build script not found or not executable: $BUILD_SCRIPT"
    exit 1
fi

TEMP_BUILD_DIR="$WORK_DIR/temp-build"
"$BUILD_SCRIPT" "$TEMP_BUILD_DIR"
if [ ! -f "$TEMP_BUILD_DIR/clojure-singleton-maps-optimized.jar" ]; then
    echo "ERROR: Built JAR not found"
    exit 1
fi
cp "$TEMP_BUILD_DIR/clojure-singleton-maps-optimized.jar" "$WORK_DIR/clojure-optimized.jar"
rm -rf "$TEMP_BUILD_DIR"
echo "✓ Built optimized JAR"
echo ""

# Create test Clojure source file with singleton map macro
echo "Creating test Clojure source file..."
cat > test_macro.clj << 'EOF'
(ns test-macro)

(defmacro test-singleton-map
  "A minimal macro that returns a syntax-quoted singleton map.
  This tests the singleton map optimization."
  [x]
  `{:a ~x})

;; Also test usage of the macro
(defn use-macro []
  (test-singleton-map 42))
EOF
echo "✓ Created test_macro.clj"
echo ""

# Compile with baseline Clojure
echo "Compiling with baseline Clojure 1.12.3..."
mkdir -p classes-baseline
java -cp "clojure-baseline.jar" clojure.main -e "
(binding [*compile-path* \"classes-baseline\"]
  (compile 'test-macro))
"
if [ ! -f "classes-baseline/test_macro\$test_singleton_map.class" ]; then
    echo "ERROR: Baseline compilation failed"
    exit 1
fi
echo "✓ Compiled with baseline Clojure"
echo ""

# Compile with optimized Clojure
echo "Compiling with optimized Clojure..."
mkdir -p classes-optimized
java -cp "clojure-optimized.jar" clojure.main -e "
(binding [*compile-path* \"classes-optimized\"]
  (compile 'test-macro))
"
if [ ! -f "classes-optimized/test_macro\$test_singleton_map.class" ]; then
    echo "ERROR: Optimized compilation failed"
    exit 1
fi
echo "✓ Compiled with optimized Clojure"
echo ""

# Compare the class files directly
echo "=== Direct Binary Comparison ==="
MACRO_CLASS="test_macro\$test_singleton_map.class"

if cmp -s "classes-baseline/$MACRO_CLASS" "classes-optimized/$MACRO_CLASS"; then
    echo "⚠️  Class files are IDENTICAL (no bytecode changes detected)"
    echo "    This might indicate the optimization doesn't affect this macro,"
    echo "    or the comparison method needs refinement."
else
    echo "✓ Class files are DIFFERENT"
    echo ""
    
    # Show file sizes
    BASELINE_SIZE=$(stat -f%z "classes-baseline/$MACRO_CLASS" 2>/dev/null || stat -c%s "classes-baseline/$MACRO_CLASS")
    OPTIMIZED_SIZE=$(stat -f%z "classes-optimized/$MACRO_CLASS" 2>/dev/null || stat -c%s "classes-optimized/$MACRO_CLASS")
    SIZE_DIFF=$((OPTIMIZED_SIZE - BASELINE_SIZE))
    
    echo "  Baseline size:  $BASELINE_SIZE bytes"
    echo "  Optimized size: $OPTIMIZED_SIZE bytes"
    echo "  Difference:     $SIZE_DIFF bytes"
    
    if [ $SIZE_DIFF -lt 0 ]; then
        PERCENT=$(echo "scale=1; ($SIZE_DIFF * 100.0) / $BASELINE_SIZE" | bc)
        echo "  Reduction:      $PERCENT%"
    fi
fi
echo ""

# Generate readable bytecode with javap
echo "=== Generating Bytecode Disassembly ==="
javap -c -p -v "classes-baseline/$MACRO_CLASS" > macro-baseline.javap 2>&1
javap -c -p -v "classes-optimized/$MACRO_CLASS" > macro-optimized.javap 2>&1
echo "✓ Generated baseline bytecode: macro-baseline.javap"
echo "✓ Generated optimized bytecode: macro-optimized.javap"
echo ""

# Compute checksums of javap output (for reproducibility)
BASELINE_JAVAP_SHA256=$(sha256sum macro-baseline.javap | awk '{print $1}')
OPTIMIZED_JAVAP_SHA256=$(sha256sum macro-optimized.javap | awk '{print $1}')
echo "  Baseline javap SHA256:  $BASELINE_JAVAP_SHA256"
echo "  Optimized javap SHA256: $OPTIMIZED_JAVAP_SHA256"
echo ""

# Show the diff
echo "=== Bytecode Differences ==="
echo ""

if diff -u macro-baseline.javap macro-optimized.javap > macro.diff; then
    echo "⚠️  No differences found in javap output"
    echo "    (This might mean optimization doesn't affect this macro,"
    echo "     or javap output is too high-level to show the change)"
else
    echo "✓ Found differences (first 150 lines):"
    echo ""
    head -150 macro.diff
    echo ""
    if [ $(wc -l < macro.diff) -gt 150 ]; then
        echo "... (diff continues, $(wc -l < macro.diff) total lines)"
        echo ""
    fi
    echo "Full diff saved to: macro.diff"
    echo "Full baseline bytecode: macro-baseline.javap"
    echo "Full optimized bytecode: macro-optimized.javap"
fi
echo ""

# Analyze the usage site (expanded code)
echo "=== Analyzing Expanded Code (use-macro function) ==="
USE_CLASS="test_macro\$use_macro.class"

if [ -f "classes-baseline/$USE_CLASS" ] && [ -f "classes-optimized/$USE_CLASS" ]; then
    BASELINE_USE_SIZE=$(stat -f%z "classes-baseline/$USE_CLASS" 2>/dev/null || stat -c%s "classes-baseline/$USE_CLASS")
    OPTIMIZED_USE_SIZE=$(stat -f%z "classes-optimized/$USE_CLASS" 2>/dev/null || stat -c%s "classes-optimized/$USE_CLASS")
    USE_SIZE_DIFF=$((OPTIMIZED_USE_SIZE - BASELINE_USE_SIZE))
    
    echo "Compiled code that USES the macro:"
    echo "  Baseline size:  $BASELINE_USE_SIZE bytes"
    echo "  Optimized size: $OPTIMIZED_USE_SIZE bytes"
    echo "  Difference:     $USE_SIZE_DIFF bytes"
    
    if [ $USE_SIZE_DIFF -lt 0 ]; then
        PERCENT=$(echo "scale=1; ($USE_SIZE_DIFF * 100.0) / $BASELINE_USE_SIZE" | bc)
        echo "  Reduction:      $PERCENT%"
    fi
    echo ""
    
    # Generate bytecode for usage site
    javap -c -p "classes-baseline/$USE_CLASS" > use-baseline.javap 2>&1
    javap -c -p "classes-optimized/$USE_CLASS" > use-optimized.javap 2>&1
    
    if diff -u use-baseline.javap use-optimized.javap > use.diff; then
        echo "  No differences in usage site bytecode"
    else
        echo "  ✓ Found differences in usage site (Effect #3)"
        echo "  Usage site diff saved to: use.diff"
    fi
fi
echo ""

echo "=== Summary ==="
echo ""
echo "All artifacts saved to: $WORK_DIR"
echo ""
echo "Key files:"
echo "  - macro-baseline.javap: Baseline macro bytecode"
echo "  - macro-optimized.javap: Optimized macro bytecode"
echo "  - macro.diff: Differences in macro definition"
echo "  - use-baseline.javap: Baseline usage site bytecode"
echo "  - use-optimized.javap: Optimized usage site bytecode"
echo "  - use.diff: Differences in usage site"
echo ""
