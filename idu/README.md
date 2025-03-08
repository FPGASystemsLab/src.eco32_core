# IDU (Instruction Decode Unit)

## Overview

The Instruction Decode Unit (IDU) is a critical component of the ECO32 processor architecture, responsible for decoding instructions fetched by the IFU and preparing them for execution by subsequent pipeline stages. It serves as the bridge between instruction fetching and execution, transforming raw instruction data into control signals that direct the operation of the processor's execution units. The IDU also manages the processor's register file, providing operands to execution units and handling register dependencies.

## Key Features

- **Instruction Decoding**: Decodes fetched instructions to determine the operation to be performed and the operands involved.
- **Control Word Generation**: Produces control words that direct the operation of downstream execution units (MPU, LSU, FPU, XPU, etc.).
- **Register File Management**: Maintains and provides access to the processor's general-purpose and control registers.
- **Operand Forwarding**: Implements forwarding mechanisms to resolve data dependencies between instructions.
- **Dual-Thread Support**: Maintains separate register contexts for two hardware threads, enabling efficient multithreading.
- **Register Locking**: Implements register locking mechanisms to prevent hazards in the pipeline.
- **Immediate Value Handling**: Processes immediate values embedded in instructions for use in operations.
- **Condition Code Management**: Handles condition codes for conditional execution of instructions.
- **Event Handling**: Processes processor events and exceptions at the decode stage.

## Architecture

The IDU architecture consists of several key components:

### Instruction Decoder

The instruction decoder analyzes the opcode and other fields of the instruction to determine:

- **Operation Type**: Identifies the type of operation (arithmetic, logical, memory, branch, etc.).
- **Operand Sources**: Determines the sources of operands (registers, immediates, etc.).
- **Destination Registers**: Identifies the registers where results will be stored.
- **Execution Unit**: Determines which execution unit will handle the instruction.
- **Control Word Parameters**: Extracts parameters needed for generating control words.

### Control Word Generator

The control word generator produces control signals for various execution units:

- **Arithmetic Control Words**: Direct the operation of the arithmetic logic unit.
- **Logical Control Words**: Control logical operations.
- **Shift Control Words**: Specify shift and rotate operations.
- **Memory Control Words**: Direct load and store operations.
- **Branch Control Words**: Control branch and jump operations.
- **Floating-Point Control Words**: Direct floating-point operations.
- **Extended Processing Control Words**: Control operations in the extended processing unit.

### Register File Unit (RFU)

The register file unit manages the processor's registers:

- **General-Purpose Registers**: Two banks (A and B) of 32 registers each.
- **Control Registers**: Special registers for system control and status.
- **Register Reading**: Provides operands to execution units.
- **Register Locking**: Prevents hazards by tracking register dependencies.
- **Register Forwarding**: Forwards results to dependent instructions.

### User-Defined Instruction Decoder

This component handles user-defined or extended instructions:

- **Instruction Identification**: Identifies user-defined instructions.
- **Mode Selection**: Determines the execution mode for these instructions.
- **Parameter Extraction**: Extracts parameters specific to user-defined instructions.

## Register Organization

The ECO32 processor features a sophisticated register organization managed by the IDU:

- **General-Purpose Register Bank A (GPRA)**: 32 registers (A0-A31) for general use.
- **General-Purpose Register Bank B (GPRB)**: 32 registers (B0-B31) for general use.
- **Control Register Bank A (CRA)**: 32 control registers for system management.
- **Control Register Bank B (CRB)**: 32 control registers for system management.

The register banks are organized to allow efficient paired operations, where registers from both banks can be used simultaneously in a single instruction.

## Instruction Decoding Process

The instruction decoding process involves several steps:

1. **Instruction Reception**: The IDU receives the instruction from the IFU.
2. **Opcode Decoding**: The primary opcode is decoded to determine the instruction type.
3. **Subopcode Decoding**: For complex instructions, subopcodes are decoded for further specification.
4. **Register Field Extraction**: Register fields are extracted to identify source and destination registers.
5. **Immediate Value Extraction**: Immediate values are extracted and sign-extended or zero-extended as needed.
6. **Control Word Generation**: Control words are generated for the appropriate execution units.
7. **Register Reading**: Source registers are read to provide operands.
8. **Dependency Checking**: Register dependencies are checked to prevent hazards.
9. **Instruction Forwarding**: The decoded instruction and operands are forwarded to execution units.

## Control Word Types

The IDU generates various types of control words for different execution units:

- **cc_cw**: Condition code control word
- **ar_cw**: Arithmetic operation control word
- **lo_cw**: Logical operation control word
- **sh_cw**: Shift operation control word
- **mm_cw**: Bit manipulation control word
- **ds_cw**: Decimal shift control word
- **bc_cw**: Bit count operation control word
- **ls_cw**: Load/store operation control word
- **jp_cw**: Jump operation control word
- **dc_cw**: Data conversion control word
- **fr_cw**: Floating-point rounding control word
- **fl_cw**: Floating-point logic control word
- **ft_cw**: Floating-point type control word
- **ml_cw**: Multiplication control word
- **cr_cw**: Control register operation control word

## Register Operand Handling

The IDU handles register operands through several mechanisms:

- **Register Mapping**: Maps logical register addresses to physical register addresses.
- **Zero Register Handling**: Special handling for the zero register (A0/B0).
- **Constant Substitution**: Substitutes constants for certain register references.
- **Bank Selection**: Selects between register banks A and B.
- **Mode Selection**: Determines how register values are interpreted.

## Dual-Thread Support

The IDU supports dual-threading with the following features:

- **Thread Context Separation**: Maintains separate register contexts for each thread.
- **Thread ID Tracking**: Tracks the thread ID throughout the pipeline.
- **Thread-Specific Register Locking**: Implements register locking on a per-thread basis.
- **Thread Switching Support**: Provides mechanisms for efficient thread switching.

## Hazard Detection and Handling

The IDU implements mechanisms for detecting and handling hazards:

- **Read-After-Write (RAW) Hazards**: Detects when an instruction needs a value that is still being computed.
- **Write-After-Write (WAW) Hazards**: Detects when multiple instructions attempt to write to the same register.
- **Write-After-Read (WAR) Hazards**: Detects when an instruction writes to a register that is still being read.
- **Register Locking**: Locks registers to prevent hazards.
- **Forwarding Paths**: Implements forwarding paths to resolve data dependencies.

## Event Handling

The IDU processes various processor events and exceptions:

- **Interrupt Handling**: Processes interrupt requests at the decode stage.
- **Exception Handling**: Handles exceptions detected during instruction decoding.
- **Event Prioritization**: Prioritizes events based on their type and urgency.
- **Event Propagation**: Propagates events to subsequent pipeline stages.

## Implementation Details

The IDU is implemented in Verilog/SystemVerilog and consists of several modules:

- **eco32_core_idu_box.v**: Main IDU module that integrates all components.
- **eco32_core_idu_cwd.v**: Control word decoder module.
- **eco32_core_idu_rfu_box.v**: Register file unit module.
- **eco32_core_idu_rfu_reg.v**: Register implementation module.
- **eco32_core_idu_rfu_tag.v**: Register tag handling module.
- **eco32_core_idu_r0t.v, eco32_core_idu_r1t.v, eco32_core_idu_r2t.v, eco32_core_idu_r3t.v**: Register operand handling modules.
- **eco32_core_idu_ryt.v**: Destination register handling module.
- **eco32_core_idu_udt.v**: User-defined instruction decoder module.

## Integration with the Processor

The IDU is tightly integrated with the ECO32 processor:

- **IFU Interface**: Receives fetched instructions from the Instruction Fetch Unit.
- **MPU Interface**: Provides decoded instructions and operands to the Main Processing Unit.
- **LSU Interface**: Provides control words and operands for load/store operations.
- **FPU Interface**: Provides control words and operands for floating-point operations.
- **XPU Interface**: Provides control words and operands for extended processing operations.
- **JPU Interface**: Provides control words and operands for jump operations.
- **WBU Interface**: Receives write-back signals for register updates.

## Performance Considerations

The IDU is designed for high performance:

- **Pipelined Architecture**: Implements a pipelined design to maximize throughput.
- **Parallel Decoding**: Decodes multiple instruction fields in parallel.
- **Efficient Register Access**: Optimizes register access for minimal latency.
- **Forwarding Mechanisms**: Implements efficient forwarding to minimize stalls.
- **Dual-Thread Support**: Maximizes utilization through dual-threading.

## Configuration Parameters

The IDU can be configured through several parameters:

- **FORCE_RST**: Controls reset behavior for simulation and synthesis.
- **CODE_ID**: Identifies the specific implementation of the module.

These parameters allow the IDU to be tailored to specific application requirements and available FPGA resources.
