# LSU (Load-Store Unit)

## Overview

The Load-Store Unit (LSU) is a critical component of the ECO32 processor architecture, responsible for handling all memory access operations. It serves as the interface between the processor core and the memory subsystem, managing data transfers between registers and memory. The LSU implements a sophisticated memory hierarchy with a data cache system to optimize memory access performance.

## Key Features

- **Memory Access Management**: Handles all load and store operations between processor registers and memory.
- **Data Cache Integration**: Incorporates a 2-way set-associative data cache for efficient memory access (detailed in [data_cache.md](data_cache.md)).
- **Address Translation**: Performs virtual-to-physical address translation for memory operations.
- **Memory Protection**: Enforces memory access permissions and detects access violations.
- **Dual-Thread Support**: Maintains separate contexts for two hardware threads, enabling efficient multithreading.
- **Variable Data Width Operations**: Supports byte, half-word, word, and twin-word (64-bit) memory operations.
- **Alignment Handling**: Manages aligned and unaligned memory accesses with appropriate data rotation.
- **NoC Interface**: Provides connectivity to the Network-on-Chip for accessing main memory and maintaining cache coherency across multiple cores.

## Architecture

The LSU architecture consists of several key components:

### Memory Access Pipeline

The LSU implements a multi-stage pipeline for processing memory operations:

1. **A0 Stage**: Initial instruction decoding and address generation
2. **B1 Stage**: Cache lookup and hit/miss determination
3. **A2 Stage**: Data processing and cache control
4. **B3 Stage**: Result preparation and writeback control

### Data Cache System

The LSU incorporates a sophisticated data cache system, as detailed in [data_cache.md](data_cache.md). Key aspects include:

- 2-way set-associative design
- Configurable cache size (8KB to 64KB)
- 32-byte cache lines
- Write-back policy with dirty page tracking
- Hardware-managed coherency

### Address Translation Unit

This unit translates virtual addresses to physical addresses and enforces memory protection:

- **Page Tables**: Store mapping information for virtual to physical address translation
- **Protection Bits**: Enforce read, write, and execute permissions
- **Exception Generation**: Detect and report memory access violations

### Memory Operation Controller

This component manages the execution of memory operations:

- **Load Operations**: Read data from memory into registers
- **Store Operations**: Write data from registers to memory
- **Atomic Operations**: Support for atomic read-modify-write operations
- **Memory Barriers**: Enforce ordering constraints on memory operations

### NoC Interface

The Network-on-Chip interface enables communication with main memory and other cores:

- **Packet-Based Communication**: Uses a packet-based protocol for memory transactions
- **Cache Coherency**: Maintains coherency across multiple cores
- **Memory Request Handling**: Manages memory requests and responses

## Memory Operations

### Load Operations

Load operations retrieve data from memory and place it in processor registers:

1. **Address Generation**: Calculate the effective address using base register and offset
2. **Memory Access**: Access the data cache or main memory
3. **Data Alignment**: Align and extend the data as needed (sign or zero extension)
4. **Register Writeback**: Write the data to the destination register(s)

Supported load operations include:
- **LB/LBU**: Load byte (signed/unsigned)
- **LH/LHU**: Load half-word (signed/unsigned)
- **LW**: Load word
- **LT**: Load twin-word (64-bit)

### Store Operations

Store operations write data from processor registers to memory:

1. **Address Generation**: Calculate the effective address
2. **Data Preparation**: Prepare the data for writing
3. **Memory Access**: Update the data cache or main memory
4. **Cache Management**: Update cache state and dirty flags

Supported store operations include:
- **SB**: Store byte
- **SH**: Store half-word
- **SW**: Store word
- **ST**: Store twin-word (64-bit)

### Special Memory Operations

The LSU also supports special memory operations:

- **Atomic Operations**: Read-modify-write operations that are executed atomically
- **Memory Barriers**: Operations that enforce ordering constraints on memory accesses
- **Cache Control Operations**: Operations that manage cache state (flush, invalidate, etc.)

## Integration with the Processor Pipeline

The LSU is tightly integrated with the ECO32 processor pipeline:

- **IDU Interface**: Receives decoded instructions from the Instruction Decode Unit
- **Register File Interface**: Accesses register operands and writes results back to registers
- **MPU Coordination**: Coordinates with the Main Processing Unit for address calculation and data processing
- **Exception Handling**: Reports memory-related exceptions to the processor core

## Performance Optimizations

The LSU implements several optimizations to enhance memory access performance:

- **Data Cache**: Reduces memory access latency by caching frequently accessed data (see [data_cache.md](data_cache.md))
- **Write Buffering**: Buffers store operations to allow the processor to continue execution
- **Data Forwarding**: Forwards data from pending stores to subsequent loads to the same address
- **Speculative Execution**: Begins processing memory operations speculatively to hide latency
- **Parallel Access**: Supports parallel access to different cache ways and memory banks

## Implementation Details

The LSU is implemented in Verilog/SystemVerilog and consists of several modules:

- **eco32_core_lsu_box.v**: Main LSU module that integrates all components
- **Data Cache Components**: Various modules implementing the data cache (detailed in [data_cache.md](data_cache.md))
- **Address Translation Components**: Modules for virtual-to-physical address translation
- **Memory Operation Controllers**: Modules that manage different types of memory operations
- **NoC Interface Components**: Modules that handle communication with the Network-on-Chip

## Configuration Parameters

The LSU can be configured through several parameters:

- **CORE_DCACHE_SIZE**: Sets the data cache size (8KB, 16KB, 32KB, or 64KB)
- **PAGE_ADDR_WIDTH**: Derived from the cache size, determines the number of pages per way
- **FORCE_RST**: Controls reset behavior for simulation and synthesis

These parameters allow the LSU to be tailored to specific application requirements and available FPGA resources.

## Error Handling

The LSU implements comprehensive error detection and handling:

- **Access Violations**: Detects attempts to access memory without proper permissions
- **Alignment Errors**: Reports unaligned accesses that are not supported
- **Page Faults**: Detects references to pages that are not present in memory
- **Cache Errors**: Detects and reports cache-related errors

When an error is detected, the LSU generates an appropriate exception and provides information to the processor core for exception handling.