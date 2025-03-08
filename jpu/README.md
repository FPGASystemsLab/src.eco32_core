# JPU (Jump Processing Unit)

## Overview

The Jump Processing Unit (JPU) is a specialized component of the ECO32 processor architecture, responsible for handling all control flow operations including jumps, branches, subroutine calls, and returns. It serves as the primary mechanism for altering the program counter (PC) and redirecting instruction execution flow. The JPU works in conjunction with other processor units to ensure efficient and accurate control flow management, which is critical for program execution and performance.

## Key Features

- **Control Flow Management**: Handles all types of control flow operations including jumps, branches, subroutine calls, and returns.
- **Address Calculation**: Computes target addresses for jumps and branches based on various addressing modes.
- **Control Register Access**: Provides access to special control registers used for storing return addresses and system call entry points.
- **Exception Handling Support**: Facilitates exception handling by redirecting control flow to appropriate exception handlers.
- **Event Acknowledgment**: Acknowledges processor events during control flow changes.
- **Dual-Thread Support**: Maintains separate control flow contexts for two hardware threads.
- **Pipeline Coordination**: Coordinates with other pipeline stages to ensure proper control flow transitions.

## Architecture

The JPU architecture consists of several key components:

### Control Flow Processing Pipeline

The JPU implements a two-stage pipeline for processing control flow operations:

1. **A0 Stage**: Initial jump instruction processing and address calculation
2. **B1 Stage**: Final address resolution and control flow redirection

### Control Register File

The JPU maintains a set of control registers that store important addresses for control flow operations:

- **CRA Registers**: 32 control registers for thread 0 and 32 for thread 1, storing base addresses for jumps and calls
- **CRB Registers**: 32 control registers for thread 0 and 32 for thread 1, storing additional control information

### Address Calculation Unit

This unit calculates target addresses for control flow operations:

- **Base Address Selection**: Selects between general-purpose register base and control register base
- **Offset Addition**: Adds appropriate offsets to base addresses
- **Alignment Handling**: Ensures proper alignment of target addresses

### Event Handling Unit

This component manages event acknowledgment during control flow changes:

- **Event Detection**: Identifies events that require acknowledgment
- **Event Acknowledgment**: Generates acknowledgment signals for detected events
- **Event Coordination**: Coordinates event handling with other processor units

## Control Flow Operations

The JPU supports various types of control flow operations:

### Direct Jumps

Direct jumps involve an immediate target address:

- **Unconditional Jumps**: Jump to a specified target address regardless of conditions
- **Conditional Jumps**: Jump to a specified target address only if certain conditions are met
- **Relative Jumps**: Jump to an address relative to the current program counter

### Register-Based Jumps

Register-based jumps use register values to determine the target address:

- **Register Direct**: Jump to the address contained in a register
- **Register Indirect**: Jump to the address calculated from a base register and offset
- **Register Indexed**: Jump to the address calculated from multiple registers

### Subroutine Calls and Returns

The JPU handles subroutine operations:

- **Call Operations**: Save the return address and jump to the subroutine entry point
- **Return Operations**: Jump back to the saved return address
- **Nested Calls**: Support for multiple levels of subroutine nesting

### System Calls and Exceptions

The JPU facilitates system-level control flow operations:

- **System Calls**: Jump to system service routines with appropriate context saving
- **Exception Handling**: Redirect control flow to exception handlers
- **Interrupt Processing**: Handle interrupts by redirecting to interrupt service routines

## Control Word Format

The JPU receives a control word (jp_cw) from the IDU that specifies the operation to be performed:

- **Bit 0**: Jump enable (jp_ena)
- **Bits 1-2**: Processor ID selection (jp_pid)
- **Bit 3**: Register/Constant selection for EID
- **Bit 4**: Control register enable (jp_cre)
- **Bits 7-10**: Control register address
- **Bit 11**: Address alignment control

## Address Calculation

The JPU calculates target addresses using the following components:

- **Base Address**: Either from a general-purpose register (i_r0_data) or a control register (cra_addr)
- **Offset**: From a general-purpose register (i_r2_data) or an immediate value
- **Alignment**: Proper alignment based on instruction requirements

The final address is calculated as: Base + Offset, with appropriate alignment applied.

## Control Register Management

The JPU manages control registers that store important addresses:

- **Return Addresses**: Store return addresses for subroutine calls and exceptions
- **System Call Entry Points**: Store entry points for system services
- **Exception Handlers**: Store addresses of exception handling routines
- **Thread Context**: Maintain separate control register contexts for each thread

Control registers can be written by the MPU through the jcr_wen, jcr_tid, jcr_addr, jcr_dataL, and jcr_dataH signals.

## Pipeline Integration

The JPU is tightly integrated with the processor pipeline:

- **IDU Interface**: Receives decoded jump instructions and operands from the Instruction Decode Unit
- **IFU Interface**: Provides target addresses to the Instruction Fetch Unit for fetching instructions from new locations
- **MPU Interface**: Coordinates with the Main Processing Unit for condition evaluation and control register updates
- **LSU Interface**: Synchronizes with the Load-Store Unit to ensure memory operations complete properly before control flow changes

## Event Handling

The JPU handles various processor events during control flow changes:

- **Exception Events**: Acknowledges exceptions and redirects control flow to exception handlers
- **System Call Events**: Processes system calls by redirecting to appropriate system services
- **Interrupt Events**: Handles interrupts by saving context and jumping to interrupt handlers
- **Debug Events**: Supports debugging by facilitating breakpoints and single-stepping

## Implementation Details

The JPU is implemented in Verilog/SystemVerilog in the file `eco32_core_jpu_box.v`. Key implementation aspects include:

- **Control Register Implementation**: Uses distributed RAM for fast access to control registers
- **Pipeline Registers**: Uses non-extractable shift registers for pipeline stage registers
- **Address Calculation Logic**: Implements efficient address calculation with proper alignment
- **Event Handling Logic**: Implements logic for event detection and acknowledgment
- **Control Flow Coordination**: Implements mechanisms to coordinate with other pipeline stages

## Performance Considerations

The JPU is designed for high performance:

- **Low-Latency Operation**: Processes jump instructions in just two pipeline stages
- **Efficient Address Calculation**: Optimized for fast target address computation
- **Control Register Caching**: Maintains control registers in fast, local storage
- **Pipeline Coordination**: Minimizes pipeline stalls during control flow changes
- **Dual-Thread Support**: Efficiently handles control flow for two hardware threads

## Configuration Parameters

The JPU can be configured through the FORCE_RST parameter, which controls reset behavior for simulation and synthesis.

## Integration with the Processor

The JPU outputs several signals that control processor operation:

- **o_stb**: Indicates a valid jump operation
- **o_evt_ack**: Acknowledges processor events
- **o_asid**: Specifies the address space ID for the target
- **o_pid**: Specifies the processor ID for the target
- **o_isw**: Provides instruction status word for the target
- **o_v_addr**: Specifies the target virtual address
- **fco_inst_jpf**: Indicates a jump is in progress to other pipeline stages

These signals ensure proper coordination with other processor units during control flow changes.
