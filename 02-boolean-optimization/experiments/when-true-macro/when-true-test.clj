(ns when-true-test
  "A synthetic macro for testing boolean literal optimization in syntax-quote.
  
  This macro deliberately uses syntax-quoted boolean literals (true/false)
  that are NOT unquoted, to demonstrate the optimization impact.")

(defmacro when-true
  "A synthetic macro that returns :yes when the condition is true, :no otherwise.
  
  This macro is designed to demonstrate the boolean literal optimization.
  It uses a syntax-quoted (if true ...) expression to showcase how
  boolean literals are handled in syntax-quote."
  [condition]
  `(if ~condition
     (if true :yes :no)
     :no))

(defmacro when-false
  "A synthetic macro that returns :yes when the condition is false, :no otherwise.
  
  This macro uses a syntax-quoted (if false ...) expression to showcase how
  boolean literals are handled in syntax-quote."
  [condition]
  `(if (not ~condition)
     (if false :no :yes)
     :no))

;; Example usage:
;; (when-true true)   ;=> :yes
;; (when-true false)  ;=> :no
;; (when-false true)  ;=> :no  
;; (when-false false) ;=> :yes
