# Verification of Sets Without Splices Optimization

## Issue
The original `09-sets-without-splices/sets-without-splices.patch` had a breaking change where sets with splices would not work properly.

## Root Cause
The patch was using `RT.cons(HASHSET, sqExpandList(seq))` for all non-empty sets, which creates:
```clojure
(hash-set `a b `c)
```

However, `sqExpandList` is designed for concat operations. When it encounters a splice (~@), it returns the splice value directly, which would create invalid syntax like:
```clojure
(hash-set `a splice-value `c)
```

Instead of the correct:
```clojure
(apply hash-set (seq (concat (list `a) splice-value (list `c))))
```

## Solution
The corrected patch now:
1. Checks if any element in the set is a splice
2. If yes: uses `(apply hash-set (seq (concat ...)))` - the original verbose form
3. If no: uses `(hash-set ...)` - the optimized form

## Code Change
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

## Test Cases

### Without Splices (Optimized)
- `#{~a ~b ~c}` → `(hash-set a b c)`
- `#{:a :b}` → `(hash-set :a :b)`
- `#{}` → Would be handled elsewhere (not by this patch)

### With Splices (Preserve Original)
- `#{~@xs}` → `(apply hash-set (seq (concat xs)))`
- `#{~@xs ~a}` → `(apply hash-set (seq (concat xs (list a))))`
- `#{~@xs ~y ~@zs}` → `(apply hash-set (seq (concat xs (list y) zs)))`

This ensures backward compatibility while providing optimization for the common case (no splices).
