---
tags:
  - fpga
  - cdc
created: 2026-10-07
sr-due: 2026-10-14
---

# Clock domain crossing

A signal launched in one clock domain and captured in another can violate the
capture flop's setup/hold window and go metastable. Every crossing needs a
synchronizer matched to what is crossing.

## Single bit: two-flop synchronizer

```systemverilog
module sync2 (
  input  logic clk,
  input  logic d,
  output logic q
);
  (* ASYNC_REG = "TRUE" *) logic meta;

  always_ff @(posedge clk)
    {q, meta} <= {meta, d};
endmodule
```

- the first flop may go metastable; the second gives it a full cycle to resolve
- MTBF grows exponentially with the resolution time, so add a third flop for fast clocks
- the input must come straight from a flop in the source domain (no combinational glitches)
- `ASYNC_REG` keeps both flops in one slice and out of retiming

## Multi-bit values

- never sync a bus bit by bit: bits resolve on different cycles
- counters: Gray-code them first, so only one bit changes per step
- arbitrary data: handshake (req/ack through `sync2`) or an async FIFO
- pulses: convert to a toggle, sync the toggle, edge-detect on the far side
