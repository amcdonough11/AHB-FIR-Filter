# AHB-FIR-Filter
An AMBA AHB-Lite 4-point FIR filter in SystemVerilog with programmable 16-bit coefficients, streamable sample input, and status/error reporting.

## Overview

This design integrates an **AHB-Lite subordinate** (slave) with a 4-point FIR filter core. Software writes four 16-bit coefficients over AHB, streams 16-bit input samples into a register, and reads the 16-bit filtered output. The subordinate supports 8-bit and 16-bit accesses, reports invalid accesses via `HRESP`, and exposes status (idle/busy/error).

<p aligh="center">
  <img width="1200" height="400" alt="image" src="https://github.com/user-attachments/assets/c77be979-2196-4744-8364-46423ddede99" />
</p>

## Operation

<img width="500" height="198" alt="image" src="https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/FIR_Filter.svg/330px-FIR_Filter.svg.png" />

*From [Wikipedia - Finite Impulse Response](https://en.wikipedia.org/wiki/Finite_impulse_response)*

This figure captures the flow of an FIR filter operation. Each new input sample enters at x[n] and is passed through a series of unit delays (represented by (z^{-1}) ), shifting the signal to the right by one time step at each stage. Each delayed sample is multiplied by a corresponding coefficient (b_{i}), and the resulting products are summed to produce the output y[n]. 

This operation follows the discrete convolution equation represented by: 

<img width="550" height="240" alt="image" src="https://wikimedia.org/api/rest_v1/media/math/render/svg/c43ba6c329a471401e87fe17c6130d801602ffdf" />

*From [Wikipedia - Finite Impulse Response](https://en.wikipedia.org/wiki/Finite_impulse_response)*

This design is a 4-point FIR Filter, represented by this equation: 

$$\ y[n] = [
 (s_1 \cdot f_0) + (s_2 \cdot f_1) + (s_3 \cdot f_2) + (s_4 \cdot f_3)
\]$$

where:
- y[n] is the output each cycle
- $$s_x$$ are the four most-recent samples (e.g., $$\(s_1=x[n]\)$$, $$\(s_2=x[n-1]\)$$, $$\(s_3=x[n-2]\)$$, $$\(s_4=x[n-3]\))$$
- $$f_x$$ are the corresponding filter coefficients

Equivalent standard convolution form:

$$
y[n] = \sum_{k=0}^{3} h[k]\cdot x[n-k]
\text{ where } h[k] == f_k \text{ and } x[n-k] == s_{k+1}
$$

## Features

| Feature | Description |
|---|---|
| AHB-Lite Subordinate | Standard `HSEL/HADDR/HTRANS/HSIZE/HWRITE/HWDATA/HRDATA/HRESP` interface. No wait states (always ready). |
| 4-Point FIR | 16-bit unsigned samples × four 16-bit fixed point programmable coefficients. |
| Coefficient Loader | Write four coefficient registers then **arm** via a control register; loader copies them into the datapath and auto-clears the arm bit. |
| Sample Streaming | Write a sample to the **New Sample** register; the core latches, shifts the 4-deep sample window, and computes the output. |
| Output Register | Read the 16-bit unsigned filtered result from the **Result** register. |
| Status & Errors | Status shows IDLE/BUSY/ERROR. Arithmetic overflow is detected and reflected in Status; invalid addresses/sizes assert `HRESP=1`. |
| 8/16-bit Access | Supports byte or half-word transfers (`HSIZE=000` or `001`); registers are even-aligned. |

---

## What I Did
- Designed and implemented RTL in SystemVerilog for: `ahb_subordinate.sv`, `fir_filter.sv`, `coefficient_loader.sv`, `controller.sv`, `counter/flex_counter.sv`, `magnitude.sv`, `sync.sv`, and the top wrapper `ahb_fir_filter.sv`.
  *(Bus model BFM (`ahb_model.sv`) and `datapath.sv` provided as a simulation helper.)*
- Authored SystemVerilog testbenches (`tb_ahb_fir_filter.sv`) to verify configuration, coefficient loading, streaming, and error cases.
- Produced block/FSM diagrams to document the subordinate, loader, and controller behavior.  


---
## Repo Structure
```
├─ source/ # SystemVerilog RTL
│ ├─ ahb_subordinate.sv # AHB register interface & decode
│ ├─ ahb_fir_filter.sv # Top-level (AHB <-> FIR core)
│ ├─ fir_filter.sv # 4-point FIR core
│ ├─ coefficient_loader.sv
│ ├─ controller.sv # Control FSM 
│ ├─ datapath.sv # Multiplies, accumulator, overflow detect
│ ├─ magnitude.sv # 17b->16b magnitude/pack
│ ├─ counter.sv / flex_counter.sv
│ └─ sync.sv
├─ testbench/ # SystemVerilog testbenches & BFM
│ ├─ tb_ahb_fir_filter.sv
│ └─ ahb_model.sv # simple AHB-Lite BFM
├─ waves/ # Sample VCD/GTKW
├─ *.core # FuseSoC core files
├─ Makefile
└─ README.md
```

## Module Overview

- **ahb_subordinate.sv** — AHB-Lite address decode & register file; maps reads/writes, enforces `HSIZE`, returns `HRESP=1` on invalid access.
- **ahb_fir_filter.sv** — Top wrapper connecting AHB subordinate to coefficient loader, controller, datapath, and result/status.
- **fir_filter.sv** — 4-point FIR: 4-deep sample shift-array, coefficient multiply-accumulate, overflow detect.
- **coefficient_loader.sv** — Latches requested coefficients and updates active taps upon arm signal; auto-clears arm bit when done.
- **controller.sv** — Simple FSM: IDLE → LOAD_COEFFS → RUN, coordinates sample accept/compute, status bits, and 1k counter.
- **magnitude.sv** — Trims intermediate result (17-bit) to 16-bit magnitude as exposed on the bus.
- **datapath.sv** — Contains ALU for copy, load, add, sub and mul operations and Data Registers for storing values. 
- **counter/flex_counter.sv** — Counter used for the 1000-sample completion flag.
- **sync.sv** — 2-FF resynchronizers for any async inputs used in the TB.

## AHB-Lite Register Map
| HADDR | Size (Bytes) |Access| Description |
|---|---|---|---|
|0x0|2|Read Only| Status Reg: <br> 0 -> IDLE <br> 1 (bit 0) -> Busy <br> 256 (bit 8) -> Error |
|0x2|2|Read Only| Result Reg|
|0x4|2|Read/Write| New Sample Reg|
|0x6|2|Read/Write| F0 Coeff Reg|
|0x8|2|Read/Write| F1 Coeff Reg|
|0xA|2|Read/Write| F2 Coeff Reg|
|0xC|2|Read/Write| F3 Coeff Reg|
|0xE|1|Read/Write| New Coefficient Set Confirmation Reg: <br> - Set to 1 to activate <br> - Cleared to 0 when loading completed|

- Others: Invalid addresses return hresp = 1 (error).

## AHB-Lite Bus Signals

| Signal | Description |
|---|---|
| `HCLK` | Bus clock (`clk`). |
| `HRESETn` | Active-low reset (`n_rst`). |
| `HSEL` | Subordinate select. |
| `HTRANS[1:0]` | Transfer type. `NONSEQ` used for single transfers; `IDLE` cycles allowed. |
| `HADDR[3:0]` | Address bus (even-aligned half-word map shown above). |
| `HSIZE[2:0]` | Transfer size: `000`=8-bit, `001`=16-bit. Others treated as invalid (error). |
| `HWRITE` | 0=Read, 1=Write. |
| `HWDATA[15:0]` | Write data. |
| `HRDATA[15:0]` | Read data. |
| `HRESP` | 0=OK, 1=ERROR (invalid addr/size or blocked op). |
| `HREADY` | Not used (fixed ready, single-cycle data phase). |
| `HBURST/HPROT` | Not used. Single-beat transfers only/No protection control implemented |

---

## Diagrams 
FIR Filter Block Diagram: 
<img width="896" height="446" alt="image" src="https://github.com/user-attachments/assets/04b5d093-c1a6-4079-a615-7914bd3e2af8" />


FIR Filter State Machine:
<p aligh="center">
  <img width="1200" height="1800" alt="Screenshot 2025-08-07 173442" src="https://github.com/user-attachments/assets/367c117f-defa-43fc-bc6b-9c672d2e2b3e" />
</p>


Coefficient Loader State Machine:
<p aligh="center">
  <img width="600" height="900" alt="Screenshot 2025-08-07 173442" src="https://github.com/user-attachments/assets/1bdd137d-0dee-406f-ac37-aea82f1d0787" />
</p>

## Design Notes & Assumptions
- Samples and FIR output are 16 bit unsigned int values (0…65,535). Coefficents are UQ1.15 fixed point values ([0,2.0)). Additionally, the datapath MUL computes ( $$S_x \cdot 𝑓_x ) ≫ 15 $$ and returns a 16-bit unsigned result.
- Overflow Error results from ALU operation exceeding 16 bit limit (0…65,535). Status Reg will be become `0xd256`, indicating an error.
- Reading or writing to an invalid address with raise `HRESP`.
- FIR Filter Sync are only needed when inputs are asynchronous and are not used with AHB-Lite interface.
- FIR Filter has configurable High Pass Filter operation represented by $$y[n] = [(s_1 \cdot f_0) - (s_2 \cdot f_1) + (s_3 \cdot f_2) - (s_4 \cdot f_3)]$$. This can be accessed by setting parameter `HIGH_PASS_FILTER == 1`. Default is `HIGH_PASS_FILTER == 0`.

## Verification

**Loading Coefficients**

<img width="1000" height="430" alt="image" src="https://github.com/user-attachments/assets/46fbef5e-1200-4858-b420-39e719ff2e98" />

 1) Program Coefficient Values: Write values `1, 1.25, 1.5, 2` to `haddr` `0x6`, `0x8`, `0xA`, `0xC` (coefficients `F0..F3`). [Coeff Calc](https://chummersone.github.io/qformat.html)

2) Verify writes: Read back `haddr` `0x6`, `0x8`, `0xA`, `0xC` to confirm coefficient values.

3) Initiates Coefficient Loading: Write `1` to `haddr` `0xE` (New Coefficient Set Confirmation register) to request a load.

4) Loader handoff: The Coefficient Loader samples `0xE = 1` and commands the FIR to latch the pending coefficients.

5) Sequential load (busy): The FIR Filter loads `F0 → F3` one-by-one; `modwait` is asserted while the load is in progress.

6) Completion check: During loading, read of `haddr` `0xE` (and/or Status) to monitor progress. After Coefficient Loader begins loading, `0xE` auto-clears to `0`, confirming the new coefficients are set.

**Streaming Samples**

Streaming Sample Values: `{16'd00100, 16'd00200, 16'd00150, 16'd00101, 16'd04000, 16'd00900, 16'd00400, 16'd00001}`. 

Coefficients from loading example above.

First Sample (16'd00100):
<img width="1000" height="430" alt="image" src="https://github.com/user-attachments/assets/0c479a04-b56b-4c36-b943-daadd533b321" />

Final Sample (16'd00001):
<img width="1000" height="430" alt="image" src="https://github.com/user-attachments/assets/d711ee40-2a5b-4e6e-b6d8-09938c65b3f3" />

Final Output:
<img width="1000" height="430" alt="image" src="https://github.com/user-attachments/assets/4e78abad-5ea1-485b-bc37-60b30eb10926" />

Expected Values:

<img width="500" height="500" alt="image" src="https://github.com/user-attachments/assets/91657c4d-9a58-4fd7-9dc2-7e8dc0ad0096" />

*From [Rapid Tables](https://www.rapidtables.com/calc/math/convolution-calculator.html)*

Result Reg Values: `{16'd00100, 16'd00325, 16'd00550, 16'd00787, 16'd04750, 16'd06350, 16'd07726, 16'd09850, 16'd02400, 16'd00800, 16'd00001}`

1) Stream Samples: Each sample is written into the New Sample Reg (`0x4`) when Status Reg (`0x0`) is IDLE (`0`).
2) Compute:  The FIR grabs the new sample, asserts BUSY, performs the MAC over the 4-deep history, and produces new Result (`0x2`).
3) Read and Continue: When Status returns to IDLE, read Result Reg (`0x2`) and write the next sample.

## Synthesis Results




