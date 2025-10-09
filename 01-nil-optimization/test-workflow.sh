#!/bin/bash
set -euo pipefail

# Demo script to verify the submodule and update-patch.sh workflow
# This script demonstrates the complete workflow for managing patches

echo "=========================================="
echo "Submodule and Patch Management Demo"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLOJURE_SUBMODULE="$REPO_ROOT/clojure"
PATCH_FILE="$SCRIPT_DIR/nil-optimization.patch"

# Read the Clojure commit SHA from CLOJURE_VERSION
CLOJURE_COMMIT=$(grep CLOJURE_COMMIT "$REPO_ROOT/CLOJURE_VERSION" | cut -d= -f2)

echo "Step 1: Verify submodule exists and is at correct commit"
echo "--------------------------------------------------------"
if [ ! -d "$CLOJURE_SUBMODULE" ]; then
    echo "ERROR: Clojure submodule directory not found"
    echo "Run: git submodule update --init"
    exit 1
fi

if [ ! -f "$CLOJURE_SUBMODULE/.git" ] && [ ! -d "$CLOJURE_SUBMODULE/.git" ]; then
    echo "ERROR: Clojure submodule not initialized"
    echo "Run: git submodule update --init"
    exit 1
fi

cd "$CLOJURE_SUBMODULE"
CURRENT_COMMIT=$(git rev-parse HEAD)
echo "Expected commit: $CLOJURE_COMMIT"
echo "Current commit:  $CURRENT_COMMIT"

if [ "$CURRENT_COMMIT" != "$CLOJURE_COMMIT" ]; then
    echo "WARNING: Submodule is not at expected commit"
    echo "Checking out correct commit..."
    git checkout "$CLOJURE_COMMIT"
fi
echo "✓ Submodule at correct commit"
echo ""

echo "Step 2: Verify patch applies cleanly"
echo "-------------------------------------"
cd "$CLOJURE_SUBMODULE"
git reset --hard "$CLOJURE_COMMIT" > /dev/null 2>&1
if git apply --check "$PATCH_FILE" 2>&1; then
    echo "✓ Patch applies cleanly"
    git apply "$PATCH_FILE"
    echo "✓ Patch applied successfully"
else
    echo "ERROR: Patch does not apply cleanly"
    exit 1
fi
echo ""

echo "Step 3: Verify patched LispReader.java matches"
echo "-----------------------------------------------"
if diff -q "$CLOJURE_SUBMODULE/src/jvm/clojure/lang/LispReader.java" \
         "$SCRIPT_DIR/patch/LispReader.java" > /dev/null 2>&1; then
    echo "✓ Patched LispReader.java matches the version in patch/ directory"
else
    echo "WARNING: Patched LispReader.java differs from patch/ directory version"
    echo "This is expected if you've modified the patch/ version"
fi
echo ""

echo "Step 4: Show the actual code change"
echo "------------------------------------"
cd "$CLOJURE_SUBMODULE"
git diff src/jvm/clojure/lang/LispReader.java | grep -A5 -B5 "form == null" || true
echo ""

echo "Step 5: Reset submodule to clean state"
echo "---------------------------------------"
git reset --hard "$CLOJURE_COMMIT" > /dev/null 2>&1
echo "✓ Submodule reset to clean state"
echo ""

echo "=========================================="
echo "Demo completed successfully!"
echo "=========================================="
echo ""
echo "To modify the patch:"
echo "  1. Edit: 01-nil-optimization/patch/LispReader.java"
echo "  2. Run:  01-nil-optimization/update-patch.sh"
echo "  3. The nil-optimization.patch file will be regenerated"
