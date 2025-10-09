# Singleton Map Optimization Verification Scripts

This directory contains scripts for verifying and analyzing the singleton map optimization in Clojure's syntax-quote reader.

## Scripts

### compare-macro-bytecode.sh

Compares the bytecode of a test macro that uses singleton maps between baseline Clojure 1.12.3 and the optimized version.

**What it measures:** Effect #1 (macro definition bytecode changes)

**How to run:**
```bash
./compare-macro-bytecode.sh
```

**Expected results:**
- The macro definition bytecode should be smaller (60-80 byte reduction)
- The compiled macro should eliminate references to `apply`, `hash-map`, `seq`, `concat` vars
- The optimized version should use direct map literal construction

**Output files** (saved to `/tmp/singleton-map-bytecode-compare-*`):
- `macro-baseline.javap`: Baseline macro bytecode disassembly
- `macro-optimized.javap`: Optimized macro bytecode disassembly
- `macro.diff`: Differences between baseline and optimized
- `use-baseline.javap`: Baseline usage site bytecode
- `use-optimized.javap`: Optimized usage site bytecode
- `use.diff`: Differences in usage site (Effect #3)

## Test Macro

The scripts compile and analyze this test macro:

```clojure
(defmacro test-singleton-map
  "A minimal macro that returns a syntax-quoted singleton map."
  [x]
  `{:a ~x})
```

This macro demonstrates the singleton map optimization in its simplest form:
- Uses syntax-quote with a map containing exactly one entry
- Has a constant key (`:a`)
- Has an unquoted value (`~x`)

## Dependencies

- `curl`: For downloading baseline Clojure
- `sha256sum`: For verifying downloads
- `java`/`javac`: For compiling test code
- `javap`: For disassembling bytecode
- `diff`: For comparing bytecode

## See Also

- [SINGLETON_MAP_OPTIMIZATION_ANALYSIS.adoc](../SINGLETON_MAP_OPTIMIZATION_ANALYSIS.adoc): Detailed analysis of the optimization
- [../../README.adoc](../../README.adoc): Singleton Maps Optimization Subproject
- [../../../EXPERIMENT_PLAN.adoc](../../../EXPERIMENT_PLAN.adoc): Complete Experiment Plan
