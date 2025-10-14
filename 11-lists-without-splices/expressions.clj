;; Minimal expressions most likely to compile differently with lists-without-splices optimization patch
;; This patch optimizes lists without splices to use (list ...) instead of (seq (concat ...))

`(1 2)
`(:a ~x)
`(~x ~y)
`(~@l)
`(1 2 3)
`((1 2))
`(foo bar)
`(+ 1 2)
`{:list (a b)}
`(first (1 2 3))
