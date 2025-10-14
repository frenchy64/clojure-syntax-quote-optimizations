;; Minimal expressions most likely to compile differently with sets-distinct-constants optimization patch
;; This patch optimizes sets with distinct constant elements to use set literals

`#{1 2 3}
`#{:a :b :c}
`#{"x" "y" "z"}
`#{true false}
`#{nil 1 2}
`#{:keyword 42 "str"}
`[#{1 2}]
`#{1 2 3 4 5}
`{:set #{:x :y}}
`(into #{} [1 2 3])
