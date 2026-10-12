# RISC-V RV32I Processor on FPGA — EEMBC CoreMark Validated

[![CoreMark Score](https://img.shields.io/badge/CoreMark%2FMHz-0.44-blue)](results/coremark_output.txt)
[![ISA](https://img.shields.io/badge/ISA-RV32I%2FM-green)](https://riscv.org/technical/specifications/)
[![FPGA](https://img.shields.io/badge/FPGA-Nexys%20A7--100T-orange)](https://digilent.com/reference/programmable-logic/nexys-a7/start)
[![HDL](https://img.shields.io/badge/HDL-SystemVerilog-blueviolet)]()
[![License](https://img.shields.io/badge/License-MIT-lightgrey)]()

A fully functional 32-bit **single-cycle RISC-V processor** designed from scratch in SystemVerilog and deployed on the Digilent **Nexys A7-100T** FPGA. Validated end-to-end with the official **EEMBC CoreMark** benchmark — achieving bit-exact CRC results against the published reference tables.

This is the full source release accompanying my Bachelor's thesis at the **Polytechnic University of Tirana (UPT)**, Faculty of Technology and Information.

---

## Results

| Metric | Value |
|---|---|
| CoreMark Score (Iterations/Sec) | **21.99** |
| CoreMark/MHz | **0.44** |
| Clock Frequency | 50 MHz |
| Total Ticks | 682,227,558 |
| Iterations | 300 |
| Execution Time | 13.64 s |
| CRC `crclist` | `0xe714` ✅ |
| CRC `crcmatrix` | `0x1fd7` ✅ |
| CRC `crcstate` | `0x8e3a` ✅ |
| FPGA LUT Utilization | ~7% |
| BRAM Utilization | ~24% |
| Validation | `Correct operation validated` |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    FPGA — Nexys A7-100T                     │
│                                                             │
│  ┌──────────┐   instr[31:0]   ┌─────────────┐              │
│  │instr_mem │ ──────────────► │  riscv_cpu  │              │
│  │ BRAM 64K │ ◄── pc[31:0] ── │  (ISA+path) │              │
│  └──────────┘                 └──────┬──────┘              │
│                                      │ data_addr/we         │
│  ┌──────────┐                 ┌──────▼──────┐  ┌─────────┐ │
│  │ data_mem │ ◄───────────── │FSM (top.sv) │  │  UART   │ │
│  │ BRAM 64K │ ───read_data──► │  5-state    │  │9600baud │ │
│  └──────────┘                 └─────────────┘  └────┬────┘ │
│                                                      │      │
└──────────────────────────────────────────────────────┼──────┘
                                                       │ serial
                                                   PuTTY / PC
```

### Key Design Decisions

**Modified Harvard Architecture** — separate instruction memory (`instr_mem`) and data memory (`data_mem`), both implemented as synchronous Block RAM (BRAM). This is the central architectural challenge of the design.

**5-State FSM for BRAM Synchronization** — because synchronous BRAM requires 1 clock cycle to return read data, a pure single-cycle design is not directly implementable. The FSM (`S_FETCH1 → S_FETCH2 → [S_DECODE_LOAD → S_LOAD_WAIT →] S_EXEC`) handles the synchronization, inserting wait states only for LOAD instructions from real RAM.

```
Instruction Type    |  Clock Cycles (physical)
--------------------|-------------------------
R-type / I-ALU      |  2
BRANCH / JAL / JALR |  2
STORE               |  2  (fire-and-forget)
LOAD from MMIO      |  2–3
LOAD from RAM       |  4
```

**Stall Signal** — `stall = (state != S_EXEC)` freezes the PC and register file while the FSM is not in the execution state. This is fundamentally different from inserting NOP instructions: the PC does not advance, no new instruction begins, and the hardware manages it transparently to software.

**MMIO Peripherals** — UART TX/RX and a hardware cycle counter are memory-mapped at `0x80000000+`, allowing bare-metal C code to interact with them through simple pointer dereferences.

---

## Repository Structure

```
riscv-fpga-coremark/
├── rtl/                    # SystemVerilog source (13 modules)
│   ├── top.sv              # Top-level: FSM, MMIO decoder, clock divider
│   ├── riscv_cpu.sv        # CPU core wrapper + cycle counter
│   ├── riscv_isa.sv        # Control unit / instruction decoder (pure combinational)
│   ├── datapath.sv         # Datapath: PC, Register File, ALU, muxes, aligner
│   ├── alu.sv              # ALU: RV32I + M-extension (MUL/DIV/REM)
│   ├── register_file.sv    # 32×32-bit register file, async read / sync write
│   ├── imm_extender.sv     # Immediate sign-extension (I/S/B/U/J formats)
│   ├── pc_reg.sv           # (declared, not instantiated — PC is in datapath)
│   ├── instr_mem.sv        # Instruction BRAM 64 KB, $readmemh from memfile.dat
│   ├── data_mem.sv         # Data BRAM 64 KB, byte-enable (SB/SH/SW)
│   ├── baud_gen.sv         # Baud rate generator (N=326 → 9600 baud @ 50 MHz)
│   ├── uart_tx.sv          # UART transmitter FSM (8N1)
│   └── uart_rx.sv          # UART receiver FSM (connected, rx unused by software)
│
├── firmware/               # Bare-metal C + Assembly
│   ├── start.S             # Reset vector: SP/GP init, .bss clear, jump to main()
│   ├── linker.ld           # Memory map: .text @0x0, .data/.bss @0x10000
│   ├── core_portme.c       # CoreMark porting layer (timer, serial output)
│   ├── core_portme.h
│   └── ee_printf.c         # Minimal printf (no stdlib dependency)
│
├── constraints/
│   └── nexys_a7.xdc        # Pin constraints for Nexys A7-100T
│
├── docs/
│   ├── thesis/
│   │   └── Relacioni_Diplome_RISCV.pdf
│   ├── presentation/
│   │   └── Prezantimi_Diplome_RISCV.pptx
│   └── figures/            # Architecture diagrams (PNG)
│       ├── fig_toplevel.png
│       ├── fig_datapath.png
│       ├── fig_fsm.png
│       └── ...
│
└── results/
    └── coremark_output.txt # Captured PuTTY terminal output
```

---

## How to Build & Run

### Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Xilinx Vivado | 2022.2+ | Synthesis, implementation, bitstream |
| xPack RISC-V GCC | 15.2.0 | `riscv-none-elf-gcc` |
| Python 3 | any | `make_hex.py` (bin → memfile.dat) |
| PuTTY / minicom | any | Serial terminal (COM port, 9600 8N1) |

### Step 1 — Compile CoreMark firmware

```bash
cd firmware/

riscv-none-elf-gcc \
  -march=rv32i -mabi=ilp32 \
  -O2 -ffreestanding -nostartfiles -nostdlib \
  -T linker.ld \
  start.S core_portme.c ee_printf.c \
  ../coremark/core_main.c \
  ../coremark/core_list_join.c \
  ../coremark/core_matrix.c \
  ../coremark/core_state.c \
  ../coremark/core_util.c \
  -o firmware.elf

riscv-none-elf-objcopy -O binary firmware.elf firmware.bin
python3 make_hex.py firmware.bin memfile.dat
```

> **Note:** Use `-march=rv32i` (not `rv32im`). The hardware MUL/DIV unit exists in `alu.sv` but is not timing-safe at 50 MHz without an additional wait state. Division falls back to libgcc software routines.

### Step 2 — Vivado Project

1. Open Vivado → **Create Project** → RTL Project
2. Add all files from `rtl/` as design sources
3. Add `memfile.dat` as a **Design Source** (not Simulation Source) — Vivado must find it at synthesis time for `$readmemh`
4. Add `constraints/nexys_a7.xdc` as a constraint
5. **Generate Bitstream** → Program Device

### Step 3 — Run

1. Program the Nexys A7 via Vivado Hardware Manager
2. Open PuTTY → Serial → COM port @ **9600 baud, 8N1**
3. Press the **CPU_RESETN** button on the board
4. Watch the terminal — expected output in ~14 seconds:

```
[CHECK 1] Inicializimi i harduerit kaloi.
[CHECK 2] Fillimi i krijimit te te dhenave ne RAM...
[CHECK 3] Te dhenat u ngarkuan me sukses ne RAM!
[STARTO] Po filloj testin zyrtar te CoreMark...
[FUND] Testi mbaroi, po llogaris rezultatet...

2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 682227558
Total time (secs): 13
Iterations/Sec   : 23
Iterations       : 300
Compiler version : GCC 15.2.0
Compiler flags   : -O2 -march=rv32i -mabi=ilp32 -ffreestanding
Memory location  : RAM
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x5275
Correct operation validated. See README.md for run and reporting rules.

--- CoreMark Perfundoi! CPU e Ngrire. ---
```

---

## Module Overview

| Module | Type | Function |
|---|---|---|
| `top.sv` | Mixed | Top-level: 5-state FSM, MMIO decoder, clock divider (100→50 MHz) |
| `riscv_cpu.sv` | Mixed | CPU wrapper, cycle counter (hardware timer for CoreMark) |
| `riscv_isa.sv` | Combinational | Instruction decoder → control signals (reg_write, alu_control, ...) |
| `datapath.sv` | Mixed | PC, Register File, ALU, byte aligner, write-back mux |
| `alu.sv` | Combinational | RV32I arithmetic/logic + M-extension MUL/DIV/REM |
| `register_file.sv` | Mixed | 32×32-bit, async read (×2), sync write (×1), x0 hardwired to 0 |
| `imm_extender.sv` | Combinational | Sign-extends immediates for all 5 RISC-V immediate formats |
| `instr_mem.sv` | Sync | 64 KB BRAM, read-only, pre-loaded via `$readmemh` |
| `data_mem.sv` | Sync | 64 KB BRAM, byte-enable write (SB/SH/SW), read with 1-cycle latency |
| `baud_gen.sv` | Sequential | Clock divider for 9600 baud (N=326 at 50 MHz) |
| `uart_tx.sv` | Sequential | Serial transmitter, 8N1, 4-state FSM |
| `uart_rx.sv` | Sequential | Serial receiver (instantiated, rx_done_tick unused by firmware) |

---

## Known Limitations & Future Work

- **CPI > 1 in practice:** The 5-state FSM means LOAD from RAM costs 4 physical clock cycles, giving an average ~2–4 cycles per instruction versus the ideal 1. This is the primary reason CoreMark/MHz is lower than pipelined commercial cores (ARM Cortex-M0: 2.33, Cortex-M4: 3.54).
- **MUL/DIV hardware not timing-safe @ 50 MHz:** The combinational divider exceeds the 20 ns critical path. Activating `-march=rv32im` requires either a reduced clock or an additional FSM wait state.
- **No branch prediction:** All branch outcomes are resolved in S_EXEC — no speculation.

**Planned improvements:**
- [ ] 5-stage pipeline (IF/ID/EX/MEM/WB) with forwarding and hazard detection
- [ ] L1 instruction and data caches
- [ ] Activate M-extension with a proper multi-cycle divide unit
- [ ] Branch prediction (at least static predict-not-taken)

---

## Thesis & Documentation

The full Bachelor's thesis (in Albanian) is available in `docs/thesis/`. It covers:
- RISC-V ISA fundamentals and instruction encoding
- Hardware architecture (FSM, datapath, Harvard memory model)
- Software toolchain and bare-metal porting
- All debugging challenges encountered (X-propagation, off-by-one FSM bug, Vivado pwropt crash, CoreMark algorithm issues)
- Performance analysis and comparison

---

## Author

**Samuel Koçi**
Bachelor of Electronics Engineering — Polytechnic University of Tirana (UPT)
GitHub: [@samuelkoci](https://github.com/samuelkoci)
LinkedIn: [samuel-koci](https://linkedin.com/in/samuel-koci)

---

## License

MIT — see [LICENSE](LICENSE) for details.

The CoreMark benchmark itself is copyright EEMBC and subject to its own license. The firmware porting layer (`core_portme.c/h`) is original work and MIT-licensed.
