(ns test-maps-distinct-constant-keys
  (:require [clojure.test :refer :all]))

(deftest test-map-with-distinct-constant-keys
  (testing "Maps with distinct constant keys should compile to map literals"
    (is (= {:a 1 :b 2} `{:a 1 :b 2}))
    (is (= {:foo 1 :bar 2} `{:foo ~1 :bar ~2}))
    (is (= {1 :a 2 :b} `{1 :a 2 :b}))
    (is (= {"x" 1 "y" 2} `{"x" 1 "y" 2}))
    (is (= {true 1 false 2} `{true 1 false 2}))
    (is (= {nil 1} `{nil 1}))))

(deftest test-map-with-duplicate-constant-keys
  (testing "Maps with duplicate constant keys should fail at compile-time"
    ;; This should be caught by the reader/compiler
    (is (thrown? Exception (eval '(let [] `{:a 1 :a 2}))))))

(deftest test-map-with-non-constant-keys
  (testing "Maps with non-constant keys should use verbose form"
    (let [a :a
          b :b]
      ;; Symbol 'a' in the map is not a self-evaluating constant
      ;; so this should NOT be optimized to a map literal
      ;; and should work correctly at runtime
      (is (= {:a 1 :b 2} `{~a 1 ~b 2})))))

(deftest test-map-with-symbol-keys-should-not-optimize
  (testing "Maps with symbols as keys (not unquoted) should not optimize"
    ;; The symbol 'a' (not ~a) is not a self-evaluating constant
    ;; This should throw an error at runtime because the symbol
    ;; will be namespace-qualified and then evaluated
    ;; The key point is it should NOT optimize to a literal
    (let [a :a]
      ;; `{a :a}` should expand to something that will fail if 'a' is not defined
      ;; or produce the wrong result if there's another 'a' in scope
      ;; This is the bug we're catching - it should NOT become {:a :a} literally
      (is (not= {a :a} (eval '(let [a :a] `{a :a})))))))

(deftest test-map-with-symbol-keys-runtime-error
  (testing "Symbol keys evaluated at different times should cause runtime error with duplicates"
    ;; This is the specific case from the bug report:
    ;; (let [a :a] `{a :a})
    ;; If 'a' is treated as a constant :a, this would create {:a :a}
    ;; which is fine. But the expansion should be (hash-map `a :a)
    ;; which becomes (hash-map user/a :a) at read time
    ;; This should either fail or produce a map with the symbol as key
    (is (thrown? Exception (eval '(let [a :a] `{a :a}))))))

(run-tests)
