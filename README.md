# 32-bit Single-Cycle RISC-V Processor on FPGA

A complete, hardware-validated **32-bit RISC-V (RV32I) processor core** designed completely from scratch using **SystemVerilog**, synthesized in Xilinx Vivado, and deployed on a **Digilent Nexys A7-100T FPGA**. The system runs bare-metal software and has been rigorously validated using the industry-standard **EEMBC CoreMark** benchmark.

---

## 🚀 Key Features
- **ISA Compliance:** Implements the core **RV32I** instruction set architecture (32-bit fixed-length instructions, 32 general-purpose registers `x0`-`x31`)[cite: 6].
- **Modified Harvard Architecture:** Separate instruction and data memories (`instr_mem` and `data_mem`) implemented via FPGA Block RAM (BRAM).
- **Single-Cycle Datapath with FSM Stall Mechanism:** Designed as a single-cycle CPU (`CPI = 1`), integrated with a custom Finite State Machine (FSM) in `top.sv` to handle synchronous BRAM read latencies automatically via hardware `stall` signals.
- **Memory-Mapped I/O (MMIO):** Features integrated hardware peripherals:
  - **UART Transmitter/Receiver (9600 Baud, 8N1)** for live serial communication with a PC (PuTTY).
  - **32-bit Hardware Cycle Timer** mapped to memory for precise performance benchmarking.
- **Robust Software Toolchain:** Compiled using `xPack RISC-V GCC` (`-march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostartfiles`) with a custom linker script (`linker.ld`) and assembly boot routine (`start.S`).

---

## 📊 System Architecture (`top.sv`)
The top-level architecture integrates the CPU core, memories, and MMIO peripherals into a single 50 MHz clock domain:

```text
                  +-----------------------------------------+
                  |           Nexys A7 FPGA (50MHz)         |
                  |                                         |
+-------------+   |   +-------------+     +-------------+   |
|  instr_mem  |<--+-->|             |<--->| MMIO Decoder|<--+--> UART (PuTTY)
|  (BRAM 64K) |   |   |  riscv_cpu  |     +-------------+   |
+-------------+   |   |  (Single    |     |  HW Timer   |   |
                  |   |   Cycle)    |     +-------------+   |
+-------------+   |   |             |                     |
|  data_mem   |<--+-->|             |                     |
|  (BRAM 64K) |   |   +-------------+                     |
+-------------+   |          ^                              |
                  |          |                              |
                  |   +------+------+                       |
                  |   | FSM Control | (Generates 'stall')   |
                  |   +-------------+                       |
                  +-----------------------------------------+