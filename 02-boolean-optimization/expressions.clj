;; Minimal expressions most likely to compile differently with boolean optimization patch
;; This patch makes `true and `false self-evaluating instead of (quote true) and (quote false)

`true
`false
`(true)
`[true false]
`{:a true}
`#{true false}
`(if true :yes :no)
`(and true false)
`{true :a false :b}
`[true true false]
