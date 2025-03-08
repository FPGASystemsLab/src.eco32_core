# Data Cache in ECO32 Processor

## Overview

The data cache in the ECO32 processor is implemented within the Load-Store Unit (LSU) and serves as a critical component for efficient memory access operations. It is designed to reduce memory access latency by storing frequently accessed data closer to the processor core. The cache architecture follows a 2-way set-associative design with configurable size and supports dual-threading capabilities.

## Key Features

- **2-Way Set-Associative Design**: Provides a balance between direct-mapped and fully associative caches, offering good hit rates while maintaining reasonable implementation complexity.
- **Configurable Cache Size**: Supports multiple cache size configurations (8KB, 16KB, 32KB, 64KB) to adapt to different application requirements and FPGA resources.
- **32-Byte Cache Lines**: Each cache line contains 32 bytes (8 words of 4 bytes each), optimizing for common memory access patterns.
- **Dual-Thread Support**: Maintains separate cache contexts for two hardware threads, enabling efficient multithreading without cache thrashing.
- **Write-Back Policy**: Uses a write-back policy with a page write flag (PWF) mechanism to track modified cache lines, reducing memory traffic.
- **Page-Based Organization**: Organizes cache entries based on memory pages, facilitating efficient address translation and memory protection.
- **Hardware-Managed Coherency**: Implements hardware mechanisms to maintain cache coherency across multiple cores when connected via the NoC (Network-on-Chip).

## Architecture

The data cache architecture consists of several key components:

### Data Cache Unit (DCU)

The Data Cache Unit is the core component that stores and manages cached data. It includes:

- **Cache Ways**: Two independent cache ways (sets) that can hold the same memory address, increasing the probability of a cache hit.
- **Page Tables**: Store address translation and protection information for each cached page.
- **Memory Arrays**: Store the actual cached data with byte-level access granularity.
- **Page Write Flags**: Track which cache lines have been modified and need to be written back to main memory.

### Data Cache Manager (DCM)

The Data Cache Manager handles cache operations and interfaces with the rest of the processor:

- **Cache Miss Handling**: Manages the process of fetching data from main memory when a cache miss occurs.
- **Replacement Policy**: Implements the algorithm for deciding which cache line to replace when a new line needs to be brought into a full cache.
- **Write-Back Operations**: Coordinates writing modified cache lines back to main memory.
- **NoC Interface**: Manages communication with the Network-on-Chip for memory operations that need to access main memory or other cores' caches.

## Cache Organization

The cache is organized as follows:

- **Cache Size**: Configurable as 8KB, 16KB, 32KB, or 64KB
- **Ways**: 2 ways per thread
- **Threads**: 2 hardware threads
- **Page Size**: 32 bytes (8 words of 4 bytes each)
- **Addressing**: Virtual addressing with hardware address translation

The number of pages per way depends on the configured cache size:
- 8KB cache: 32 pages per way per thread (5-bit page address)
- 16KB cache: 64 pages per way per thread (6-bit page address)
- 32KB cache: 128 pages per way per thread (7-bit page address)
- 64KB cache: 256 pages per way per thread (8-bit page address)

## Cache Operations

### Read Operation

1. **Address Generation**: The LSU generates a virtual address based on the instruction and register values.
2. **Tag Comparison**: The virtual address is compared with the tags in both cache ways to determine if the data is present in the cache.
3. **Cache Hit**: If the data is found in the cache, it is read and returned to the processor.
4. **Cache Miss**: If the data is not found, a cache miss occurs, triggering the cache miss handling process.

### Write Operation

1. **Address Generation**: Similar to read operations, a virtual address is generated.
2. **Tag Comparison**: The address is compared with cache tags to check for a hit.
3. **Cache Hit**: If the data is in the cache, it is updated, and the corresponding page write flag is set to indicate the line is dirty.
4. **Cache Miss**: If the data is not in the cache, a cache line is allocated, the data is fetched from memory, updated, and the page write flag is set.

### Cache Miss Handling

When a cache miss occurs, the following steps are taken:

1. **Line Selection**: If the cache is full, a line is selected for replacement based on the replacement policy.
2. **Write-Back**: If the selected line is dirty (modified), its contents are written back to main memory.
3. **Line Fill**: The new data is fetched from main memory and placed in the cache.
4. **Operation Completion**: The original operation (read or write) is completed using the newly cached data.

## Implementation Components

The data cache implementation consists of several Verilog modules:

### eco32_core_lsu_dcu_way.v

Implements a single cache way, including tag comparison logic and hit/miss detection. Each way contains:
- Tag storage for identifying the memory address associated with cached data
- Status bits (valid, dirty, locked, etc.)
- Interface to the page table and memory arrays

### eco32_core_lsu_dcu_mem.v

Implements the memory arrays that store the actual cached data. Features:
- Byte-addressable storage
- Support for partial word operations
- Dual-port design for simultaneous access by the processor and cache manager

### eco32_core_lsu_dcu_pt.v

Implements the page table that stores address translation and protection information:
- Maps virtual page addresses to physical addresses
- Stores protection bits (read, write, execute permissions)
- Supports thread-specific page tables

### eco32_core_lsu_dcu_pwf.v

Implements the page write flag mechanism that tracks modified cache lines:
- Maintains flags for each page indicating whether it has been modified
- Supports clearing flags when pages are written back to memory
- Separate tracking for each thread and way

### eco32_core_lsu_dcm.v

Implements the data cache manager that coordinates cache operations:
- Handles cache miss processing
- Manages communication with main memory via the NoC
- Implements the cache replacement policy
- Coordinates write-back operations

## Performance Considerations

The data cache is designed for high performance:

- **Low-Latency Access**: Cache hits provide data with minimal latency (typically 1-2 cycles)
- **High Bandwidth**: Multiple bytes can be accessed simultaneously
- **Efficient Replacement**: The 2-way set-associative design provides a good balance between hit rate and implementation complexity
- **Thread Isolation**: Separate cache contexts for each thread prevent thrashing when multiple threads are active
- **Write Buffering**: Dirty lines are only written back when necessary, reducing memory traffic

## Integration with the Processor

The data cache is tightly integrated with the ECO32 processor:

- **LSU Interface**: Directly connected to the Load-Store Unit for handling memory operations
- **NoC Interface**: Connected to the Network-on-Chip for communication with main memory and other cores
- **Pipeline Integration**: Designed to work efficiently with the processor's pipeline, minimizing stalls due to memory access

## Configuration Parameters

The data cache can be configured through several parameters:

- **CORE_DCACHE_SIZE**: Sets the overall cache size (8KB, 16KB, 32KB, or 64KB)
- **PAGE_ADDR_WIDTH**: Derived from the cache size, determines the number of pages per way
- **FORCE_RST**: Controls reset behavior for simulation and synthesis

These parameters allow the cache to be tailored to specific application requirements and available FPGA resources.