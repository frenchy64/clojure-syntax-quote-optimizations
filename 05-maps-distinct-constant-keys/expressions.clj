;; Minimal expressions most likely to compile differently with maps-distinct-constant-keys optimization patch
;; This patch optimizes maps with distinct constant keys and non-unquote-splicing values to use map literals

`{:a 1 :b 2}
`{:x 1 :y 2 :z 3}
`{1 :a 2 :b}
`{"x" 1 "y" 2}
`{true :yes false :no}
`{nil 1 :x 2}
`[:a {:x 1 :y 2}]
`{:outer {:inner 1}}
`(foo {:k1 :v1 :k2 :v2})
`{:keyword 42 "str" true}
`{1 2 3 4 5 6}
