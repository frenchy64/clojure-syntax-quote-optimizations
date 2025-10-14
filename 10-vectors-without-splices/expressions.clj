;; Minimal expressions most likely to compile differently with vectors-without-splices optimization patch
;; This patch optimizes vectors without splices to use vector literals instead of (apply vector (seq (concat ...)))

`[1 2]
`[:a ~x]
`[~x ~y]
`[~@v]
`[1 2 3]
`[[1 2]]
`[~(+ 1 2)]
`(conj [1] 2)
`{:vec [~a ~b]}
`(first [1 2 3])
