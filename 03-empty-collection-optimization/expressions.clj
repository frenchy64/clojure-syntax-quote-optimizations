;; Minimal expressions most likely to compile differently with empty collection optimization patch
;; This patch makes `[], `{}, `(), `#{} self-evaluating instead of complex expansions

`[]
`{}
`()
`#{}
`[[]]
`[{}]
`{:a []}
`(foo [])
`(let [x []] x)
`[[] {} () #{}]
