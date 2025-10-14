;; Minimal expressions most likely to compile differently with singleton-sets optimization patch
;; This patch optimizes 1-element sets without splices to use set literals instead of (apply hash-set ...)

`#{1}
`#{:key}
`#{"string"}
`#{true}
`#{nil}
`#{~x}
`[#{:a}]
`(#{1})
`{:set #{:val}}
`(conj #{42} 1)
