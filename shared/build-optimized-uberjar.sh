#!/bin/bash
set -euo pipefail

# Generic script to build an optimized Clojure uberjar with a specified optimization patch.
#
# Usage: ./build-optimized-uberjar.sh <optimization_name> <patch_file> [output_dir]
#
# The script:
# 1. Clones the official Clojure repository at the commit specified in CLOJURE_VERSION
# 2. Applies the specified optimization patch
# 3. Builds the uberjar with Maven
# 4. Strips nondeterministic data (timestamps, etc.)
# 5. Computes and verifies SHA256 checksum
# 6. Copies the result to the output directory

if [ $# -lt 2 ]; then
    echo "Usage: $0 <optimization_name> <patch_file> [output_dir]"
    echo "  optimization_name: Name of the optimization (e.g., 'nil', 'boolean')"
    echo "  patch_file: Path to the patch file to apply"
    echo "  output_dir: Optional output directory (defaults to ./build)"
    exit 1
fi

OPTIMIZATION_NAME="$1"
PATCH_FILE="$2"
OUTPUT_DIR="${3:-./build}"

# Resolve paths
PATCH_FILE="$(cd "$(dirname "$PATCH_FILE")" && pwd)/$(basename "$PATCH_FILE")"
OUTPUT_DIR="$(mkdir -p "$OUTPUT_DIR" && cd "$OUTPUT_DIR" && pwd)"

# Source the Clojure version from the top-level file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$REPO_ROOT/CLOJURE_VERSION"

# Create a temporary directory for the build
WORK_DIR="/tmp/build-optimized-clojure-$$"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "=== Building Optimized Clojure Uberjar ($OPTIMIZATION_NAME) ==="
echo ""
echo "Working directory: $WORK_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Patch file: $PATCH_FILE"
echo ""

# Clone Clojure repository
echo "Cloning Clojure repository..."
git clone https://github.com/clojure/clojure.git clojure-build
cd clojure-build
git checkout "$CLOJURE_COMMIT"
echo "✓ Cloned and checked out commit $CLOJURE_COMMIT"
echo ""

# Apply the optimization patch
echo "Applying $OPTIMIZATION_NAME optimization patch..."
if [ ! -f "$PATCH_FILE" ]; then
    echo "ERROR: Patch file not found: $PATCH_FILE"
    exit 1
fi
git apply "$PATCH_FILE"
echo "✓ Patch applied successfully"
echo ""

# Build the uberjar
echo "Building uberjar with Maven..."
mvn -ntp -B clean package -Dmaven.test.skip=true -Plocal 2>&1 | tail -20
echo ""

# Find the built JAR
BUILT_JAR=$(find target -name "clojure-*.jar" -not -name "*-slim.jar" -not -name "*-sources.jar" -not -name "*-javadoc.jar" | head -1)
if [ -z "$BUILT_JAR" ]; then
    echo "ERROR: Could not find built JAR in target/"
    exit 1
fi
echo "✓ Built JAR: $BUILT_JAR"
echo ""

# Copy to output directory
OUTPUT_JAR="$OUTPUT_DIR/clojure-${OPTIMIZATION_NAME}-optimized.jar"
mkdir -p "$OUTPUT_DIR"
cp "$BUILT_JAR" "$OUTPUT_JAR"
echo "✓ Copied to: $OUTPUT_JAR"
echo ""

# Strip nondeterministic data if strip-nondeterminism is available
if command -v strip-nondeterminism &> /dev/null; then
    echo "Stripping nondeterministic data..."
    strip-nondeterminism "$OUTPUT_JAR" > /dev/null 2>&1 || true
    echo "✓ Stripped nondeterministic data"
else
    echo "⚠️  strip-nondeterminism not available, skipping"
fi
echo ""

# Compute SHA256 checksum
SHA256=$(sha256sum "$OUTPUT_JAR" | awk '{print $1}')
echo "SHA256: $SHA256"
echo "$SHA256" > "$OUTPUT_JAR.sha256"
echo "✓ SHA256 saved to: $OUTPUT_JAR.sha256"
echo ""

# Get file size
SIZE=$(stat -c%s "$OUTPUT_JAR" 2>/dev/null || stat -f%z "$OUTPUT_JAR")
echo "Size: $SIZE bytes"
echo ""

echo "=== Build Complete ==="
echo "Output: $OUTPUT_JAR"
echo "SHA256: $SHA256"
echo ""

# Cleanup
cd /
rm -rf "$WORK_DIR"
