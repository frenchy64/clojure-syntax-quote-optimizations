(ns empty-vector-test
  "A test macro for empty collection literal optimization in syntax-quote.
  
  This macro deliberately uses syntax-quoted empty collection literals
  that are NOT unquoted, to demonstrate the optimization impact.")

(defmacro with-default-vector
  "A macro that returns the provided value or an empty vector if nil.
  
  This macro uses a syntax-quoted empty vector to showcase how
  empty collections are handled in syntax-quote."
  [x]
  `(or ~x []))

(defmacro with-default-map
  "A macro that returns the provided value or an empty map if nil.
  
  This macro uses a syntax-quoted empty map to showcase how
  empty collections are handled in syntax-quote."
  [x]
  `(or ~x {}))

(defmacro with-default-set
  "A macro that returns the provided value or an empty set if nil.
  
  This macro uses a syntax-quoted empty set to showcase how
  empty collections are handled in syntax-quote."
  [x]
  `(or ~x #{}))

(defmacro with-default-list
  "A macro that returns the provided value or an empty list if nil.
  
  This macro uses a syntax-quoted empty list to showcase how
  empty collections are handled in syntax-quote."
  [x]
  `(or ~x ()))

;; Example usage:
;; (with-default-vector nil)   ;=> []
;; (with-default-vector [1 2]) ;=> [1 2]
;; (with-default-map nil)      ;=> {}
;; (with-default-map {:a 1})   ;=> {:a 1}
;; (with-default-set nil)      ;=> #{}
;; (with-default-set #{1 2})   ;=> #{1 2}
;; (with-default-list nil)     ;=> ()
;; (with-default-list '(1 2))  ;=> (1 2)
