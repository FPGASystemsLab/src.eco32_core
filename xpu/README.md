# XPU (Extended Processing Unit)

## Overview

The Extended Processing Unit (XPU) is a specialized component of the ECO32 processor architecture, designed to handle complex computational operations that go beyond the capabilities of the standard arithmetic logic unit. It serves as a high-performance accelerator for operations such as multiplication, division, floating-point arithmetic, and other computationally intensive tasks. The XPU significantly enhances the processor's computational capabilities, enabling efficient execution of complex algorithms and mathematical operations.

## Key Features

- **Advanced Arithmetic Operations**: Implements complex arithmetic operations including multiplication, division, and multi-operand calculations.
- **Floating-Point Support**: Provides hardware acceleration for IEEE 754 single-precision floating-point operations.
- **DSP Integration**: Leverages FPGA Digital Signal Processing (DSP) blocks for high-performance computation.
- **Configurable Implementation**: Supports multiple DSP architectures (DSP48E, DSP48E1, DSP48A1, MUL18x18, MUL25x18) to adapt to different FPGA platforms.
- **Pipelined Architecture**: Implements a multi-stage pipeline for high throughput and efficient execution.
- **Dual-Thread Support**: Maintains separate execution contexts for two hardware threads.
- **Dual Write-Back Paths**: Provides two separate write-back paths for efficient result delivery to the register file.
- **Extended Precision**: Supports operations on extended precision operands (up to 35-bit by 25-bit multiplication).

## Architecture

The XPU architecture consists of several key components:

### Integer Processing Unit

This unit handles integer arithmetic operations:

- **Multiplication Unit**: Performs 16-bit and 32-bit integer multiplication with support for signed and unsigned operands.
- **Addition/Subtraction Unit**: Performs addition and subtraction operations, including multi-operand calculations.
- **Linear Expression Evaluation**: Computes linear expressions of the form a*b + c*d efficiently.
- **Bit Manipulation**: Performs various bit manipulation operations.

### Floating-Point Processing Unit

This unit handles floating-point arithmetic operations:

- **Floating-Point Addition/Subtraction**: Performs IEEE 754 single-precision floating-point addition and subtraction.
- **Floating-Point Multiplication**: Performs IEEE 754 single-precision floating-point multiplication.
- **Floating-Point Division**: Performs IEEE 754 single-precision floating-point division.
- **Floating-Point Conversion**: Converts between integer and floating-point formats.
- **Fused Multiply-Add**: Performs fused multiply-add operations (a*b + c) with a single rounding step.

### DSP Integration

The XPU integrates with FPGA DSP blocks for high-performance computation:

- **Configurable DSP Architecture**: Supports multiple DSP architectures to adapt to different FPGA platforms.
- **Optimized Multipliers**: Implements optimized multipliers (35x18, 35x25) tailored to the capabilities of specific DSP blocks.
- **Shift-Add Unit**: Implements a specialized shift-add unit for floating-point operations.
- **Pipeline Optimization**: Optimizes the pipeline structure based on the available DSP architecture.

### Pipeline Structure

The XPU implements a multi-stage pipeline for efficient execution:

1. **A0 Stage**: Initial instruction processing and operand preparation
2. **B1 Stage**: First computation stage
3. **A2 Stage**: Intermediate result processing
4. **B3 Stage**: Second computation stage
5. **A4 Stage**: Final result preparation
6. **B5 Stage**: Result writeback

## Supported Operations

The XPU supports a wide range of operations:

### Integer Operations

- **16-bit Multiplication**: Multiplies 16-bit integers with optional accumulation
- **32-bit Multiplication**: Multiplies 32-bit integers
- **Linear Expression Evaluation**: Computes expressions of the form a*b + c*d
- **Addition/Subtraction**: Performs addition and subtraction with extended precision
- **Signed/Unsigned Operations**: Supports both signed and unsigned arithmetic

### Floating-Point Operations

- **Addition/Subtraction**: Performs IEEE 754 single-precision floating-point addition and subtraction
- **Multiplication**: Performs IEEE 754 single-precision floating-point multiplication
- **Division**: Performs IEEE 754 single-precision floating-point division
- **Fused Multiply-Add**: Performs a*b + c in a single operation with a single rounding step
- **Conversion**: Converts between integer and floating-point formats
- **Comparison**: Compares floating-point values with proper handling of special cases (NaN, infinity)

## Control Word Format

The XPU receives several control words from the IDU that specify the operations to be performed:

- **dc_cw**: Data conversion control word
- **fr_cw**: Floating-point rounding control word
- **ml_cw**: Multiplication control word
- **fl_cw**: Floating-point operation control word

These control words determine the specific operation to be performed and its parameters.

## DSP Integration

The XPU is designed to leverage FPGA DSP blocks for high-performance computation:

- **DSP48E/DSP48E1**: Used in Xilinx Virtex-5/6 and 7-series FPGAs
- **DSP48A1**: Used in Xilinx Spartan-6 FPGAs
- **MUL18x18/MUL25x18**: Generic multiplier implementations for FPGAs without dedicated DSP blocks

The implementation is configurable through the DSP parameter, allowing the XPU to adapt to different FPGA platforms.

## Floating-Point Implementation

The floating-point implementation in the XPU follows the IEEE 754 single-precision format:

- **Sign Bit**: 1 bit indicating the sign of the number
- **Exponent**: 8 bits representing the exponent (biased by 127)
- **Mantissa**: 23 bits representing the fractional part (with an implicit leading 1)

The implementation handles special cases such as:

- **Zero**: Exponent and mantissa are zero
- **Infinity**: Exponent is all ones, mantissa is zero
- **NaN (Not a Number)**: Exponent is all ones, mantissa is non-zero
- **Denormalized Numbers**: Exponent is zero, mantissa is non-zero

## Performance Considerations

The XPU is designed for high performance:

- **DSP Utilization**: Efficiently utilizes FPGA DSP blocks for maximum performance
- **Pipelined Architecture**: Implements a multi-stage pipeline for high throughput
- **Optimized Multipliers**: Uses optimized multiplier implementations tailored to the target FPGA
- **Parallel Execution**: Supports parallel execution of multiple operations
- **Dual Write-Back Paths**: Provides two separate write-back paths for efficient result delivery

## Implementation Details

The XPU is implemented in Verilog/SystemVerilog and consists of several modules:

- **eco32_core_xpu_box.v**: Main XPU module that integrates integer operations
- **eco32_core_xpu_fl_box.v**: Floating-point unit module
- **eco32_core_xpu_mul_35x18.v**: 35x18 multiplier module
- **eco32_core_xpu_mul_35x25.v**: 35x25 multiplier module
- **eco32_core_xpu_sh_add_bezDSP.v**: Shift-add unit module for floating-point operations

## Integration with the Processor

The XPU is tightly integrated with the ECO32 processor:

- **IDU Interface**: Receives decoded instructions and operands from the Instruction Decode Unit
- **WBU Interface**: Sends results to the Write-Back Unit for register updates
- **Pipeline Coordination**: Coordinates with other pipeline stages through control signals (fci_inst_jpf, fci_inst_lsf, fci_inst_rep, fci_inst_skip)

## Configuration Parameters

The XPU can be configured through several parameters:

- **DSP**: Specifies the DSP architecture to use (DSP48E, DSP48E1, DSP48A1, MUL18x18, MUL25x18)
- **FORCE_RST**: Controls reset behavior for simulation and synthesis

These parameters allow the XPU to be tailored to specific FPGA platforms and application requirements.

## Limitations and Considerations

While the XPU provides powerful computational capabilities, there are some limitations to consider:

- **Floating-Point Precision**: The implementation may have systematic rounding errors for certain operations due to implementation constraints.
- **DSP Resource Requirements**: The XPU requires DSP resources, which may be limited on some FPGA platforms.
- **Pipeline Latency**: Complex operations have higher latency due to the multi-stage pipeline.
- **Power Consumption**: Intensive use of the XPU may increase power consumption.

Despite these limitations, the XPU significantly enhances the computational capabilities of the ECO32 processor, enabling efficient execution of complex algorithms and mathematical operations.
