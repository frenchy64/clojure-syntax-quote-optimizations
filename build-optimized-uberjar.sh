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
REPO_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
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
git clone "${REPO_ROOT}/clojure" clojure-build
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

# Convenience feature: Auto-setup Java 8 with sdkman for local usage
# This checks if sdkman is available and ensures Java 8 is installed and active

# First, check if sdkman is installed and source it if needed
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    # Temporarily disable unbound variable and exit-on-error checks
    # (sdkman-init.sh may reference variables like ZSH_VERSION and positional parameters that aren't set)
    set +eu
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    set -eu
fi

# Now check if sdk is available (either already in PATH or just sourced)
if type sdk &> /dev/null; then
    echo "sdkman detected, checking for Java 8..."
    
    # Look for the latest installed temurin Java 8
    # Note: We use 'set +e' here because grep may return non-zero if no matches found,
    # which shouldn't cause the script to exit
    # Pattern: Filter for Java 8, extract Identifier column, check if ends with -tem
    # Note: sdk list uses a pager, so we set PAGER=cat to get raw output
    set +e
    JAVA8_VERSION=$(PAGER=cat sdk list java 2>/dev/null | \
        grep "installed" | \
        grep "8\." | \
        awk -F'|' '{print $NF}' | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
        grep -- "-tem$" | \
        sort -V | tail -1)
    set -e
    
    if [ -z "$JAVA8_VERSION" ]; then
        echo "No temurin Java 8 installation found via sdkman."
        echo "Installing latest temurin Java 8..."
        
        # Find the latest available temurin Java 8
        # Pattern: Filter for Java 8, extract Identifier column, check if ends with -tem
        set +e
        JAVA8_VERSION=$(PAGER=cat sdk list java 2>/dev/null | \
            grep "8\." | \
            awk -F'|' '{print $NF}' | \
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
            grep -- "-tem$" | \
            sort -V | tail -1)
        set -e
        
        if [ -z "$JAVA8_VERSION" ]; then
            echo "ERROR: Could not find temurin Java 8 in sdk list"
            exit 1
        fi
        
        # Install the latest temurin Java 8
        sdk install java "$JAVA8_VERSION" || {
            echo "ERROR: Failed to install Java 8 via sdkman"
            exit 1
        }
        echo "✓ Installed temurin Java 8: $JAVA8_VERSION"
    else
        echo "✓ Found installed temurin Java 8: $JAVA8_VERSION"
    fi
    
    # Activate Java 8 for this shell session
    echo "Activating Java 8 for this build session..."
    sdk use java "$JAVA8_VERSION" || {
        echo "ERROR: Failed to activate Java 8"
        exit 1
    }
    echo "✓ Java 8 activated"
    echo ""
else
    echo "sdkman not detected, skipping auto-setup."
    echo "Please ensure Java 8 is active manually."
fi

# Assert Check Java version
java -version 2>&1 | head -1 | grep -q '1\.8\.0' && (echo "Java 8"; exit 0) || (echo "Not Java 8" ; exit 1)

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
