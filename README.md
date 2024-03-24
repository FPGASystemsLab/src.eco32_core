# ECO32 Microprocessor Project

## Overview

ECO32 is an innovative microprocessor project designed for FPGA implementation, developed within the research framework of FPGASystemsLab. It is a RISC architecture processor notable for its two complementary sets of general-purpose registers (GPRA and GPRB), effectively offering 64 registers due to unique addressing capabilities. This design allows for efficient data handling and direct connections to FPGA processing units without signal rerouting.

## Key Features

- **Dual Register Banks:** GPRA and GPRB complement each other, enabling operations such as address+offset to source data from both, enhancing the effective register count to 64.
- **Direct FPGA Integration:** Lines directly enter processing units, eliminating the need for signal rerouting and boosting operational efficiency.
- **Dual Register Writing:** Capability to write data to two registers simultaneously within a single clock cycle, facilitating operations like min/max which can output to two different registers concurrently.
- **2-Way Cache Memory:** Each cache page contains 32 bytes, optimizing data retrieval and storage processes.
- **Extensibility:** Designed to natively support extensions/accelerators and I/O devices without blocking processor operations.
- **Hardware Multithreading:** Implements hardware dual-threading similar to HyperThreading, interweaving instructions from two threads every clock cycle, effectively managing interrupts and I/O handling.
- **Performance:** Depending on the FPGA model and synthesis parameters, clock speeds range from 100MHz to 400MHz, making ECO32 a highly efficient processor for control units or as a core in audio/video encoding and decoding modules.

## Modules

- **FPU (Floating Point Unit)**
- **IDU (Instruction Decode Unit)**
- **IFU (Instruction Fetch Unit)**
- **JPU (Jump Processing Unit)**
- **MPU (Memory Processing Unit)**
- **TRACE (Trace and Debug Module)**
- **WBU (Write-Back Unit)**
- **XPU (Execution Processing Unit)**




Control Registers 

| Bank A Register | Description        | Bank B Register | Description      |
|-----------------|--------------------|-----------------|------------------|
| CRA0            | Flags              | CRB0            | Flags            |
| CRA1            | -                  | CRB1            | reserved         |
| CRA2            | -                  | CRB2            | reserved         |
| CRA3            | -                  | CRB3            | reserved         |
| CRA4            | -                  | CRB4            | reserved         |
| CRA5            | -                  | CRB5            | reserved         |
| CRA6            | Counter Lo         | CRB6            | Counter Hi       |
| CRA7            | Processor ID       | CRB7            | Processor CAP    |
| CRA8            | Thread ctx         | CRB8            | Thread param     |
| CRA9            | Thread ctx         | CRB9            | Thread param     |
| CRA10           | Debug control      | CRB10           | Debug flags      |
| CRA11           | Debug control      | CRB11           | Debug flags      |
| CRA12           | SystemTemp         | CRB12           | SystemTemp       |
| CRA13           | System             | CRB13           | System           |
| CRA14           | Event Ctrl         | CRB14           | Event Flags      |
| CRA15           | Event Data Lo      | CRB15           | Event Data Hi    |
| CRA16           | SysCall 0          | CRB16           | reserved         |
| CRA17           | SysCall 1          | CRB17           | reserved         |
| CRA18           | SysCall 2          | CRB18           | reserved         |
| CRA19           | SysCall 3          | CRB19           | reserved         |
| CRA20           | SysCall 4          | CRB20           | reserved         |
| CRA21           | SysCall 5          | CRB21           | reserved         |
| CRA22           | SysCall 6          | CRB22           | reserved         |
| CRA23           | SysEvent           | CRB23           | reserved         |
| CRA24           | RetAddr0 - Int Exc | CRB24           | Ret_ISW0         |
| CRA25           | RetAddr1 - Dbg Exc | CRB25           | Ret_ISW1         |
| CRA26           | RetAddr2 - Ext Exc | CRB26           | Ret_ISW2         |
| CRA27           | RetAddr3 - TLB Exc | CRB27           | Ret_ISW3         |
| CRA28           | JP_ADDR0           | CRB28           | JP_ISW0          |
| CRA29           | JP_ADDR1           | CRB29           | JP_ISW1          |
| CRA30           | JP_ADDR2           | CRB30           | JP_ISW2          |
| CRA31           | JP_ADDR3           | CRB31           | JP_ISW3          |



## Getting Started

[Instructions on how to set up and start working with the ECO32 project, including required tools and initial setup steps.]

## How to Contribute

[Guidelines for contributing to the ECO32 project, including how to submit pull requests, report bugs, and suggest enhancements.]

## License

[Details about the project's licensing. Typically, an open-source license is used, but make sure to specify any conditions or restrictions.]

## Acknowledgements

[Space for acknowledging contributions from team members, other researchers, or any funding/supporting organizations.]

