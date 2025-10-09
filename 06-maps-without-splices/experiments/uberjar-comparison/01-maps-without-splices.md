# Experiment 1: Maps Without Splices Optimization

## Overview

This experiment measures the impact of optimizing syntax-quote to use more direct map construction for maps without top-level splices (`~@`), using reproducible builds methodology.

## Hypothesis

**Before**: 
- `` `{:a ~x :b ~y} `` => `(apply hash-map (seq (concat (list :a) (list x) (list :b) (list y))))`

**After**: 
- `` `{} `` => `{}`
- `` `{:a ~x} `` => `{:a x}`
- `` `{:a ~x :b ~y} `` => `(hash-map :a x :b y)`

**Expected Impact**: 
1. Reduce AOT-compiled bytecode size (maps without splices are extremely common)
2. Simplify code generation by avoiding concat/seq/apply
3. Improve macro expansion performance
4. Better runtime performance for maps without dynamic splicing

**Safety**: When there are no splices, the map structure is known at compile time, allowing direct construction.

## Rationale

Maps without splices appear in:
- **Most map literals in macros**: `` `{:name ~name :value ~value} ``
- **Destructuring forms**: `` `(let [{:keys [~x ~y]} ~expr] ...) ``
- **Configuration maps**: `` `{:timeout ~ms :retries ~n} ``
- **Keyword arguments**: `` `(fn [& {:keys [~opt1 ~opt2]}] ...) ``

The vast majority of syntax-quoted maps don't use splices. By using more direct construction, we expect measurable improvements across the entire Clojure codebase.

## Reproducibility

To verify this experiment:
1. Clone this repository
2. Run the experiment script
3. Compare the SHA256 checksum in `optimized-stripped.sha256` with documented value

## Code Change

The patch modifies the `IPersistentMap` case in `LispReader.java`:

```java
ISeq seq = keyvals.seq();
// `{~@k ~@v} => (apply hash-map (concat k v))
if(hasSplice(seq))
    ret = RT.list(APPLY, HASHMAP, RT.cons(CONCAT, sqExpandList(seq)));
// `{} => {}
else if(seq == null)
    ret = PersistentArrayMap.EMPTY;
// `{k v} => {`k `v}
else if(seq.count() == 2)
    ret = PersistentArrayMap.createAsIfByAssoc(RT.toArray(sqExpandFlat(seq)));
// `{k v ...} => (hash-map k v ...)
else
    ret = RT.cons(HASHMAP, sqExpandFlat(seq));
```

Helper functions:
- `hasSplice(ISeq seq)` - Detects top-level splices (`~@`)
- `sqExpandFlat(ISeq seq)` - Flattens for use with direct calls

## Results

### JAR Size Comparison

Results will be documented after running the experiment.

### Affected Classes

Classes affected by this optimization will be listed after running the experiment.

### Bytecode Analysis

Detailed bytecode differences will be analyzed after running the experiment.

## Related Optimizations

This experiment builds on:
- Empty collection optimization (experiment 03) - handles `{}`
- Singleton maps optimization (experiment 04) - handles `{:a ~x}`

And establishes the baseline for:
- Maps with distinct constant keys (experiment 05) - potential future optimization

## See Also

- link:../../README.adoc[Maps Without Splices Optimization Subproject]
- link:../../../EXPERIMENT_PLAN.adoc[Complete Experiment Plan]
- link:../../../optimize-syntax-quote-full.patch[Full Optimization Patch]
