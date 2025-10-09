# Distinct Constant Keys Map Macro Bytecode Comparison

This directory contains scripts to compare the bytecode of a compiled macro that uses maps with distinct constant keys between baseline Clojure 1.12.3 and the optimized version.

## Test Macro

The experiment uses this minimal macro:

```clojure
(defmacro test-distinct-keys-map [x y z]
  `{:a ~x :b ~y :c ~z})
```

This macro demonstrates the optimization where syntax-quoted maps with distinct constant keys (`:a`, `:b`, `:c`) are compiled to direct map literals instead of verbose `(apply hash-map (seq (concat ...)))` constructions.

## What This Measures

The bytecode comparison shows **Effect #1** of the optimization: how the macro's *definition* is compiled to bytecode. The optimization affects:

1. The size of the macro's compiled classfile
2. The complexity of bytecode instructions
3. The constant pool usage

See `DISTINCT_KEYS_MAP_OPTIMIZATION_ANALYSIS.adoc` for a comprehensive explanation of all three effects (macro definition, expansion performance, and runtime execution).

## Running the Experiment

```bash
./compare-macro-bytecode.sh
```

## Expected Results

The script compiles the test macro with both baseline and optimized Clojure, then uses `javap` to disassemble the bytecode. Expected observations:

**Baseline version:**
- Complex construction using `apply`, `hash-map`, `seq`, `concat`
- Multiple `list` calls (2 per key-value pair)
- ~150-200 bytes for the construction code
- 6+ nested INVOKESTATIC instructions

**Optimized version:**
- Direct map literal using `PersistentArrayMap.createAsIfByAssoc`
- Load constants and arguments directly
- ~40-60 bytes
- Single INVOKESTATIC instruction

**Reduction:** Approximately 60-75% reduction in bytecode size for the macro definition.

## Output

The script generates:
- `baseline-bytecode.txt`: Full bytecode disassembly from baseline Clojure
- `optimized-bytecode.txt`: Full bytecode disassembly from optimized Clojure
- Console output showing size comparison and key differences

## Dependencies

- `curl` - to download baseline Clojure JAR
- `sha256sum` - to verify JAR integrity
- `javap` - Java disassembler (included with JDK)
- `java`/`javac` - Java compiler and runtime
- `diff` - to compare bytecode
- Maven - to build the optimized version (via shared build script)

## Why This Matters

Maps with distinct constant keys are extremely common in Clojure:
- Keyword argument maps: `{:timeout 1000 :retries 3}`
- Destructuring: `{:keys [x y z]}`
- Configuration maps: `{:host "localhost" :port 8080}`
- API requests: `{:method :get :url "/api/users"}`

This optimization likely provides the **highest impact** of all syntax-quote optimizations because keyword maps are so pervasive in Clojure codebases.

## See Also

- `../DISTINCT_KEYS_MAP_OPTIMIZATION_ANALYSIS.adoc` - Detailed analysis
- `../../uberjar-comparison/` - Full uberjar size comparison experiment
- `../../../README.adoc` - Overview of the maps-distinct-constant-keys optimization
