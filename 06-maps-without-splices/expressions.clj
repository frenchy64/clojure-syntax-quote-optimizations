;; Minimal expressions most likely to compile differently with maps-without-splices optimization patch
;; This patch optimizes maps without splices to use (hash-map ...) instead of (apply hash-map (seq (concat ...)))

`{:a 1 :b 2}
`{:x ~x :y ~y}
`{~k ~v}
`{1 2 3 4}
`{:a 1 :b 2 :c 3}
`{~@m}
`[{:a ~a}]
`{:key ~(+ 1 2)}
`{{:nested :map} :value}
`(merge {:a 1} {:b 2})
