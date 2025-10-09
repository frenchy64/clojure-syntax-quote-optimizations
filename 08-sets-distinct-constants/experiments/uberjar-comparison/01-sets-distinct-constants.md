# Experiment 1: Sets with Distinct Constants Optimization

## Overview

This experiment measures the impact of optimizing syntax-quote to use set literals for sets with distinct constant elements, using reproducible builds methodology.

## Hypothesis

**Before**: 
- `` `#{:a :b :c} `` => `(apply hash-set (seq (concat (list :a) (list :b) (list :c))))`

**After (with distinct constants)**: 
- `` `#{:a :b :c} `` => `#{:a :b :c}`

**After (with non-constants or duplicates - preserved)**:
- `` `#{~x ~y} `` => `(apply hash-set (seq (concat (list x) (list y))))`
- `` `#{:a :a} `` => `(apply hash-set (seq (concat ...)))` (duplicate element)

**Expected Impact**: 
1. Reduce AOT-compiled bytecode size (sets with constant elements are common)
2. Improve runtime performance (set literals are faster than apply/concat)
3. Simplify generated code

**Safety**: The optimization checks:
- All elements must be constants (not unquoted variables)
- All elements must be distinct according to `Util.equiv`

## Rationale

Sets with constant elements appear in various contexts:
- **Enumeration values**: `` `#{:pending :running :complete} ``
- **Configuration options**: `` `#{:debug :info :warn :error} ``
- **Validation sets**: `` `#{:required :optional} ``
- **Type sets**: `` `#{String Number Boolean} ``

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
// Check if all elements are distinct constants
boolean hasDistinctConstants = false;
if(seq != null)
    {
    hasDistinctConstants = true;
    PersistentVector elements = PersistentVector.EMPTY;
    // Check each element
    for(ISeq s = seq; s != null; s = s.next())
        {
        Object element = s.first();
        // Element must be a self-evaluating constant (keyword, number, string, boolean, nil, char)
        if(!(element instanceof Keyword) && 
           !(element == null) &&
           !(element instanceof Number) &&
           !(element instanceof String) &&
           !(element instanceof Boolean) &&
           !(element instanceof Character))
            {
            hasDistinctConstants = false;
            break;
            }
        // Check if this element is distinct from previous elements
        for(ISeq e = elements.seq(); e != null; e = e.next())
            {
            if(Util.equiv(e.first(), element))
                {
                hasDistinctConstants = false;
                break;
                }
            }
        if(!hasDistinctConstants)
            break;
        elements = elements.cons(element);
        }
    }
// If all elements are distinct constants, use set literal
if(hasDistinctConstants && seq != null)
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
    ret = PersistentHashSet.create(RT.toArray(expanded));
    }
else
    ret = RT.list(APPLY, HASHSET, RT.list(SEQ, RT.cons(CONCAT, sqExpandList(seq))));
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
- Maps with distinct constant keys (experiment 05)
- Singleton sets optimization (experiment 07)
- Sets without splices (experiment 09)

And provides the most comprehensive set optimization by handling the common case of constant element sets.

## See Also

- link:../../README.adoc[Sets with Distinct Constants Optimization Subproject]
- link:../../../EXPERIMENT_PLAN.adoc[Complete Experiment Plan]
- link:../../../optimize-syntax-quote-full.patch[Full Optimization Patch]
