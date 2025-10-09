#!/bin/bash
set -euo pipefail

# Script to build nil-optimized Clojure uberjar with caching
#
# This script checks if the patch and built JAR are up-to-date by comparing
# SHA256 checksums. If they are up-to-date, it exits successfully without
# rebuilding. Otherwise, it calls the parent build script.
#
# Usage: ./build-optimized-uberjar.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_SCRIPT="$REPO_ROOT/build-optimized-uberjar.sh"
PATCH_FILE="$SCRIPT_DIR/nil-optimization.patch"
PATCH_SHA256_FILE="$SCRIPT_DIR/nil-optimization.patch.sha256"
JAR_SHA256_FILE="$SCRIPT_DIR/clojure-nil-optimized.jar.sha256"
BUILD_DIR="$REPO_ROOT/build"
JAR_FILE="$BUILD_DIR/clojure-nil-optimized.jar"
JAR_SHA256_FILE_BUILD="$BUILD_DIR/clojure-nil-optimized.jar.sha256"

echo "=== Nil Optimization Build Script ==="
echo ""

# Step 1: Check if patch SHA256 exists and matches
if [ -f "$PATCH_FILE" ] && [ -f "$PATCH_SHA256_FILE" ]; then
    echo "Checking patch file SHA256..."
    CURRENT_PATCH_SHA256=$(sha256sum "$PATCH_FILE" | awk '{print $1}')
    STORED_PATCH_SHA256=$(cat "$PATCH_SHA256_FILE")
    
    if [ "$CURRENT_PATCH_SHA256" != "$STORED_PATCH_SHA256" ]; then
        echo "⚠️  Patch SHA256 mismatch!"
        echo "   Current:  $CURRENT_PATCH_SHA256"
        echo "   Stored:   $STORED_PATCH_SHA256"
        echo "   Updating stored SHA256 and rebuilding..."
        echo "$CURRENT_PATCH_SHA256" > "$PATCH_SHA256_FILE"
        # Skip to step 4
    else
        echo "✓ Patch SHA256 matches"
        
        # Step 2: Check if JAR SHA256 exists and matches
        if [ -f "$JAR_FILE" ] && [ -f "$JAR_SHA256_FILE" ]; then
            echo "Checking JAR file SHA256..."
            CURRENT_JAR_SHA256=$(sha256sum "$JAR_FILE" | awk '{print $1}')
            STORED_JAR_SHA256=$(cat "$JAR_SHA256_FILE")
            
            if [ "$CURRENT_JAR_SHA256" = "$STORED_JAR_SHA256" ]; then
                # Step 3: Both are up-to-date, exit successfully
                echo "✓ JAR SHA256 matches"
                echo ""
                echo "=== Build is up-to-date ==="
                echo "✓ Patch SHA256 matches stored value"
                echo "✓ JAR SHA256 matches stored value"
                echo "✓ No rebuild needed"
                exit 0
            else
                echo "⚠️  JAR SHA256 mismatch!"
                echo "   Current:  $CURRENT_JAR_SHA256"
                echo "   Stored:   $STORED_JAR_SHA256"
                echo "   Rebuilding..."
            fi
        else
            if [ ! -f "$JAR_FILE" ]; then
                echo "⚠️  JAR file not found: $JAR_FILE"
            fi
            if [ ! -f "$JAR_SHA256_FILE" ]; then
                echo "⚠️  JAR SHA256 file not found: $JAR_SHA256_FILE"
            fi
            echo "   Rebuilding..."
        fi
    fi
else
    if [ ! -f "$PATCH_FILE" ]; then
        echo "ERROR: Patch file not found: $PATCH_FILE"
        exit 1
    fi
    if [ ! -f "$PATCH_SHA256_FILE" ]; then
        echo "⚠️  Patch SHA256 file not found"
        echo "   Creating it and rebuilding..."
        CURRENT_PATCH_SHA256=$(sha256sum "$PATCH_FILE" | awk '{print $1}')
        echo "$CURRENT_PATCH_SHA256" > "$PATCH_SHA256_FILE"
    fi
fi

# Step 4: Build the optimized uberjar
echo ""
echo "=== Building Optimized Uberjar ==="
echo ""

if [ ! -x "$BUILD_SCRIPT" ]; then
    echo "ERROR: Build script not found or not executable: $BUILD_SCRIPT"
    exit 1
fi

# Call the parent build script
"$BUILD_SCRIPT" "nil" "$PATCH_FILE" "$BUILD_DIR"

# Copy the SHA256 file from build directory to current directory
if [ -f "$JAR_SHA256_FILE_BUILD" ]; then
    echo ""
    echo "Copying JAR SHA256 to local directory..."
    cp "$JAR_SHA256_FILE_BUILD" "$JAR_SHA256_FILE"
    echo "✓ Copied $JAR_SHA256_FILE_BUILD to $JAR_SHA256_FILE"
else
    echo "WARNING: JAR SHA256 file not found in build directory: $JAR_SHA256_FILE_BUILD"
fi

echo ""
echo "=== Build Complete ==="
echo "✓ Optimized JAR: $JAR_FILE"
echo "✓ SHA256: $(cat "$JAR_SHA256_FILE" 2>/dev/null || echo 'N/A')"
