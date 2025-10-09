# Patch Management Workflow

This directory contains helper scripts and files for managing the `nil-optimization.patch`.

## Directory Structure

```
01-nil-optimization/
├── nil-optimization.patch     # Git patch file (to be applied to Clojure)
├── patch/
│   └── LispReader.java       # The patched version of LispReader.java
├── update-patch.sh           # Script to regenerate the patch from LispReader.java
└── test-workflow.sh          # Demo script to verify the workflow
```

## Workflow

### Initial Setup (Already Done)

The Clojure repository has been added as a git submodule at the root of this repository:

```bash
# This has already been done
git submodule add https://github.com/clojure/clojure.git clojure
cd clojure
git checkout e6393a4063c42ddc0e0812f04464467764f0fd1e  # From CLOJURE_VERSION file
```

### Modifying the Patch

To modify the nil optimization patch:

1. **Edit the patched file:**
   ```bash
   # Edit this file with your changes
   vim 01-nil-optimization/patch/LispReader.java
   ```

2. **Regenerate the patch:**
   ```bash
   ./01-nil-optimization/update-patch.sh
   ```

   This script will:
   - Reset the clojure submodule to the clean state (commit from CLOJURE_VERSION)
   - Copy your modified LispReader.java to the submodule
   - Create a git commit with the hardcoded author and message from the original patch
   - Generate a new git patch file using `git format-patch`
   - Clean up by resetting the submodule

3. **Commit the changes:**
   ```bash
   git add 01-nil-optimization/nil-optimization.patch
   git add 01-nil-optimization/patch/LispReader.java
   git commit -m "Update nil optimization patch"
   ```

### Testing the Workflow

Run the test script to verify everything is working:

```bash
./01-nil-optimization/test-workflow.sh
```

This will verify:
- The submodule is at the correct commit
- The patch applies cleanly
- The patched LispReader.java matches the version in patch/ directory
- Display the actual code changes

## How It Works

The `update-patch.sh` script uses these hardcoded values from the original patch:

- **Author:** Copilot <copilot@github.com>
- **Date:** Mon, 7 Oct 2024 20:00:00 +0000
- **Subject:** Optimize syntax-quote to make nil self-evaluating
- **Commit message:** (full message preserved as heredoc in the script)

This ensures that every regenerated patch maintains consistency with the original patch metadata.

## Notes

- The patch exclusively modifies `src/jvm/clojure/lang/LispReader.java` in the Clojure repository
- The submodule always stays clean (no uncommitted changes after running scripts)
- The commit SHA in the patch file will change each time, but the actual code changes remain identical
