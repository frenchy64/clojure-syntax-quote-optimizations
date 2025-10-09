# Maps with Distinct Constant Keys Macro Bytecode Comparison

This experiment analyzes the bytecode impact of the "maps with distinct constant keys" optimization on a minimal test macro.

## Overview

The optimization transforms syntax-quoted maps where all keys are distinct constants (like `:a`, `:b`, `:c`) from verbose construction code to simple map literals.

**Test Macro:**
```clojure
(defmacro test-distinct-constant-keys [x y z]
  `{:a ~x :b ~y :c ~z})
```

This macro is ideal for testing because:
- It uses exactly the pattern the optimization targets
- All keys are constant keywords
- All keys are distinct
- Values are unquoted arguments

## What This Measures

This experiment measures **Effect #1**: The bytecode size and complexity of the compiled macro definition itself.

The optimization should reduce macro definition bytecode by approximately 60-80% by replacing complex nested structures with simple map literal construction.

## Running the Experiment

```bash
cd distinct-constant-keys-scripts
./compare-macro-bytecode.sh
```

The script will:
1. Download baseline Clojure 1.12.3
2. Build optimized Clojure with experiment 05's patch
3. Compile the test macro with both versions
4. Disassemble and compare bytecode using `javap`
5. Report bytecode size differences

## Expected Results

**Before optimization:**
- Complex nested structure with multiple `list`, `concat`, `seq`, `apply` calls
- Estimated: 120-180 bytes of bytecode

**After optimization:**
- Direct map literal construction
- Estimated: 40-60 bytes of bytecode

**Expected reduction: 60-80%**

## Understanding the Three Effects

See `DISTINCT_CONSTANT_KEYS_OPTIMIZATION_ANALYSIS.adoc` for detailed analysis of:

1. **Effect #1**: Macro definition bytecode (measured by this script)
2. **Effect #2**: Macro expansion performance (implicitly improved)
3. **Effect #3**: Runtime execution speed (10-20x faster map construction)

## Why This Matters

Keyword-keyed maps are ubiquitous in Clojure:
- Let-destructuring: `{:keys [...]}`
- Keyword arguments: `[& {:keys [...]}]`
- Configuration maps: `{:host ~h :port ~p}`

This is likely the highest-impact syntax-quote optimization.

## Dependencies

- `curl` - for downloading baseline Clojure
- `sha256sum` - for verifying downloads
- `java` / `javac` - for compiling and running
- `javap` - for disassembling bytecode
- Maven - for building optimized Clojure

## Artifacts

All generated files are saved in `/tmp/distinct-constant-keys-bytecode-compare-$$` including:
- `clojure-baseline.jar` - Baseline Clojure 1.12.3
- `clojure-optimized.jar` - Optimized Clojure with patch
- `test_macro.clj` - Test macro source
- `baseline-classes/` - Compiled classes with baseline
- `optimized-classes/` - Compiled classes with optimization
