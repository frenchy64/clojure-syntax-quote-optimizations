# Experiment 1: Singleton Maps Optimization

## Overview

This experiment measures the impact of optimizing syntax-quote to use map literals for singleton maps (maps with exactly one key-value pair) using reproducible builds methodology.

## Hypothesis

**Before**: 
- `` `{:a ~x} `` => `(apply hash-map (seq (concat (list :a) (list x))))`

**After**: 
- `` `{:a ~x} `` => `{:a x}`

**Expected Impact**: 
1. Reduce AOT-compiled bytecode size (singleton maps are common in let-destructuring, keyword args)
2. Simplify code generation for macros using singleton maps
3. Improve macro expansion performance by eliminating concat/apply overhead

**Safety**: Singleton maps trivially satisfy the distinct-keys requirement since there's only one entry.

## Rationale

Singleton maps appear frequently in:
- **Let-destructuring**: `` `(let [{:keys [~x]} ~expr] ...) ``
- **Keyword arguments**: `` `(fn [& {:keys [~opt]}] ...) ``
- **Single configuration entries**: `` `{:timeout ~ms} ``

By using map literals instead of verbose construction code, we expect measurable bytecode and performance improvements.

## Methodology

This experiment uses reproducible builds methodology with efficient comparison:

1. **Baseline**: Official Clojure 1.12.3 JAR from Maven Central (SHA256 verified)
2. **Optimized**: Current branch built with same procedure as releases
3. **Comparison**: Extract and compare class files using checksums for fast identification
4. **Bytecode Analysis**: Detailed `javap` comparison of changed classes

### Key Features

- Uses official release as baseline for stability
- Strips timestamps with `strip-nondeterminism` for fair comparison (or stubbed version)
- Custom efficient class file comparison (faster than diffoscope for CI)
- Separates Java source changes from Clojure compilation changes

## Running the Experiment

### Prerequisites

```bash
sudo apt-get install strip-nondeterminism
# OR use the stubbed version if unavailable
```

### Execute

```bash
cd experiments/uberjar-comparison/
./01-singleton-maps.sh
```

## Output Analysis

### Three Categories of Changes

1. **Java Source Changes** (LispReader.java)
   - Files: `LispReader-*-bytecode.txt`, `syntaxQuote-*.txt`
   - Impact: Additional singleton map check in `syntaxQuote()` method
   
2. **Clojure Compilation Strategy Changes**
   - Files: `changed-*-baseline.txt`, `changed-*-optimized.txt`
   - Impact: Different bytecode in macros using syntax-quoted singleton maps
   
3. **Overall Size Impact**
   - Stripped JAR comparison for fair measurement
   - Exact byte count and percentage reduction

### Reports Generated

- `summary.txt` - Complete analysis with interpretation
- `class-differences.txt` - List of all changed/added/removed class files
- `*-bytecode.txt` - Individual class bytecode comparisons
- `optimized-stripped.sha256` - For reproducibility verification

## Reproducibility

To verify this experiment:
1. Clone this repository
2. Run the experiment script
3. Compare the SHA256 checksum in `optimized-stripped.sha256` with documented value

## Code Change

The patch modifies the `IPersistentMap` case in `LispReader.java`:

```java
ISeq seq = keyvals.seq();
// Optimize singleton maps: `{:a ~x} => {:a x}
if(seq != null && seq.count() == 2 && !hasSplice(seq))
    ret = PersistentArrayMap.createAsIfByAssoc(RT.toArray(sqExpandFlat(seq)));
else
    ret = RT.list(APPLY, HASHMAP, RT.list(SEQ, RT.cons(CONCAT, sqExpandList(seq))));
```

Helper functions:
- `hasSplice(ISeq seq)` - Detects top-level splices (`~@`)
- `sqExpandFlat(ISeq seq)` - Flattens for use with map literals

## Interpretation Guide

### If Size Decreases (Positive Result)
✓ Optimization reduces bytecode overhead  
✓ Singleton maps are common enough to measure  
✓ Confirms hypothesis

### If Size Increases (Negative Result)
⚠ Optimization may have unexpected overhead  
⚠ Could indicate constant pool inflation  
⚠ Helper functions may add more cost than savings

### If No Change (Neutral Result)
- Singleton maps may be too infrequent
- Effect below measurement precision
- May need to examine specific macro cases

## Next Steps

After this experiment:
1. Document actual results in results/01-singleton-maps/summary.txt
2. Analyze any significant bytecode differences
3. If successful, proceed to maps with distinct constant keys (experiment 05)
4. If unsuccessful, investigate specific use cases

## Related Optimizations

This experiment builds on:
- Nil optimization (experiment 01)
- Boolean optimization (experiment 02)
- Empty collection optimization (experiment 03)

And establishes the baseline for:
- Maps with distinct constant keys (experiment 05)
- Maps without splices (experiment 06)

## See Also

- link:../../README.adoc[Singleton Maps Optimization Subproject]
- link:../../../EXPERIMENT_PLAN.adoc[Complete Experiment Plan]
- link:../../../optimize-syntax-quote-full.patch[Full Optimization Patch]
