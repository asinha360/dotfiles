---
tags:
  - linear-algebra
  - quant
created: 2026-10-07
sr-due: 2026-10-14
---

# Spectral theorem

A real symmetric matrix diagonalizes in an orthonormal basis:

$$A = Q\Lambda Q^\top, \qquad Q^\top Q = I$$

- eigenvalues are real; eigenvectors for distinct λ are orthogonal
- the Rayleigh quotient is bounded by the top eigenvalue:

$$\max_{\|x\|=1} x^\top A x = \lambda_{\max}$$

## Why it matters for portfolios

$$\operatorname{Var}(w^\top X) = w^\top \Sigma w$$

- Σ is symmetric PSD, so the riskiest unit w is its top eigenvector.
- PCA on returns is this decomposition, sorted by λ.
