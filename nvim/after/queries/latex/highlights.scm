;; extends

; Dim the math delimiters so the raw source on the cursor line reads like board A.
(displayed_equation
  "$$" @punctuation.delimiter)

(inline_formula
  "$" @punctuation.delimiter)
