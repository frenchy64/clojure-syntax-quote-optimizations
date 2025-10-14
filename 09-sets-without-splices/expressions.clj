;; Minimal expressions most likely to compile differently with sets-without-splices optimization patch
;; This patch optimizes sets without splices to use (hash-set ...) instead of (apply hash-set (seq (concat ...)))

`#{1 2}
`#{:a ~x}
`#{~x ~y}
`#{~@s}
`#{1 2 3}
`[#{:a :b}]
`#{~(inc 1)}
`(conj #{1} 2)
`{:set #{~a ~b}}
`#{#{1}}
