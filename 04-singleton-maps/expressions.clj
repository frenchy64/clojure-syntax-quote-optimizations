;; Minimal expressions most likely to compile differently with singleton maps optimization patch
;; This patch optimizes 1-entry maps without splices to use map literals instead of (apply hash-map ...)

`{:a 1}
`{:key "value"}
`{1 2}
`{"a" "b"}
`{true false}
`{nil 0}
`{:x ~x}
`[{:a 1}]
`({:k :v})
`(foo {:bar 42})
