# Experiment 1: Sets Without Splices Optimization

## Overview

This experiment measures the impact of optimizing syntax-quote to use more direct set construction for sets without top-level splices (`~@`), using reproducible builds methodology.

## Hypothesis

**Before**: 
- `` `#{:a :b :c} `` => `(apply hash-set (seq (concat (list :a) (list :b) (list :c))))`

**After**: 
- `` `#{} `` => `#{}`
- `` `#{:a} `` => `#{:a}`
- `` `#{:a :b :c} `` => `(hash-set :a :b :c)`

**Expected Impact**: 
1. Reduce AOT-compiled bytecode size (sets without splices are common)
2. Simplify code generation by avoiding concat/seq/apply
3. Improve macro expansion performance
4. Better runtime performance for sets without dynamic splicing

**Safety**: When there are no splices, the set structure is known at compile time, allowing direct construction.

## Rationale

Sets without splices appear in:
- **Protocol/interface specifications**: `` `#{~protocol1 ~protocol2} ``
- **Tag sets**: `` `#{:required :optional} ``
- **Set literals in macros**: Various uses of sets in macro expansions

The majority of syntax-quoted sets don't use splices. By using more direct construction, we expect measurable improvements.

## Reproducibility

To verify this experiment:
1. Clone this repository
2. Run the experiment script
3. Compare the SHA256 checksum in `optimized-stripped.sha256` with documented value

## Code Change

The patch modifies the `IPersistentSet` case in `LispReader.java`:

```java
ISeq seq = ((IPersistentSet) form).seq();
// Check if there are any splices
boolean hasSplice = false;
for(ISeq s = seq; s != null; s = s.next())
    {
    if(isUnquoteSplicing(s.first()))
        {
        hasSplice = true;
        break;
        }
    }
// `#{~@a b ~@c} => (apply hash-set (seq (concat a [b] c)))
if(hasSplice)
    ret = RT.list(APPLY, HASHSET, RT.list(SEQ, RT.cons(CONCAT, sqExpandList(seq))));
// `#{a b c} => (hash-set `a `b `c)
else
    ret = RT.cons(HASHSET, sqExpandList(seq));
```

This patch checks for splices and only optimizes sets without them, using only existing functions from the codebase.

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
- Singleton sets optimization (experiment 07) - handles `#{:a}`

And establishes comprehensive set optimization coverage.

## See Also

- link:../../README.adoc[Sets Without Splices Optimization Subproject]
- link:../../../EXPERIMENT_PLAN.adoc[Complete Experiment Plan]
- link:../../../optimize-syntax-quote-full.patch[Full Optimization Patch]
