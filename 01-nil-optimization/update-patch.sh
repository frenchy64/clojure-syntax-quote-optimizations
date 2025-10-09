#!/bin/bash
set -euo pipefail

# This script regenerates the nil-optimization.patch from the modified LispReader.java
# Usage: ./update-patch.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLOJURE_SUBMODULE="$REPO_ROOT/clojure"
PATCH_FILE="$SCRIPT_DIR/nil-optimization.patch"
PATCHED_LISP_READER="$SCRIPT_DIR/patch/LispReader.java"

# Read the Clojure commit SHA from CLOJURE_VERSION
CLOJURE_COMMIT=$(grep CLOJURE_COMMIT "$REPO_ROOT/CLOJURE_VERSION" | cut -d= -f2)

if [ -z "$CLOJURE_COMMIT" ]; then
    echo "ERROR: Could not read CLOJURE_COMMIT from $REPO_ROOT/CLOJURE_VERSION"
    exit 1
fi

if [ ! -d "$CLOJURE_SUBMODULE" ]; then
    echo "ERROR: Clojure submodule not found at $CLOJURE_SUBMODULE"
    exit 1
fi

if [ ! -f "$PATCHED_LISP_READER" ]; then
    echo "ERROR: Patched LispReader.java not found at $PATCHED_LISP_READER"
    exit 1
fi

echo "Updating nil-optimization.patch from modified LispReader.java..."
echo ""

# Step 1: Clean reset the submodule to the target commit
echo "Step 1: Resetting clojure submodule to commit $CLOJURE_COMMIT..."
cd "$CLOJURE_SUBMODULE"
git reset --hard "$CLOJURE_COMMIT"
git clean -fd
echo "✓ Submodule reset complete"
echo ""

# Step 2: Copy the modified LispReader.java to the submodule
echo "Step 2: Copying modified LispReader.java to submodule..."
cp "$PATCHED_LISP_READER" "$CLOJURE_SUBMODULE/src/jvm/clojure/lang/LispReader.java"
echo "✓ File copied"
echo ""

# Step 3: Stage and commit the changes
echo "Step 3: Committing changes in submodule..."
git add src/jvm/clojure/lang/LispReader.java

# Set commit author and committer using hardcoded values from the original patch
GIT_AUTHOR_NAME="Copilot"
GIT_AUTHOR_EMAIL="copilot@github.com"
GIT_AUTHOR_DATE="Mon, 7 Oct 2024 20:00:00 +0000"
GIT_COMMITTER_NAME="Copilot"
GIT_COMMITTER_EMAIL="copilot@github.com"
GIT_COMMITTER_DATE="Mon, 7 Oct 2024 20:00:00 +0000"
export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_AUTHOR_DATE GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_COMMITTER_DATE

# Use heredoc for the commit message
git commit -m "$(cat <<'EOF'
Optimize syntax-quote to make nil self-evaluating

Make nil self-evaluating in syntax-quote by treating it like other
self-evaluating forms (keywords, numbers, characters, strings).

Instead of expanding `nil to (quote nil), it now expands to just nil.
Both forms evaluate to the same value, but the optimization reduces
bytecode size and improves macro expansion performance.
EOF
)"

echo "✓ Changes committed"
echo ""

# Step 4: Generate the patch
echo "Step 4: Generating patch file..."
git format-patch -1 HEAD --stdout > "$PATCH_FILE"
echo "✓ Patch generated at $PATCH_FILE"
echo ""

# Step 5: Reset the submodule back to clean state
echo "Step 5: Resetting submodule back to clean state..."
git reset --hard "$CLOJURE_COMMIT"
git clean -fd
echo "✓ Submodule reset complete"
echo ""

echo "SUCCESS: Patch file updated at $PATCH_FILE"
