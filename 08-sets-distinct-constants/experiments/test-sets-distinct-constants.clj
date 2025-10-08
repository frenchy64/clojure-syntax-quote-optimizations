(ns test-sets-distinct-constants
  (:require [clojure.test :refer :all]))

(deftest test-set-with-distinct-constants
  (testing "Sets with distinct constant elements should compile to set literals"
    (is (= #{:a :b :c} `#{:a :b :c}))
    (is (= #{1 2 3} `#{1 2 3}))
    (is (= #{"x" "y"} `#{"x" "y"}))
    (is (= #{true false} `#{true false}))
    (is (= #{nil} `#{nil}))))

(deftest test-set-with-duplicate-constants
  (testing "Sets with duplicate constants should fail at compile-time"
    ;; This should be caught by the reader/compiler
    (is (thrown? Exception (eval '(let [] `#{:a :a}))))))

(deftest test-set-with-non-constant-elements
  (testing "Sets with non-constant elements should use verbose form"
    (let [x :a
          y :b]
      ;; Unquoted variables work fine
      (is (= #{:a :b} `#{~x ~y})))))

(deftest test-set-with-symbol-elements-should-not-optimize
  (testing "Sets with symbols as elements (not unquoted) should not optimize"
    ;; The symbol 'a' (not ~a) is not a self-evaluating constant
    ;; This is the bug case from the issue:
    ;; (let [a :a] `#{a :a})
    ;; If 'a' is incorrectly treated as a constant distinct from :a,
    ;; this would create #{a :a} as a literal
    ;; But at runtime, 'a' becomes a namespace-qualified symbol
    ;; and could evaluate to :a, causing a duplicate element error
    (is (thrown? Exception (eval '(let [a :a] `#{a :a}))))))

(deftest test-set-symbol-elements-runtime-behavior
  (testing "Symbol elements should be namespace-qualified and cause issues"
    ;; When we have `#{a :b}, the 'a' becomes namespace-qualified
    ;; This should NOT be optimized to a literal set
    (let [result (eval '(let [a :test] `#{a}))]
      ;; The result should contain a namespace-qualified symbol, not :test
      (is (symbol? (first result))))))

(run-tests)
