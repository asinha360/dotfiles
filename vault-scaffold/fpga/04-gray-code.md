---
tags:
  - fpga
  - cdc
created: 2026-10-09
sr-due: 2026-10-16
---

# Gray-code pointers

An async FIFO passes its read and write pointers across clock domains. Binary
counters can flip many bits at once, so a synchronizer may sample a value that
never existed. Gray code changes exactly one bit per increment, so a sampled
pointer is either the old value or the new one.

$$g = b \oplus (b \gg 1)$$

- convert to Gray in the source domain, register, then `sync2` each bit
- full/empty are computed on Gray pointers with one extra wrap bit
- the synchronized pointer lags by two cycles, so flags are pessimistic, never wrong
