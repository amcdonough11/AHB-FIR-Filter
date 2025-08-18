# FIR-Filter
AHB Finite Impulse Response (FIR) Filter Design

## Overview

This is a design for a 4-point FIR Filter interfaced with an AHB subordinate. The design processes 16-bit input samples using 4 configurable 16-bit coefficients to produce a 16-bit filtered output, which can be accessed via the AHB bus. This is designed for discrete convolution in an AHB-based SoC. 

<img width="1200" height="400" alt="image" src="https://github.com/user-attachments/assets/bf8a5d37-8aad-457e-ab41-c38a2d5dbb48" />


## Operation

<img width="500" height="198" alt="image" src="https://github.com/user-attachments/assets/3a47c0db-5eda-46bd-a502-fd80a7a9ded7" />

*From [Wikipedia - Finite Impulse Response](https://en.wikipedia.org/wiki/Finite_impulse_response)*

This figure captures the flow of an FIR filter operation. Each new input sample enters at x[n] and is passed through a series of unit delays (represented by (z^{-1}) ), shifting the signal to the right by one time step at each stage. Each delayed sample is multiplied by a corresponding coefficient (b_{i}), and the resulting products are summed to produce the output y[n]. 

This operation follows the discrete convolution equation represented by: 

<img width="550" height="240" alt="image" src="https://github.com/user-attachments/assets/7d998c03-7729-4383-9c44-883825030b3b" />

*From [Wikipedia - Finite Impulse Response](https://en.wikipedia.org/wiki/Finite_impulse_response)*

This design is a 4-point FIR Filter, meaning 4 coefficients and 4 delayed input samples are used to compute each output. 

## Structure 

- ahb_fir_filter.sv: Top-level module

- ahb_subordinate.sv: Manages AHB-Lite bus transactions and register access

- fir_filter.sv: Implements the FIR filter core

- coefficient_loader.sv: Handles loading and clearing of FIR coefficients

- controller.sv: Controls FIR filter operations via a state machine

- counter.sv, flex_counter.sv: Track sample counts (up to 1000 samples)

- magnitude.sv: Converts 17-bit filter output to 16-bit magnitude

- sync.sv: Synchronizes asynchronous inputs

- datapath.sv: Perform arithmetic operations (multiply, add, subtract) for the FIR filter

## Features 

- AHB-Lite Interface: Supports 8-bit and 16-bit transfers for configuration and data access

- FIR Filter: Processes 16-bit samples with four programmable coefficients

- Dynamic Coefficient Loading: Updates coefficients via AHB writes, triggered by a control register

- Sample Tracking: Signals completion after processing 1000 samples (one_k_samples)

- Error Handling: Detects arithmetic overflow, reported via the status register

- Synchronous Design: Operates with a single clock (clk) and active-low reset (n_rst)

## AHB Memory Map
| HADDR | Size (Bytes) |Access| Description |
|---|---|---|---|
|0x0|2|Read Only| Status Reg: <br> 0 -> IDLE <br> 1 -> Busy <br> 2 -> Error |
|0x2|2|Read Only| Result Reg|
|0x4|2|Read/Write| New Sample Reg|
|0x6|2|Read/Write| F0 Coeff Reg|
|0x8|2|Read/Write| F1 Coeff Reg|
|0xA|2|Read/Write| F2 Coeff Reg|
|0xC|2|Read/Write| F3 Coeff Reg|
|0xE|1|Read/Write| New Coefficient Set Confirmation Reg: <br> - Set to 1 to activate <br> - Cleared to 0 when loading completed|

- Others: Invalid addresses return hresp = 1 (error).

## Usage

1. Integration:
  - Instantiate ahb_fir_filter in an AHB-based SoC.
  
  - Connect AHB signals to the system bus.

2. Configuration:
  - Write coefficients to 0x6-0xD (F0-F3, e.g., {1, 2, 3, 4}).
  
  - Write 0x1 to 0xE to trigger coefficient loading.
  
  - Write samples to 0x4-0x5 to set sample_data and assert data_ready.

3. Operation:
  - Read filtered output from 0x2-0x3.
  
  - Monitor status at 0x0-0x1 for errors or operation status.
  
  - Check one_k_samples for 1000-sample completion.

## Diagrams 
AHB Subordinate RTL Diagram:
![ahb_sub_rtl](https://github.com/user-attachments/assets/8db44e8f-a272-4b72-9474-fbc456b3805a)
FIR Filter State Machine:
![fir_std](https://github.com/user-attachments/assets/f184c5d5-46d7-4427-a224-4e77442c97ee)
Coefficient Loader State Machine:

<img width="600" height="900" alt="image" src="https://github.com/user-attachments/assets/e705024b-f184-4997-81bd-e790207c4f15" />


