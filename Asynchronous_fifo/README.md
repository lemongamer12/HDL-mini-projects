# Asynchronous FIFO Design

This repository contains the RTL design and verification environment for an Asynchronous FIFO (First-In-First-Out) buffer. The design is implemented in Verilog and focuses on safe Clock Domain Crossing (CDC) using Gray code pointers and 2-Flip-Flop synchronizers.

## Project Overview

Asynchronous FIFOs are used to transfer data between independent clock domains without causing metastability or data corruption. This project implements a 16-depth, 8-bit wide FIFO, paired with a SystemVerilog testbench that verifies functional correctness, backpressure handling, and pointer wraparound scenarios.

## Design Architecture and CDC Strategy

Passing multi-bit pointers across asynchronous clock domains introduces the risk of metastability. This design mitigates that risk using Gray code, where only one bit changes between successive numbers. This ensures the 2-FF synchronizer can safely capture the pointer without sampling a transient, invalid state.

For example, when transitioning from 3 to 4:
* Normal binary coding: 3 (011) to 4 (100) changes all three bits, creating a high probability of misinterpretation.
* Gray coding: 3 (010) to 4 (110) changes only one bit.

The binary-to-Gray conversion is implemented using the formula:
`G_ptr = (B_ptr >> 1) ^ B_ptr`

The pointer width is calculated as `log2(Number of locations)`. For a 16-location memory, a 4-bit address is used, requiring a 5-bit pointer to detect wrap-around conditions.

### Flag Generation
The status flags are generated in their respective clock domains to avoid crossing domains for control signals:
* **Full Flag:** Generated in the write clock domain using the synchronized read pointer.
* **Empty Flag:** Generated in the read clock domain using the synchronized write pointer.

## Module Hierarchy

The design is structured into modular blocks to maintain clarity and ease of debugging:

* `async_fifo`: Top-level module integrating the memory, pointers, and synchronizers.
* `wptr_handler`: Manages the write binary pointer, converts it to Gray code, and generates the full flag.
* `rptr_handler`: Manages the read binary pointer, converts it to Gray code, and generates the empty flag.
* `synchronizer`: A 2-Flip-Flop (2-FF) synchronizer chain to safely cross clock domains.
* `b2g_converter`: Purely combinational Binary-to-Gray code converter.
* `dual_port_memory`: 16x8 register-based dual-port memory array.

## Verification

Functional verification was performed using a SystemVerilog testbench equipped with a reference model to ensure data integrity under various conditions.

### Test Scenarios

1. **Fill to Full**: Writes data until the full flag asserts, verifying write backpressure.
2. **Drain to Empty**: Reads data until the empty flag asserts, verifying correct data ordering.
3. **Concurrent Stress Test**: Runs randomized simultaneous reads and writes to test pointer wraparound and continuous operation.
4. **Mid-Operation Reset**: Verifies safe recovery from an asynchronous reset while the FIFO is active.

### Simulation Results

```text
Phase 1: fill to full
[159000] full correctly asserted, wrote 15 entries

Phase 2: drain to empty
[413000] empty correctly asserted, read 15 entries

Phase 3: concurrent read/write, pointer wraparound stress
Phase 4: reset while active

----------------------------------------
TEST PASSED: 99 writes, 99 reads, 0 errors
----------------------------------------
