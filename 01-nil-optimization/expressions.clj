;; Minimal expressions most likely to compile differently with nil optimization patch
;; This patch makes `nil self-evaluating instead of (quote nil)

`nil
`(nil)
`[nil]
`{:a nil}
`#{nil}
`(foo nil)
`[nil nil]
`{nil :a}
`(if nil true false)
`(let [x nil] x)
