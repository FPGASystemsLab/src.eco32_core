# IFU (Instruction Fetch Unit)

## Overview

The Instruction Fetch Unit (IFU) is a fundamental component of the ECO32 processor architecture, responsible for retrieving instructions from memory and feeding them into the processor pipeline. It serves as the first stage of the instruction execution process, ensuring a continuous flow of instructions to the subsequent pipeline stages. The IFU implements sophisticated mechanisms for instruction caching, branch prediction, and event handling to optimize instruction throughput and minimize pipeline stalls.

## Key Features

- **Instruction Cache**: Incorporates a configurable instruction cache to reduce memory access latency and improve instruction throughput.
- **Dual-Thread Support**: Maintains separate instruction streams for two hardware threads, enabling efficient multithreading.
- **Branch Prediction**: Implements branch prediction mechanisms to minimize pipeline stalls due to control flow changes.
- **Event Handling**: Processes processor events and exceptions at the instruction fetch stage.
- **NoC Interface**: Provides connectivity to the Network-on-Chip for accessing main memory and maintaining cache coherency.
- **Configurable Cache Size**: Supports multiple cache size configurations (4KB, 8KB, 16KB, 32KB) to adapt to different application requirements.
- **Instruction Prefetching**: Prefetches instructions to hide memory latency and maintain pipeline efficiency.
- **Instruction Alignment**: Handles instruction alignment and boundary crossing to ensure proper instruction delivery.

## Architecture

The IFU architecture consists of several key components:

### Instruction Cache Unit (ICU)

The Instruction Cache Unit stores recently accessed instructions to reduce memory access latency:

- **Cache Ways**: Two independent cache ways (sets) that can hold the same memory address, increasing the probability of a cache hit.
- **Page Tables**: Store address translation and protection information for each cached page.
- **Memory Arrays**: Store the actual cached instructions with word-level access granularity.
- **Tag Comparison**: Performs fast tag comparison to determine cache hits and misses.

### Instruction Cache Manager (ICM)

The Instruction Cache Manager handles cache operations and interfaces with the rest of the processor:

- **Cache Miss Handling**: Manages the process of fetching instructions from main memory when a cache miss occurs.
- **Replacement Policy**: Implements the algorithm for deciding which cache line to replace when a new line needs to be brought into a full cache.
- **NoC Interface**: Manages communication with the Network-on-Chip for memory operations that need to access main memory.

### Event Manager (EVM)

The Event Manager handles processor events and exceptions:

- **Event Detection**: Identifies and processes events from various sources.
- **Event Prioritization**: Prioritizes events based on their type and urgency.
- **Event Delivery**: Delivers events to the appropriate thread context.
- **Event Acknowledgment**: Manages event acknowledgment and completion.

### Instruction Pipeline

The IFU implements a multi-stage pipeline for processing instructions:

1. **BN Stage**: Next program counter generation
2. **A0 Stage**: Initial instruction fetch and address translation
3. **B1 Stage**: Cache lookup and hit/miss determination
4. **A2 Stage**: Instruction data retrieval and processing
5. **B3 Stage**: Instruction alignment and formatting
6. **A4 Stage**: Final instruction preparation
7. **B5 Stage**: Instruction delivery to the IDU (Instruction Decode Unit)

## Instruction Cache Organization

The instruction cache is organized as follows:

- **Cache Size**: Configurable as 4KB, 8KB, 16KB, or 32KB
- **Ways**: 2 ways per thread
- **Threads**: 2 hardware threads
- **Page Size**: 32 bytes (8 words of 4 bytes each)
- **Addressing**: Virtual addressing with hardware address translation

The number of pages per way depends on the configured cache size:
- 4KB cache: 16 pages per way per thread (4-bit page address)
- 8KB cache: 32 pages per way per thread (5-bit page address)
- 16KB cache: 64 pages per way per thread (6-bit page address)
- 32KB cache: 128 pages per way per thread (7-bit page address)

## Instruction Fetch Process

The instruction fetch process involves several steps:

1. **Program Counter Generation**: The IFU generates the next program counter (PC) based on sequential execution, branch prediction, or explicit jumps.
2. **Address Translation**: The virtual address is translated to a physical address using the page tables.
3. **Cache Lookup**: The physical address is used to look up the instruction in the cache.
4. **Cache Hit Processing**: If the instruction is found in the cache, it is retrieved and prepared for delivery.
5. **Cache Miss Handling**: If the instruction is not found in the cache, a cache miss occurs, triggering the cache miss handling process.
6. **Instruction Alignment**: The instruction is aligned and formatted according to its size and type.
7. **Instruction Delivery**: The instruction is delivered to the IDU for decoding and execution.

## Branch Handling

The IFU implements mechanisms for efficient branch handling:

- **Branch Prediction**: Predicts the outcome of branch instructions to minimize pipeline stalls.
- **Jump Processing**: Handles explicit jump instructions by updating the program counter.
- **Return Address Stack**: Maintains a stack of return addresses for efficient subroutine handling.
- **Branch Target Buffer**: Caches branch target addresses to speed up branch resolution.

## Event Handling

The IFU processes various processor events and exceptions:

- **Interrupt Processing**: Handles external interrupts by redirecting instruction fetch to the appropriate handler.
- **Exception Handling**: Processes exceptions such as page faults or protection violations.
- **System Call Processing**: Manages system calls by redirecting instruction fetch to the system call handler.
- **Debug Events**: Handles debug-related events for processor debugging and monitoring.

## NoC Integration

The IFU interfaces with the Network-on-Chip for memory access:

- **Packet-Based Communication**: Uses a packet-based protocol for memory transactions.
- **Cache Coherency**: Maintains coherency across multiple cores.
- **Memory Request Handling**: Manages memory requests and responses for instruction fetching.

## Thread Management

The IFU supports dual-threading with the following features:

- **Independent Program Counters**: Maintains separate program counters for each thread.
- **Thread Switching**: Alternates between threads on a cycle-by-cycle basis or based on events.
- **Thread Priority**: Supports thread prioritization for critical tasks.
- **Thread Synchronization**: Provides mechanisms for thread synchronization and communication.

## Performance Optimizations

The IFU implements several optimizations to enhance instruction fetch performance:

- **Instruction Cache**: Reduces memory access latency by caching frequently accessed instructions.
- **Instruction Prefetching**: Fetches instructions ahead of time to hide memory latency.
- **Branch Prediction**: Minimizes pipeline stalls due to control flow changes.
- **Dual-Thread Support**: Maximizes utilization of the instruction fetch pipeline.
- **Parallel Cache Access**: Accesses multiple cache ways in parallel for faster lookup.

## Implementation Details

The IFU is implemented in Verilog/SystemVerilog and consists of several modules:

- **eco32_core_ifu_box.v**: Main IFU module that integrates all components.
- **eco32_core_ifu_icu_way.v**: Implements a single instruction cache way.
- **eco32_core_ifu_icu_way_mem.v**: Implements the memory arrays for the instruction cache.
- **eco32_core_ifu_icu_way_pt.v**: Implements the page tables for address translation.
- **eco32_core_ifu_icm_box.v**: Implements the instruction cache manager.
- **eco32_core_ifu_evm_box.v**: Implements the event manager.
- **eco32_core_ifu_evm_ff.v**: Implements event FIFO buffers.
- **eco32_core_ifu_evm_mgr.v**: Implements event management logic.
- **eco32_core_ifu_evm_token.v**: Implements event token handling.

## Configuration Parameters

The IFU can be configured through several parameters:

- **ICACHE_SIZE**: Sets the instruction cache size (4KB, 8KB, 16KB, or 32KB).
- **FORCE_RST**: Controls reset behavior for simulation and synthesis.
- **MEM_SP_BOOTROM_START_LOG**: Specifies the logical address of the boot ROM.

These parameters allow the IFU to be tailored to specific application requirements and available FPGA resources.

## Integration with the Processor

The IFU is tightly integrated with the ECO32 processor:

- **IDU Interface**: Delivers fetched and processed instructions to the Instruction Decode Unit.
- **JPU Interface**: Receives jump and branch information from the Jump Processing Unit.
- **LSU Interface**: Coordinates with the Load-Store Unit for memory access synchronization.
- **NoC Interface**: Connects to the Network-on-Chip for memory access and inter-core communication.

## Error Handling

The IFU implements comprehensive error detection and handling:

- **Instruction Cache Errors**: Detects and reports cache-related errors.
- **Address Translation Errors**: Identifies invalid address translations and protection violations.
- **Memory Access Errors**: Detects errors during memory access operations.
- **Event Processing Errors**: Handles errors in event processing and delivery.

When an error is detected, the IFU generates an appropriate exception and provides information to the processor core for exception handling.