(ns test-sets-without-splices
  (:require [clojure.test :refer :all]))

(deftest test-set-without-splice
  (testing "Sets without splices should compile to (hash-set ...)"
    (let [a 1 b 2 c 3]
      (is (= #{1 2 3} `#{~a ~b ~c}))
      (is (= #{:a :b} `#{:a :b}))
      (is (= #{} `#{}))
      (is (= #{42} `#{~a}) "Singleton set without splice"))))

(deftest test-set-with-splice
  (testing "Sets with splices should compile to (apply hash-set (seq (concat ...)))"
    (let [xs [1 2 3]
          a 4]
      (is (= #{1 2 3 4} `#{~@xs ~a}))
      (is (= #{1 2 3} `#{~@xs}))
      (is (= #{} `#{~@[]}))))
  (testing "Mixed splice and non-splice"
    (let [xs [1 2]
          y 3
          zs [4 5]]
      (is (= #{1 2 3 4 5} `#{~@xs ~y ~@zs})))))

(run-tests)
