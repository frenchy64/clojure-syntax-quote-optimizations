# Experiment 1: Singleton Sets Optimization

## Overview

This experiment measures the impact of optimizing syntax-quote to use set literals for singleton sets (sets with exactly one element) using reproducible builds methodology.

## Hypothesis

**Before**: 
- `` `#{:a} `` => `(apply hash-set (seq (concat (list :a))))`

**After**: 
- `` `#{:a} `` => `#{:a}`

**Expected Impact**: 
1. Reduce AOT-compiled bytecode size
2. Simplify code generation for macros using singleton sets
3. Improve macro expansion performance by eliminating concat/apply overhead

**Safety**: Singleton sets trivially satisfy the distinct-elements requirement since there's only one element.

## Rationale

Singleton sets appear in:
- **Protocol/interface specifications**: `` `#{~protocol} ``
- **Single-tag sets**: `` `#{:required} ``
- **Macro-generated sets**: Various macro expansions that create sets with one element

By using set literals instead of verbose construction code, we expect measurable bytecode and performance improvements.

## Reproducibility

To verify this experiment:
1. Clone this repository
2. Run the experiment script
3. Compare the SHA256 checksum in `optimized-stripped.sha256` with documented value

## Code Change

The patch modifies the `IPersistentSet` case in `LispReader.java`:

```java
ISeq seq = ((IPersistentSet) form).seq();
// `#{~@a b ~@c} => (apply hash-set (concat a [b] c))
```java
ISeq seq = ((IPersistentSet) form).seq();
// `#{a} => #{`a}
if(seq != null && seq.count() == 1)
    ret = PersistentHashSet.create(RT.toArray(syntaxQuote(seq.first())));
else
    ret = RT.list(APPLY, HASHSET, RT.list(SEQ, RT.cons(CONCAT, sqExpandList(seq))));
```

This minimal patch uses only existing functions from the codebase (`syntaxQuote` and `sqExpandList`).

## Results

### JAR Size Comparison

Results will be documented after running the experiment.

### Affected Classes

Classes affected by this optimization will be listed after running the experiment.

### Bytecode Analysis

Detailed bytecode differences will be analyzed after running the experiment.

## Related Optimizations

This experiment builds on:
- Empty collection optimization (experiment 03) - handles `#{}`
- Singleton maps optimization (experiment 04) - similar pattern for maps

And establishes the baseline for:
- Sets with distinct constants (experiment 08)
- Sets without splices (experiment 09)

## See Also

- link:../../README.adoc[Singleton Sets Optimization Subproject]
- link:../../../EXPERIMENT_PLAN.adoc[Complete Experiment Plan]
- link:../../../optimize-syntax-quote-full.patch[Full Optimization Patch]
