# Experiment 1: Maps with Distinct Constant Keys Optimization

## Overview

This experiment measures the impact of optimizing syntax-quote to use map literals for maps with distinct constant keys, using reproducible builds methodology.

## Hypothesis

**Before**: 
- `` `{:a ~x :b ~y} `` => `(apply hash-map (seq (concat (list :a) (list x) (list :b) (list y))))`

**After (with distinct constant keys)**: 
- `` `{:a ~x :b ~y} `` => `{:a x :b y}`

**After (with non-constant or duplicate keys - preserved)**:
- `` `{~k ~v} `` => `(apply hash-map (seq (concat (list k) (list v))))`

**Expected Impact**: 
1. Reduce AOT-compiled bytecode size (maps with constant keys are ubiquitous)
2. Improve runtime performance (map literals are faster than apply/concat)
3. Simplify generated code

**Safety**: The optimization checks:
- All keys must be constants (not unquoted variables)
- All keys must be distinct according to `Util.equiv`

## Rationale

Maps with constant keyword keys appear everywhere in Clojure:
- **Configuration maps**: `` `{:timeout ~ms :retries ~n} ``
- **Keyword arguments**: `` `(fn [& {:keys [~opt]}] ...) ``
- **Let destructuring**: `` `(let [{:keys [~x ~y]} ~expr] ...) ``
- **Record/deftype definitions**: Constants in syntax-quoted forms

This is likely one of the highest-impact optimizations because keyword maps are the most common data structure in idiomatic Clojure code.

## Reproducibility

To verify this experiment:
1. Clone this repository
2. Run the experiment script
3. Compare the SHA256 checksum in `optimized-stripped.sha256` with documented value

## Code Change

The patch modifies the `IPersistentMap` case in `LispReader.java`:

```java
ISeq seq = keyvals.seq();
// Check if all keys are distinct constants
boolean hasDistinctConstantKeys = false;
if(seq != null && (seq.count() % 2) == 0 && seq.count() > 0)
    {
    hasDistinctConstantKeys = true;
    PersistentVector keys = PersistentVector.EMPTY;
    // Check each key (even-indexed position: 0, 2, 4, ...)
    int idx = 0;
    for(ISeq s = seq; s != null; s = s.next(), idx++)
        {
        if(idx % 2 == 0) // This is a key position
            {
            Object key = s.first();
            // Key must be a self-evaluating constant (keyword, number, string, boolean, nil, char)
            if(isUnquote(key) || isUnquoteSplicing(key) ||
               (key instanceof Symbol) ||
               (key instanceof ISeq) ||
               (key instanceof IPersistentCollection && !(key instanceof Keyword)))
                {
                hasDistinctConstantKeys = false;
                break;
                }
            // Check if this key is distinct from previous keys
            for(ISeq k = keys.seq(); k != null; k = k.next())
                {
                if(Util.equiv(k.first(), key))
                    {
                    hasDistinctConstantKeys = false;
                    break;
                    }
                }
            if(!hasDistinctConstantKeys)
                break;
            keys = keys.cons(key);
            }
        }
    }
// If all keys are distinct constants, use map literal
if(hasDistinctConstantKeys)
    {
    // Expand each element through syntax-quote
    PersistentVector expanded = PersistentVector.EMPTY;
    for(ISeq s = seq; s != null; s = s.next())
        {
        Object item = s.first();
        if(isUnquote(item))
            expanded = expanded.cons(RT.second(item));
        else
            expanded = expanded.cons(syntaxQuote(item));
        }
    ret = PersistentArrayMap.createAsIfByAssoc(RT.toArray(expanded));
    }
else
    ret = RT.list(APPLY, HASHMAP, RT.list(SEQ, RT.cons(CONCAT, sqExpandList(seq))));
```

**Important**: A "constant" is a self-evaluating form whose value is known at compile-time (keywords, numbers, strings, booleans, nil, characters). Symbols are NOT constants because they reference bindings whose values are only known at runtime.

## Results

### JAR Size Comparison

Results will be documented after running the experiment.

### Affected Classes

Classes affected by this optimization will be listed after running the experiment.

### Bytecode Analysis

Detailed bytecode differences will be analyzed after running the experiment.

## Related Optimizations

This experiment builds on:
- Singleton maps optimization (experiment 04)
- Maps without splices (experiment 06)

And provides the most comprehensive map optimization by handling the common case of constant keyword keys.

## See Also

- link:../../README.adoc[Maps with Distinct Constant Keys Optimization Subproject]
- link:../../../EXPERIMENT_PLAN.adoc[Complete Experiment Plan]
- link:../../../optimize-syntax-quote-full.patch[Full Optimization Patch]
