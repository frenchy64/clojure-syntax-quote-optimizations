# Experiment 1: Empty Collection Optimization

## Overview

This experiment measures the impact of optimizing syntax-quote to treat empty collections (`[]`, `{}`, `()`, `#{}`) as self-evaluating forms using reproducible builds methodology and professional comparison tools.

## Hypothesis

**Before**: 
- `` `[] `` => `(apply vector (seq (concat)))` - empty vector constructed via concat
- `` `{} `` => `(apply hash-map (seq (concat)))` - empty map constructed via concat
- `` `() `` => `(seq (concat))` - empty list constructed via concat
- `` `#{} `` => `(apply hash-set (seq (concat)))` - empty set constructed via concat

**After**: 
- `` `[] `` => `[]` - empty vector returned directly
- `` `{} `` => `{}` - empty map returned directly
- `` `() `` => `()` - empty list returned directly
- `` `#{} `` => `#{}` - empty set returned directly

**Expected Impact**: Eliminating unnecessary collection construction should:
1. Reduce AOT-compiled bytecode size significantly (empty collections are very common)
2. Simplify code generation for macros using empty collections
3. Improve macro expansion performance
4. Utilize cached empty collection constants

## Rationale

### Why This Optimization Makes Sense

1. **Consistency**: Other self-evaluating forms (keywords, numbers, strings, nil, booleans) are already optimized this way
2. **Semantics**: Empty collections are self-evaluating constants in Clojure
3. **Simplicity**: `[]` is much simpler than `(apply vector (seq (concat)))`
4. **Performance**: Uses cached empty collection singletons rather than constructing new ones
5. **Common Usage**: Empty collections appear very frequently in macros for:
   - Default values
   - Initialization
   - Conditional expressions
   - Return values

### Example Macro Impact

```clojure
;; Before optimization
(defmacro with-default [x]
  `(or ~x []))

;; Expands to (conceptually):
(or x (apply vector (seq (concat))))

;; After optimization
;; Expands to:
(or x [])
```

The difference is substantial - the optimized version generates much less bytecode and executes faster.

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

## Running the Experiment

### Prerequisites

```bash
sudo apt-get install strip-nondeterminism
```

### Execute

```bash
cd experiments/uberjar-comparison/
./01-empty-collection-optimization.sh
```

## Output Analysis

### Three Categories of Changes

1. **Java Source Changes** (LispReader.java)
   - Files: `LispReader-*-bytecode.txt`, `syntaxQuote-*.txt`
   - Impact: Additional empty collection check in `syntaxQuote()` method
   
2. **Clojure Compilation Strategy Changes**
   - Files: `changed-*-baseline.txt`, `changed-*-optimized.txt`
   - Impact: Different bytecode in macros using syntax-quoted empty collections
   
3. **Overall Size Impact**
   - Stripped JAR comparison for fair measurement
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
`src/jvm/clojure/lang/LispReader.java` - `SyntaxQuoteReader.syntaxQuote()` method

### Modification

```diff
 else if(form instanceof Keyword
         || form instanceof Number
         || form instanceof Character
-        || form instanceof String)
+        || form instanceof String
+        // Empty collections are self-evaluating
+        || (form instanceof IPersistentCollection && RT.count(form) == 0))
     ret = form;
```

## Interpretation Guide

### If Size Decreases (Positive Result)
✓ Optimization reduces bytecode overhead significantly  
✓ Evidence that collection construction has measurable cost  
✓ Confirms hypothesis  
✓ Expected to be larger impact than nil/boolean optimizations

### If Size Increases (Negative Result)
⚠ Optimization may have unexpected overhead  
⚠ Could indicate constant pool inflation  
⚠ Worth investigating bytecode diff

### If No Change (Neutral Result)
- Empty collection usage may be too infrequent to measure (unlikely)
- Compiler may already optimize this case (unlikely)
- Size difference below measurement precision

## Next Steps

After this experiment:
1. Document actual results in results/01-empty-collection-optimization/summary.txt
2. Analyze any significant bytecode differences
3. If successful, proceed to simple constant collection optimizations
4. If unsuccessful, investigate why and adjust approach

## Related Optimizations

This experiment builds on:
- Nil optimization (completed)
- Boolean optimization (completed)

And establishes the baseline for:
- Simple constant collections (next phase)
- Understanding collection optimization benefits
- Measuring granular optimization impacts

## See Also

- link:../../README.adoc[Empty Collection Optimization Subproject]
- link:../../../nil-optimization/experiments/uberjar-comparison/01-nil-optimization.md[Nil Optimization Experiment]
- link:../../../boolean-optimization/README.adoc[Boolean Optimization Subproject]
