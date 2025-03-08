# ECO32 Microprocessor Project

## Overview of Eco32

At the outset, it's crucial to note that the processor was designed for FPGA systems, drawing on experiences from other FPGA-based projects. The primary goals we aimed to achieve include:
- High operating frequency, close to the maximum fabric frequency for the given FPGA.
- Flexibility in programming (pairing of registers, their substantial number).
- Compatibility with NoC networks (RingNet).
- The capability to run multiple cores on a single FPGA.
- Intended as a control unit for data processing modules, such as audio/video encoders/decoders, packet network routers, and others.
- Easy integration of hardware functions (hardware function call), allowing for, e.g., hardware-based decoding of binary symbols from a video stream.
- A modern approach to semi-hardware integration of software libraries, enabling function calls from libraries at the level of a single hardware call.

These goals have been achieved, and the repository contains a description in Verilog/SystemVerilog of a dual-thread processor core. During R&D activities, a set of four cores connected in the NoC network (RingNet) was tested, and simulations of up to 64 cores connected via the same NoC network were conducted. The results are included in the doctoral thesis of colleague Jakub Siasta.

Let's now move on to the processor description. The processor consists of a lengthy instruction processing pipeline, with the first stage being the IFU (Instruction Fetch Unit), which retrieves commands from memory and passes them to the IDU (Instruction Decoding Unit). In this unit, after command decoding, processor registers indicated in the command are also read, as well as flag registers. The command then moves to the MPU (Main Processing Unit), which performs basic arithmetic-logic operations, and then the results are directed to the WBU (Write Back Unit) or LSU (Load-Store Unit), which contains cache memory and allows for data exchange between the registers and main memory. The WBU unit also gathers results from other units such as the FPU (Floating Point Unit) or XPU (Extended Processing Unit), queues them, and writes them to processor registers. The WBU's task is to buffer results if they arrive from several units at the same time, as only one pair of Axx:Bxx registers can be written in a given cycle.
The pipeline scheme is shown in the following figure:

[link to the image in media/eco32_processor_units_pipeline.png]

The processor features an interface compatible with the NoC network's RingBus. However, it can also be connected without using the network; it's essential to remember that data exchange on this interface is packet-based, in packets of 32 bytes length (8 words of 32 bits + 1 word of 32 bits header).

Below, the processor's features are described, starting from showing its structure from the programming side (registers, markers, commands, IO operations, multi-threading features) to a brief description of individual blocks (units).

## Key Features of hardware implementation

- **Dual Register Banks:** GPRA and GPRB complement each other, enabling operations such as address+offset to source data from both, enhancing the effective register count to 64.
- **Direct FPGA Integration:** Lines directly enter processing units, eliminating the need for signal rerouting and boosting operational efficiency.
- **Dual Register Writing:** Capability to write data to two registers simultaneously within a single clock cycle, facilitating operations like min/max which can output to two different registers concurrently.
- **2-Way Cache Memory:** Each cache page contains 32 bytes, optimizing data retrieval and storage processes.
- **Extensibility:** Designed to natively support extensions/accelerators and I/O devices without blocking processor operations.
- **Hardware Multithreading:** Implements hardware dual-threading similar to HyperThreading, interweaving instructions from two threads every clock cycle, effectively managing interrupts and I/O handling.
- **Performance:** Depending on the FPGA model and synthesis parameters, clock speeds range from 100MHz to 400MHz, making ECO32 a highly efficient processor for control units or as a core in audio/video encoding and decoding modules.

## Processor Architecture

The ECO32 processor is built around a sophisticated pipeline architecture that enables efficient instruction execution and parallel processing. The core components of this architecture are described below:

## Modules

### IFU (Instruction Fetch Unit)
The Instruction Fetch Unit is responsible for retrieving instructions from memory and feeding them into the processor pipeline. Key features include:
- Instruction cache with configurable size (default 8KB)
- Support for dual-threading with separate instruction streams
- Branch prediction and handling
- Interface with the NoC network for instruction fetching
- Event handling and management for instruction flow control

### IDU (Instruction Decode Unit)
The Instruction Decode Unit decodes fetched instructions and prepares them for execution. Its responsibilities include:
- Instruction decoding and classification
- Register file access for operand retrieval
- Condition code evaluation
- Control word generation for downstream execution units
- Register dependency tracking and hazard detection
- Event and exception handling at the decode stage

### MPU (Main Processing Unit)
The Main Processing Unit performs the core arithmetic and logical operations of the processor. Features include:
- Integer arithmetic operations (addition, subtraction, etc.)
- Logical operations (AND, OR, XOR, etc.)
- Comparison operations
- Shift and rotate operations
- Condition code generation
- Support for dual-threading with context switching
- Event handling and propagation

### LSU (Load-Store Unit)
The Load-Store Unit manages memory access operations, including:
- Data cache management with 2-way associativity
- Memory read and write operations
- Address translation and validation
- Memory-mapped I/O operations
- Cache coherency maintenance
- Support for various addressing modes
- Memory barrier and synchronization operations

### JPU (Jump Processing Unit)
The Jump Processing Unit handles all control flow operations, including:
- Conditional and unconditional jumps
- Subroutine calls and returns
- Exception and interrupt handling
- Thread context switching support
- Control register access for jump operations
- Branch target calculation and validation

### FPU (Floating Point Unit)
The Floating Point Unit provides hardware support for floating-point operations:
- IEEE 754 compliant floating-point arithmetic
- Single-precision floating-point operations
- Basic operations (addition, subtraction, multiplication, division)
- Comparison operations
- Conversion between integer and floating-point formats
- Exception handling for floating-point operations

### XPU (Extended Processing Unit)
The Extended Processing Unit provides additional computational capabilities:
- Advanced arithmetic operations (multiplication, division)
- DSP-oriented operations
- Support for various DSP implementations (DSP48E, DSP48E1, DSP48A1, etc.)
- Extended precision operations
- Special function acceleration
- Custom instruction extensions

### WBU (Write-Back Unit)
The Write-Back Unit manages the final stage of instruction execution:
- Result collection from various execution units
- Register file updates
- Result prioritization and scheduling
- Support for dual register writes in a single cycle
- Result forwarding to handle data dependencies
- Exception and event handling during write-back

### TRACE (Trace and Debug Module)
The Trace and Debug Module provides debugging and monitoring capabilities:
- Instruction execution tracing
- Register and memory state monitoring
- Breakpoint and watchpoint support
- Performance monitoring
- Debug interface for external tools
- Event logging and analysis

## Register Organization

The processor has two banks of general-purpose registers, A and B, with 32-bit registers accessible at the assembler level without the need to "switch banks". This term only relates to the situation of pairing registers when we want to use them simultaneously (description Axx:Bxx) where the command description contains information on how data from bank A and B are interpreted. For example, addressing through Axx:Bxx means that Axx contains the base address and Bxx contains the offset.
Additionally, the processor includes two banks of control registers, CRA and CRB, which are also 32-bit and organized in pairs. This allows, for example, for the separation of registers used by the kernel for thread switching and storing data about addresses and control markers in one pair of CARxx:CRBxx.

### General Purpose and Control Registers

| GPR Bank A Register | Description        | GPR Bank B Register | Description      | CR Bank A Register | CR Description        | CR Bank B Register | CR Description      |
|---------------------|--------------------|---------------------|------------------|---------------------|-----------------------|---------------------|---------------------|
| A0                  | ZERO               | B0                  | ZERO             | CRA0                | Flags                 | CRB0                | Flags               |
| A1                  | VL                 | B1                  | VH (n)           | CRA1                | -                     | CRB1                | reserved            |
| A2                  | ARG0               | B2                  | (tmp)            | CRA2                | -                     | CRB2                | reserved            |
| A3                  | ARG1               | B3                  | (tmp)            | CRA3                | -                     | CRB3                | reserved            |
| A4                  | ARG2               | B4                  | (tmp)            | CRA4                | -                     | CRB4                | reserved            |
| A5                  | ARG3               | B5                  | (tmp)            | CRA5                | -                     | CRB5                | reserved            |
| A6                  | ARG4               | B6                  | (tmp)            | CRA6                | Counter Lo            | CRB6                | Counter Hi          |
| A7                  | ARG5               | B7                  | (tmp)            | CRA7                | Processor ID          | CRB7                | Processor CAP       |
| A8                  | (saved)            | B8                  | (saved)          | CRA8                | Thread ctx            | CRB8                | Thread param        |
| A9                  | (saved)            | B9                  | (saved)          | CRA9                | Thread ctx            | CRB9                | Thread param        |
| A10                 | (saved)            | B10                 | (saved)          | CRA10               | Debug control         | CRB10               | Debug flags         |
| A11                 | (saved)            | B11                 | (saved)          | CRA11               | Debug control         | CRB11               | Debug flags         |
| A12                 | (saved)            | B12                 | (saved)          | CRA12               | SystemTemp            | CRB12               | SystemTemp          |
| A13                 | (saved)            | B13                 | (saved)          | CRA13               | System                | CRB13               | System              |
| A14                 | (saved)            | B14                 | (saved)          | CRA14               | Event Ctrl            | CRB14               | Event Flags         |
| A15                 | (saved)            | B15                 | (saved)          | CRA15               | Event Data Lo         | CRB15               | Event Data Hi       |
| A16                 | (saved)            | B16                 | (saved)          | CRA16               | SysCall 0             | CRB16               | reserved            |
| A17                 | (saved)            | B17                 | (saved)          | CRA17               | SysCall 1             | CRB17               | reserved            |
| A18                 | (saved)            | B18                 | (saved)          | CRA18               | SysCall 2             | CRB18               | reserved            |
| A19                 | (saved)            | B19                 | (saved)          | CRA19               | SysCall 3             | CRB19               | reserved            |
| A20                 | -                  | B20                 | -                | CRA20               | SysCall 4             | CRB20               | reserved            |
| A21                 | -                  | B21                 | -                | CRA21               | SysCall 5             | CRB21               | reserved            |
| A22                 | -                  | B22                 | -                | CRA22               | SysCall 6             | CRB22               | reserved            |
| A23                 | -                  | B23                 | -                | CRA23               | SysEvent              | CRB23               | reserved            |
| A24                 | -                  | B24                 | -                | CRA24               | RetAddr0 - Int Exc    | CRB24               | Ret_ISW0            |
| A25                 | -                  | B25                 | -                | CRA25               | RetAddr1 - Sys Call   | CRB25               | Ret_ISW1            |
| A26                 | -                  | B26                 | -                | CRA26               | RetAddr2 - Debug      | CRB26               | Ret_ISW2            |
| A27                 | -                  | B27                 | -                | CRA27               | RetAddr3 - User       | CRB27               | Ret_ISW3            |
| A28                 | SP                 | B28                 | FP               | CRA28               | Kernel SP             | CRB28               | Kernel FP           |
| A29                 | GP                 | B29                 | TP               | CRA29               | Kernel GP             | CRB29               | Kernel TP           |
| A30                 | RA                 | B30                 | EA               | CRA30               | Kernel RA             | CRB30               | Kernel EA           |
| A31                 | PC                 | B31                 | NPC              | CRA31               | Kernel PC             | CRB31               | Kernel NPC          |

### Flag Register (CRA0:CRB0)

| Bit | Flag | Description                                                      | Source         |
|-----|------|------------------------------------------------------------------|----------------|
| 8   | I    | Infinity - Indicates the result of the FP operation is infinity  | Floating Point |
| 7   | N    | NaN (Not a Number) - Indicates the result cannot be represented as a real number | Floating Point |
| 6   | D    | Denormalized - Indicates a denormalized floating-point number   | Floating Point |
| 5   | -    | Not utilized                                                     | -              |
| 4   | S    | Sign - Indicates if the ALU operation result is negative         | ALU            |
| 3   | O    | Overflow - Indicates arithmetic overflow in ALU operations       | ALU            |
| 2   | C    | Carry Out - Indicates carry out from the most significant bit in ALU operations | ALU |
| 1   | Z    | Zero - Indicates the ALU operation result is zero                | ALU            |
| 0   | P    | Parity - Indicates if the number of set bits in the result is even | ALU          |

## Pipeline Architecture

The ECO32 processor employs a sophisticated pipeline architecture that enables efficient instruction execution. The pipeline consists of several stages, each handled by a dedicated unit:

1. **Instruction Fetch (IFU)**: Retrieves instructions from memory
2. **Instruction Decode (IDU)**: Decodes instructions and reads register operands
3. **Execution (MPU/XPU/FPU)**: Performs the actual computation
4. **Memory Access (LSU)**: Handles memory operations if needed
5. **Write Back (WBU)**: Writes results back to registers

This pipeline design allows for instruction-level parallelism, where multiple instructions can be in different stages of execution simultaneously, significantly improving throughput.

## Hardware Multithreading

The ECO32 processor implements hardware dual-threading similar to Intel's HyperThreading technology. This feature allows two independent threads to execute concurrently on the same physical core. Key aspects include:

- Thread interleaving at the clock cycle level
- Separate architectural state (registers, program counters) for each thread
- Shared execution resources with time-multiplexed access
- Efficient handling of long-latency operations by switching to the other thread
- Improved overall throughput by utilizing otherwise idle execution units

## Memory Hierarchy

The ECO32 processor features a hierarchical memory system designed for performance:

- **L1 Instruction Cache**: Managed by the IFU, configurable size (default 8KB)
- **L1 Data Cache**: Managed by the LSU, 2-way associative with 32-byte cache lines
- **Main Memory Interface**: Packet-based communication with 32-byte transfers
- **NoC Interface**: Compatible with RingNet for multi-core configurations

## NoC Integration

The ECO32 processor is designed to work seamlessly with Network-on-Chip (NoC) architectures, specifically the RingNet:

- Packet-based communication protocol
- 32-byte packet size (8 words of 32 bits + 1 word header)
- Support for multi-core configurations (tested with 4 cores, simulated with up to 64)
- Efficient inter-core communication and memory access

## Implementation Technologies

The ECO32 processor is designed for FPGA implementation with support for various FPGA families:

- Optimized for high clock frequencies on FPGA fabric
- Support for different DSP block implementations (DSP48E, DSP48E1, DSP48A1, etc.)
- Configurable parameters to adapt to different FPGA resources
- Performance ranging from 100MHz to 400MHz depending on FPGA model and synthesis parameters

## Getting Started

### Prerequisites

To work with the ECO32 processor, you'll need:

- Verilog/SystemVerilog development environment
- FPGA synthesis tools compatible with your target FPGA
- Simulation tools for verification (ModelSim, VCS, etc.)
- Basic understanding of processor architecture and FPGA design

### Building and Synthesis

1. Clone the repository to your local machine
2. Configure the processor parameters according to your requirements
3. Synthesize the design using your FPGA vendor's tools
4. Implement and generate the bitstream
5. Program your FPGA with the generated bitstream

### Simulation

1. Set up your simulation environment
2. Run the provided testbenches to verify functionality
3. Analyze simulation results to ensure correct operation

## How to Contribute

Contributions to the ECO32 project are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows the project's coding standards and includes appropriate documentation.

## License

This project is licensed under the terms of the LICENSE file included in the repository.

## Acknowledgements

- Adam Luczak - Main contributor and architect
- Jakub Siasta - Contributor and researcher

