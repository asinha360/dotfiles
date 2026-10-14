---
tags:
  - probability
  - quant
created: 2026-10-10
sr-due: 2026-10-17
---

# Conjugate priors

A prior is conjugate to a likelihood when the posterior stays in the prior's
family, so updating is just arithmetic on its parameters.

$$p \sim \operatorname{Beta}(\alpha, \beta), \quad k \mid p \sim \operatorname{Bin}(n, p) \;\Rightarrow\; p \mid k \sim \operatorname{Beta}(\alpha + k,\ \beta + n - k)$$

- α and β act as pseudo-counts of prior successes and failures
- normal likelihood with known variance: normal prior on the mean stays normal
- Poisson rate: gamma prior, posterior $\operatorname{Gamma}(\alpha + \sum x_i,\ \beta + n)$
