# Experiment 1: Simple Constant Collections Optimization

## Overview

This experiment measures the impact of optimizing syntax-quote to treat collections containing only constants as quotable forms using reproducible builds methodology and professional comparison tools.

## Hypothesis

**Before**: 
- `` `[1 2 3] `` => `(apply vector (seq (concat (list 1) (list 2) (list 3))))` - vector constructed via concat
- `` `{:a 1 :b 2} `` => `(apply hash-map (seq (concat (list :a) (list 1) (list :b) (list 2))))` - map constructed via concat
- `` `#{:x :y} `` => `(apply hash-set (seq (concat (list :x) (list :y))))` - set constructed via concat

**After**: 
- `` `[1 2 3] `` => `(quote [1 2 3])` - vector wrapped in quote
- `` `{:a 1 :b 2} `` => `(quote {:a 1 :b 2})` - map wrapped in quote
- `` `#{:x :y} `` => `(quote #{:x :y})` - set wrapped in quote

**Expected Impact**: Wrapping constant collections in quote should:
1. Significantly reduce AOT-compiled bytecode size (constant collections are very common)
2. Simplify code generation for macros using constant data structures
3. Improve macro expansion performance dramatically
4. Enable better constant propagation in the compiler
5. Utilize compile-time evaluation more effectively

## Rationale

### Why This Optimization Makes Sense

1. **Massive Simplification**: `(quote [1 2 3])` is far simpler than `(apply vector (seq (concat (list 1) (list 2) (list 3))))`
2. **Semantic Equivalence**: Both evaluate to the exact same constant value
3. **Common Pattern**: Constant collections appear frequently in:
   - Configuration data
   - Default values and parameters
   - Lookup tables and mappings
   - Test fixtures
   - Documentation examples
4. **Builds on Previous Work**: Extends nil, boolean, and empty collection optimizations
5. **Compiler-Friendly**: Quoted constants are easier for the compiler to optimize

### Example Macro Impact

```clojure
;; Before optimization
(defmacro lookup-table []
  `{:success 200 :not-found 404 :error 500})

;; Expands to (conceptually):
(apply hash-map (seq (concat (list :success) (list 200) (list :not-found) (list 404) (list :error) (list 500))))

;; After optimization
;; Expands to:
(quote {:success 200 :not-found 404 :error 500})
```

The difference is enormous - the optimized version generates minimal bytecode and can be evaluated at compile-time.

## Methodology

This experiment uses reproducible builds methodology with efficient comparison:

1. **Baseline**: Official Clojure 1.12.3 JAR from Maven Central (SHA256 verified)
2. **Optimized**: Current branch built with same procedure as releases
3. **Comparison**: Extract and compare class files using checksums for fast identification
4. **Bytecode Analysis**: Detailed `javap` comparison of changed classes

### Key Features

- Uses official release as baseline for stability
- Strips timestamps with `strip-nondeterminism` for fair comparison
- Custom efficient class file comparison (faster than diffoscope for CI)
- Separates Java source changes from Clojure compilation changes

### Reference Implementation

This experiment takes inspiration from https://github.com/frenchy64/clojure/pull/41[PR #41], which contains the full optimization that we are breaking down into smaller pieces. The complete patch is available at the root of this repository as `optimize-syntax-quote-full.patch`.

## Running the Experiment

### Prerequisites

```bash
sudo apt-get install strip-nondeterminism
```

### Execute

```bash
cd experiments/uberjar-comparison/
./01-simple-constant-collections.sh
```

## Output Analysis

### Three Categories of Changes

1. **Java Source Changes** (LispReader.java)
   - Files: `LispReader-*-bytecode.txt`, `syntaxQuote-*.txt`
   - Impact: Additional constant collection detection logic in `syntaxQuote()` method
   - New helper methods: `isQuoteLiftable()`, `isAllQuoteLiftable()`, `sqLiftQuoted()`
   
2. **Clojure Compilation Strategy Changes**
   - Files: `changed-*-baseline.txt`, `changed-*-optimized.txt`
   - Impact: Different bytecode in macros using syntax-quoted constant collections
   - Much simpler bytecode for constant data structures
   
3. **Overall Size Impact**
   - Stripped JAR comparison for fair measurement
   - Expected larger reduction than previous optimizations
   - Exact byte count and percentage reduction

### Reports Generated

- `summary.txt` - Complete analysis with interpretation
- `class-differences.txt` - List of all changed/added/removed class files
- `*-bytecode.txt` - Individual class bytecode comparisons
- `optimized-stripped.sha256` - For reproducibility verification

## Reproducibility

- Baseline JAR verified against: `7d5eaa5b31d4c5ab12e4df90aeb4e8ba85c1a6cc279120b69f44f3eb1abca9ba`
- Optimized stripped JAR SHA256 recorded for verification
- All tools are deterministic
- Results should be identical across runs

## Code Change

### Location
`src/jvm/clojure/lang/LispReader.java` - `SyntaxQuoteReader.syntaxQuote()` method and new helper methods

### Key Modifications

1. **New Helper Methods**: `isQuoteLiftable()`, `isAllQuoteLiftable()`, `sqLiftQuoted()`
2. **Vector Handling**: Check if all elements are constants before expansion
3. **List Handling**: Check if all elements are constants before expansion
4. **Set Handling**: Check if all elements are constants before expansion
5. **Map Handling**: Check if all keys and values are constants before expansion

The optimization detects when all elements of a collection are constants and wraps the entire collection in a quote instead of generating construction code.

## Interpretation Guide

### If Size Decreases (Expected Result)
✓ Optimization significantly reduces bytecode overhead  
✓ Constant collections are common enough to measure  
✓ Evidence that quote wrapping is much more efficient  
✓ Confirms hypothesis

### If Size Increases (Unexpected Result)
⚠ Optimization may have unexpected overhead  
⚠ Could indicate constant pool inflation  
⚠ Worth investigating bytecode diff carefully

### If Small Change (Possible Result)
- Constant collections may be less common than expected
- Many collections may have unquoted elements
- Optimization still valuable for affected cases

## Next Steps

After this experiment:
1. Document actual results in results/01-simple-constant-collections/summary.txt
2. Analyze significant bytecode differences
3. Consider micro-benchmarks for macro expansion performance
4. If successful, proceed to more advanced constant optimizations
5. If unsuccessful, investigate why and adjust approach

## Related Optimizations

This experiment builds on:
- Nil optimization (completed)
- Boolean optimization (completed)
- Empty collection optimization (completed)

And establishes the baseline for:
- Constant collection lifting (more sophisticated constant folding)
- Mixed constant/unquote collections
- Understanding advanced optimization benefits

## See Also

- link:../../README.adoc[Simple Constant Collections Optimization Subproject]
- link:../../../01-nil-optimization/experiments/uberjar-comparison/01-nil-optimization.md[Nil Optimization Experiment]
- link:../../../02-boolean-optimization/README.adoc[Boolean Optimization Subproject]
- link:../../../03-empty-collection-optimization/experiments/uberjar-comparison/01-empty-collection-optimization.md[Empty Collection Optimization Experiment]
- https://github.com/frenchy64/clojure/pull/41[PR #41: Full Optimization Implementation]
