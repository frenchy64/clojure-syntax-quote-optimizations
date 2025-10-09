#!/bin/bash
set -euo pipefail

# This script regenerates all optimization patches from their modified LispReader.java files
# Usage: ./update-all-patches.sh [directory_pattern]
#
# If directory_pattern is provided, only matching directories will be processed.
# Otherwise, all directories with patch files will be processed.
#
# Example: ./update-all-patches.sh "01-*"  # Only process directory 01
# Example: ./update-all-patches.sh         # Process all directories

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
CLOJURE_SUBMODULE="$REPO_ROOT/clojure"

# Read the Clojure commit SHA from CLOJURE_VERSION
CLOJURE_COMMIT=$(grep CLOJURE_COMMIT "$REPO_ROOT/CLOJURE_VERSION" | cut -d= -f2)

if [ -z "$CLOJURE_COMMIT" ]; then
    echo "ERROR: Could not read CLOJURE_COMMIT from $REPO_ROOT/CLOJURE_VERSION"
    exit 1
fi

if [ ! -d "$CLOJURE_SUBMODULE" ]; then
    echo "ERROR: Clojure submodule not found at $CLOJURE_SUBMODULE"
    echo "Please run: git submodule update --init"
    exit 1
fi

# Get optional directory pattern from command line
PATTERN="${1:-*}"

# Find all directories with patch files
PATCH_DIRS=()
for dir in "$REPO_ROOT"/$PATTERN; do
    if [ -d "$dir" ] && ls "$dir"/*.patch >/dev/null 2>&1; then
        PATCH_DIRS+=("$dir")
    fi
done

if [ ${#PATCH_DIRS[@]} -eq 0 ]; then
    echo "ERROR: No directories with patch files found matching pattern: $PATTERN"
    exit 1
fi

echo "==========================================="
echo "Updating patches for ${#PATCH_DIRS[@]} optimization(s)"
echo "==========================================="
echo ""

# Process each directory
for dir in "${PATCH_DIRS[@]}"; do
    DIR_NAME=$(basename "$dir")
    PATCH_FILE=$(ls "$dir"/*.patch | head -1)
    PATCH_NAME=$(basename "$PATCH_FILE")
    PATCHED_LISP_READER="$dir/LispReader.java"
    
    echo "==========================================="
    echo "Processing: $DIR_NAME"
    echo "==========================================="
    
    if [ ! -f "$PATCHED_LISP_READER" ]; then
        echo "⚠ WARNING: Patched LispReader.java not found at $PATCHED_LISP_READER"
        echo "Skipping $DIR_NAME"
        echo ""
        continue
    fi
    
    # Extract commit metadata from existing patch
    echo "Extracting metadata from existing patch..."
    COMMIT_AUTHOR_NAME=$(git mailinfo /dev/null /dev/null < "$PATCH_FILE" | grep "^Author:" | cut -d: -f2- | sed 's/^ *//')
    COMMIT_AUTHOR_EMAIL=$(sed -n 's/^From: .*<\(.*\)>.*/\1/p' "$PATCH_FILE" | head -1)
    COMMIT_DATE=$(git mailinfo /dev/null /dev/null < "$PATCH_FILE" | grep "^Date:" | cut -d: -f2- | sed 's/^ *//')
    
    # Extract full commit message (subject + body)
    COMMIT_MESSAGE=$(sed -n '/^Subject: \[PATCH\] /,/^---$/{ /^---$/d; s/^Subject: \[PATCH\] //; p; }' "$PATCH_FILE")
    COMMIT_SUBJECT=$(echo "$COMMIT_MESSAGE" | head -1)
    
    echo "  Subject: $COMMIT_SUBJECT"
    echo "  Author: $COMMIT_AUTHOR_NAME <$COMMIT_AUTHOR_EMAIL>"
    echo "  Date: $COMMIT_DATE"
    echo ""
    
    # Step 1: Clean reset the submodule to the target commit
    echo "Step 1: Resetting clojure submodule to commit $CLOJURE_COMMIT..."
    cd "$CLOJURE_SUBMODULE"
    git reset --hard "$CLOJURE_COMMIT" >/dev/null 2>&1
    git clean -fd >/dev/null 2>&1
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
    
    # Set commit metadata from extracted values
    export GIT_AUTHOR_NAME="$COMMIT_AUTHOR_NAME"
    export GIT_AUTHOR_EMAIL="$COMMIT_AUTHOR_EMAIL"
    export GIT_AUTHOR_DATE="$COMMIT_DATE"
    export GIT_COMMITTER_NAME="$COMMIT_AUTHOR_NAME"
    export GIT_COMMITTER_EMAIL="$COMMIT_AUTHOR_EMAIL"
    export GIT_COMMITTER_DATE="$COMMIT_DATE"
    
    # Commit with the extracted message
    git commit -m "$COMMIT_MESSAGE" >/dev/null 2>&1
    echo "✓ Changes committed"
    echo ""
    
    # Step 4: Generate the patch
    echo "Step 4: Generating patch file..."
    git format-patch -1 HEAD --stdout > "$PATCH_FILE"
    echo "✓ Patch generated at $PATCH_FILE"
    echo ""
    
    # Step 5: Reset the submodule back to clean state
    echo "Step 5: Resetting submodule back to clean state..."
    git reset --hard "$CLOJURE_COMMIT" >/dev/null 2>&1
    git clean -fd >/dev/null 2>&1
    echo "✓ Submodule reset complete"
    echo ""
    
    echo "SUCCESS: Patch updated for $DIR_NAME"
    echo ""
done

cd "$REPO_ROOT"
echo "==========================================="
echo "All patches updated successfully!"
echo "==========================================="
