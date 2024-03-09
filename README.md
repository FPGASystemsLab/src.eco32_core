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

[Detailed descriptions of each module will be provided.]

## Getting Started

[Instructions on how to set up and start working with the ECO32 project, including required tools and initial setup steps.]

## How to Contribute

[Guidelines for contributing to the ECO32 project, including how to submit pull requests, report bugs, and suggest enhancements.]

## License

[Details about the project's licensing. Typically, an open-source license is used, but make sure to specify any conditions or restrictions.]

## Acknowledgements

[Space for acknowledging contributions from team members, other researchers, or any funding/supporting organizations.]

