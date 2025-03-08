# MPU (Main Processing Unit)

## Overview

The Main Processing Unit (MPU) is a critical component of the ECO32 processor architecture, responsible for executing arithmetic, logical, and control operations. It serves as the primary computational engine of the processor, handling a wide range of instructions from basic arithmetic to complex conditional operations.

## Key Features

- **Comprehensive ALU Operations**: Supports a full range of arithmetic and logical operations including addition, subtraction, AND, OR, XOR, and NOR.
- **Condition Code Management**: Generates and maintains processor flags (Zero, Carry, Overflow, Sign, etc.) based on operation results.
- **Control Register Operations**: Provides access to and manipulation of the processor's control registers.
- **Shift and Rotate Operations**: Implements various shift and rotate operations with support for different modes.
- **Bit Counting and Manipulation**: Supports operations for counting bits, finding leading/trailing zeros, and other bit manipulation tasks.
- **Multi-cycle Operation Support**: Handles operations that require multiple cycles to complete.
- **Dual-thread Support**: Maintains separate state for two hardware threads.
- **Event Handling**: Processes processor events and exceptions.

## Architecture

The MPU is designed with a pipelined architecture that allows for efficient instruction execution. The pipeline consists of several stages:

1. **A0 Stage**: Initial instruction decoding and operand preparation
2. **B1 Stage**: Execution of arithmetic and logical operations
3. **A2 Stage**: Result processing and preparation for writeback
4. **B3 Stage**: Additional processing for multi-cycle operations
5. **A4 Stage**: Final result preparation and writeback control

## Functional Units

### Arithmetic Logic Unit (ALU)

The ALU performs basic arithmetic and logical operations:

- **Arithmetic Operations**: Addition, subtraction, increment, decrement
- **Logical Operations**: AND, OR, XOR, NOR, NOT
- **Comparison Operations**: Equal, not equal, greater than, less than, etc.

The ALU generates condition codes that reflect the result of operations:
- **Z (Zero)**: Set when the result is zero
- **C (Carry)**: Set when there's a carry out from the most significant bit
- **O (Overflow)**: Set when arithmetic overflow occurs
- **S (Sign)**: Set when the result is negative

### Shifter Unit

The shifter unit handles various shift and rotate operations:

- **Logical Shift Left/Right**: Shifts bits left or right, filling with zeros
- **Arithmetic Shift Right**: Shifts bits right, preserving the sign bit
- **Rotate Left/Right**: Rotates bits left or right, wrapping around
- **Variable Shift**: Supports shift amounts specified in registers or immediate values

### Bit Manipulation Unit

This unit provides specialized bit manipulation capabilities:

- **Bit Counting**: Counts the number of set bits in a word
- **Leading/Trailing Zero Detection**: Finds the position of the first/last set bit
- **Bit Field Operations**: Extracts or inserts bit fields within a word

### Control Register Unit

The control register unit manages access to the processor's control registers:

- **Read/Write Operations**: Allows reading from and writing to control registers
- **Special Register Handling**: Provides special handling for system-critical registers
- **Thread Context Management**: Maintains separate control register contexts for each thread

## Instruction Handling

The MPU processes instructions received from the IDU (Instruction Decode Unit) and performs the following steps:

1. **Instruction Decoding**: Further decodes the instruction to determine the specific operation
2. **Operand Retrieval**: Obtains operands from registers or immediate values
3. **Operation Execution**: Performs the specified operation
4. **Condition Code Generation**: Updates condition codes based on the result
5. **Result Writeback**: Prepares results for writeback to registers

## Control Words

The MPU receives several control words from the IDU that specify the operations to be performed:

- **ar_cw**: Arithmetic operation control
- **lo_cw**: Logical operation control
- **sh_cw**: Shift operation control
- **mm_cw**: Bit manipulation control
- **cr_cw**: Control register operation control
- **cc_cw**: Condition code control
- **bc_cw**: Bit count operation control
- **jp_cw**: Jump operation control

## Condition Code Handling

The MPU maintains a set of condition codes that reflect the results of operations:

- **Integer Flags**: Z (Zero), C (Carry), O (Overflow), S (Sign), P (Parity)
- **Floating-Point Flags**: N (NaN), I (Infinity), D (Denormalized)

These flags are used for conditional operations and can be tested by branch instructions.

## Event Handling

The MPU handles various processor events and exceptions:

- **Interrupt Processing**: Saves the current state and prepares for interrupt handling
- **Exception Handling**: Processes exceptions such as undefined instructions or memory access violations
- **System Call Processing**: Handles system calls by saving state and transferring control to the appropriate handler

## Integration with Other Units

The MPU interfaces with several other processor units:

- **IDU (Instruction Decode Unit)**: Receives decoded instructions and operands
- **LSU (Load-Store Unit)**: Coordinates with memory operations
- **JPU (Jump Processing Unit)**: Provides information for jump operations
- **WBU (Write-Back Unit)**: Sends results for register writeback
- **FPU (Floating Point Unit)**: Coordinates with floating-point operations
- **XPU (Extended Processing Unit)**: Coordinates with extended operations

## Performance Considerations

The MPU is designed for high performance:

- **Pipelined Architecture**: Allows multiple instructions to be in different stages of execution
- **Parallel Execution**: Multiple functional units can operate in parallel
- **Efficient Resource Utilization**: Optimized for FPGA implementation
- **Low-Latency Operations**: Most operations complete in a single cycle
- **Dual-Thread Support**: Efficiently switches between two hardware threads

## Implementation Details

The MPU is implemented in Verilog/SystemVerilog and consists of several modules:

- **eco32_core_mpu_box.v**: Main MPU module that integrates all functional units
- **eco32_core_mpu_cfr.v**: Condition flag register module
- **eco32_core_mpu_crx.v**: Control register access module
- **eco32_core_mpu_erx.v**: Extension register module

The implementation is optimized for FPGA targets and supports various configuration options to adapt to different requirements.