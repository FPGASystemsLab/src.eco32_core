# WBU (Write-Back Unit)

## Overview

The Write-Back Unit (WBU) is a critical component of the ECO32 processor architecture, responsible for managing the final stage of instruction execution by writing results back to the processor's register file. It serves as a central hub that collects results from various execution units and coordinates their orderly delivery to the appropriate registers. The WBU plays a crucial role in maintaining data coherency and ensuring that register updates occur in the correct sequence, which is essential for proper program execution.

## Key Features

- **Result Collection**: Gathers computation results from multiple execution units including MPU, LSU, FPU, and XPU.
- **Write-Back Arbitration**: Implements priority-based arbitration to resolve conflicts when multiple units attempt to write to registers simultaneously.
- **Byte-Enable Support**: Provides fine-grained control over byte-level writes to registers.
- **Dual Register Bank Support**: Manages writes to both A and B register banks.
- **Register Pairing**: Supports writing to register pairs (A:B) for operations that produce 64-bit results.
- **Result Buffering**: Buffers results to handle timing variations between different execution units.
- **Dual-Thread Support**: Maintains separate write-back contexts for two hardware threads.
- **Configurable Floating-Point Support**: Can be configured to support different levels of floating-point functionality.

## Architecture

The WBU architecture consists of several key components:

### Input Interfaces

The WBU receives results from multiple execution units through dedicated interfaces:

- **MPU Interface (a_stb)**: Receives results from the Main Processing Unit for basic arithmetic and logical operations.
- **LSU Interfaces (b0_stb, b1_stb, b2_stb)**: Receive results from the Load-Store Unit for memory operations.
- **XPU Interface (xp_stb)**: Receives results from the Extended Processing Unit for complex arithmetic operations.
- **FPU Interface (fp_stb)**: Receives results from the Floating-Point Unit for floating-point operations.

Each interface includes control signals (enable, tag, address) and data signals (dataL, dataH) to specify the destination registers and the values to be written.

### Arbitration Logic

The arbitration logic determines which result should be written to the register file when multiple results are available:

- **Priority Encoder**: Implements a priority-based scheme to select among competing write requests.
- **Conflict Resolution**: Resolves conflicts when multiple units attempt to write to the same register.
- **Write Selection**: Selects the appropriate write data and control signals based on the arbitration result.

### Write-Back FIFO

The Write-Back FIFO buffers write requests to handle timing variations and ensure orderly register updates:

- **Request Buffering**: Stores write requests that cannot be immediately serviced.
- **Almost-Full Signaling**: Provides feedback to execution units when the FIFO is nearly full.
- **Request Forwarding**: Forwards buffered requests to the register file when they can be serviced.

### Output Interface

The output interface connects to the register file and provides the necessary signals for register updates:

- **Clear Signal (o_clr)**: Indicates a register clear operation.
- **Address Signal (o_addr)**: Specifies the register address to be written.
- **Bank A Signals**: Control signals and data for writing to register bank A.
- **Bank B Signals**: Control signals and data for writing to register bank B.

## Write-Back Process

The write-back process involves several steps:

1. **Result Reception**: The WBU receives results from various execution units along with destination register information.
2. **Arbitration**: When multiple results are available, the arbitration logic determines which result should be written first.
3. **Write Selection**: The selected result is prepared for writing to the register file.
4. **Register File Update**: The result is written to the appropriate register(s) in the register file.
5. **Feedback Signaling**: The WBU provides feedback to execution units to indicate when they can send more results.

## Arbitration Priority

The WBU implements a priority-based arbitration scheme to resolve conflicts:

1. **Register Clear Operations**: Highest priority, used for system-level operations.
2. **LSU Results (b0, b1, b2)**: High priority, ensuring memory operation results are promptly written.
3. **MPU Results (a)**: Medium priority, for basic arithmetic and logical operations.
4. **Buffered Results (c)**: Lower priority, for results that have been buffered in the FIFO.
5. **XPU and FPU Results**: Lowest priority, as these operations typically have longer latency and can tolerate some delay.

## Register Write Control

The WBU provides fine-grained control over register writes:

- **Enable Signals**: Control which register banks (A, B) are written.
- **Byte-Enable Signals**: Control which bytes within a register are written.
- **Tag Signals**: Provide additional information about the write operation.
- **Mode Signal**: Controls special write modes, such as writing to register pairs.

## Dual-Thread Support

The WBU supports dual-threading with the following features:

- **Thread-Specific Writes**: Ensures that results are written to the correct thread's register context.
- **Independent Arbitration**: Maintains separate arbitration for each thread's register writes.
- **Thread Isolation**: Prevents register updates from one thread from affecting the other thread.

## Buffering Mechanism

The WBU implements a buffering mechanism to handle timing variations:

- **FIFO Buffer**: Uses a FIFO (First-In-First-Out) buffer to store write requests that cannot be immediately serviced.
- **Almost-Full Detection**: Detects when the FIFO is nearly full and signals execution units to pause sending results.
- **Request Forwarding**: Forwards buffered requests to the register file when they can be serviced.

## Configuration Options

The WBU can be configured through several parameters:

- **FLOAT_HW**: Controls whether basic floating-point hardware support is enabled ("ON" or "OFF").
- **FLOAT_ADV_HW**: Controls whether advanced floating-point hardware support is enabled ("ON" or "OFF").
- **FORCE_RST**: Controls reset behavior for simulation and synthesis.

These parameters allow the WBU to be tailored to specific application requirements and available FPGA resources.

## Implementation Details

The WBU is implemented in Verilog/SystemVerilog and consists of several modules:

- **eco32_core_wbu_box.v**: Main WBU module that implements the arbitration logic and write-back control.
- **eco32_core_wbu_lff.v**: FIFO module for buffering write requests.

The implementation uses several techniques to ensure efficient operation:

- **Pipelined Design**: Implements a pipelined design to maximize throughput.
- **Priority Encoding**: Uses priority encoding for efficient arbitration.
- **Resource Sharing**: Shares resources between threads to minimize FPGA resource usage.
- **Configurable Implementation**: Adapts to different floating-point support requirements.

## Integration with the Processor

The WBU is tightly integrated with the ECO32 processor:

- **Register File Interface**: Connects to the register file for updating registers.
- **Execution Unit Interfaces**: Connects to various execution units to receive results.
- **Pipeline Coordination**: Coordinates with the processor pipeline to ensure proper instruction completion.
- **Feedback Signaling**: Provides feedback to execution units to control result delivery timing.

## Performance Considerations

The WBU is designed for high performance:

- **Low-Latency Operation**: Minimizes the latency between result availability and register update.
- **High Throughput**: Supports multiple register writes per cycle when possible.
- **Efficient Arbitration**: Implements efficient arbitration to minimize stalls.
- **Buffering**: Uses buffering to handle timing variations and maintain high throughput.
- **Dual-Thread Support**: Efficiently handles register updates for two hardware threads.

## Error Handling

The WBU implements error detection and handling:

- **FIFO Overflow Protection**: Prevents FIFO overflow by signaling execution units to pause sending results.
- **Write Conflict Detection**: Detects and resolves conflicts when multiple units attempt to write to the same register.
- **Invalid Write Detection**: Detects attempts to write to invalid registers or with invalid control signals.

These error handling mechanisms ensure reliable operation even under high load conditions.
