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

## General Description

At the outset, it's crucial to note that the processor was designed for FPGA systems, drawing on experiences from other FPGA-based projects. The primary goals we aimed to achieve include:
- High operating frequency, close to the maximum fabric frequency for the given FPGA.
- Flexibility in programming (pairing of registers, their substantial number).
- Compatibility with NoC networks (RingNet).
- The capability to run multiple cores on a single FPGA.
- Intended as a control unit for data processing modules, such as audio/video encoders/decoders, packet network routers, and others.
- Easy integration of hardware functions (hardware function call, described in the document [here link]), allowing for, e.g., hardware-based decoding of binary symbols from a video stream.
- A modern approach to semi-hardware integration of software libraries, enabling function calls from libraries at the level of a single hardware call.

These goals have been achieved, and the repository contains a description in Verilog/SystemVerilog of a dual-thread processor core. During R&D activities, a set of four cores connected in the NoC network (RingNet [repository link]) was tested, and simulations of up to 64 cores connected via the same NoC network were conducted. The results are included in the doctoral thesis of colleague Jakub Siasta ([link to the thesis]).

Let's now move on to the processor description. The processor consists of a lengthy instruction processing pipeline, with the first stage being the IFU (Instruction Fetch Unit), which retrieves commands from memory and passes them to the IDU (Instruction Decoding Unit). In this unit, after command decoding, processor registers indicated in the command are also read, as well as flag registers. The command then moves to the MPU (Main Processing Unit), which performs basic arithmetic-logic operations, and then the results are directed to the WBU (Write Back Unit) or LSU (Load-Store Unit), which contains cache memory and allows for data exchange between the registers and main memory. The WBU unit also gathers results from other units such as the FPU (Floating Point Unit) or XPU (Extended Processing Unit), queues them, and writes them to processor registers. The WBU's task is to buffer results if they arrive from several units at the same time, as only one pair of Axx:Bxx registers can be written in a given cycle.
The pipeline scheme is shown in the following figure:

[link to the image in media/eco32_processor_units_pipeline.png]

The processor features an interface compatible with the NoC network's RingBus. However, it can also be connected without using the network; it's essential to remember that data exchange on this interface is packet-based, in packets of 32 bytes length (8 words of 32 bits + 1 word of 32 bits header).

Below, the processor's features are described, starting from showing its structure from the programming side (registers, markers, commands, IO operations, multi-threading features) to a brief description of individual blocks (units).

### Processor Registers (General Purpose and Control)

The processor has two banks of general-purpose registers, A and B, with 32-bit registers accessible at the assembler level without the need to "switch banks". This term only relates to the situation of pairing registers when we want to use them simultaneously (description Axx:Bxx) where the command description contains information on how data from bank A and B are interpreted. For example, addressing through Axx:Bxx means that Axx contains the base address and Bxx contains the offset.
Additionally, the processor includes two banks of control registers, CRA and CRB, which are also 32-bit and organized in pairs. This allows, for example, for the separation of registers used by the kernel for thread switching and storing data about addresses and control markers in one pair of CARxx:CRBxx.

#### General Purpose Registers

| Bank A Register | Description | Bank B Register | Description |
|-----------------|-------------|-----------------|-------------|
| A0              | ZERO        | B0              | ZERO        |
| A1              | VL          | B1              | VH (n)      |
| A2              | ARG0        | B2              | (tmp)       |
| A3              | ARG1        | B3              | (tmp)       |
| A4              | ARG2        | B4              | (tmp)       |
| A5              | ARG3        | B5              | (tmp)       |
| A6              | ARG4        | B6              | (tmp)       |
| A7              | ARG5        | B7              | (tmp)       |
| A8              | (saved)     | B8              | (saved)     |
| A9              | (saved)     | B9              | (saved)     |
| A10             | (saved)     | B10             | (saved)     |
| A11             | (saved)     | B11             | (saved)     |
| A12             | (saved)     | B12             | (saved)     |
| A13             | (saved)     | B13             | (saved)     |
| A14             | (saved)     | B14             | (saved)     |
| A15             | (saved)     | B15             | (saved)     |
| A16             | (saved)     | B16             | (saved)     |
| A17             | (saved)     | B17             | (saved)     |
| A18             | (saved)     | B18             | (saved)     |
| A19             | (saved)     | B19             | (saved)     |
| A20             | -           | B20             | -           |
| A21             | -           | B21             | -           |
| A22             | -           | B22             | -           |
| A23             | -           | B23             | -           |
| A24             | -           | B24             | -           |
| A25             | -           | B25             | -           |
| A26             | -           | B26             | -           |
| A27             | -           | B27             | -           |
| A28             | GP          | B28             | KGP         |
| A29             | FP          | B29             | KFP         |
| A30             | SP          | B30             | KSP         |
| A31             | LR          | B31             | LX          |



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

