# Note on Patch Status

The `simple-constant-collections.patch` file is currently **NOT READY** for automated testing.

## Issue

The patch was extracted from PR #41's full optimization but has formatting corruption issues that prevent it from applying cleanly. The error is "corrupt patch at line 163".

## Root Cause

The patch extraction process didn't properly preserve the git diff format when removing nil/boolean optimizations. The diff hunks (@@ lines) and context became misaligned.

## Next Steps

To fix this, we need to:
1. Apply the full patch to a clean Clojure checkout
2. Manually revert the nil, boolean, and empty collection optimizations
3. Generate a fresh `git diff` that only contains the constant collection optimization
4. Add proper patch header with GitHub Copilot attribution

## Workaround

For now, the experiment can be run using `optimize-syntax-quote-full.patch` which includes all optimizations. This allows testing the infrastructure while the targeted patch is being fixed.
