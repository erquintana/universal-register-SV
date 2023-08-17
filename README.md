# Project Title: Universal Register File (URF) with Read and Write Operations

NOTE: code is all implemented in the testbench.sv for easy editing and running in EDA playground. So, verification_components folder has empty files by now.
Find live executable code here: <https://www.edaplayground.com/x/iJsR>

## Project Description

Design and implement a Universal Register File (URF) module that supports both read and write operations. The URF should have a generic width and depth, making it flexible to use in different designs. It should support read and write operations on multiple clock cycles. The URF should also have error checking mechanisms to handle invalid read/write addresses.

## Module Specifications

### Universal Register File (URF) Module

#### Parameters

- DATA_WIDTH: Width of each register in bits (e.g., 8, 16, 32, etc.).
- DEPTH: Number of registers in the URF (e.g., 16, 32, 64, etc.).

#### Inputs

- clk: Clock signal for synchronous operations.
- rst: Asynchronous reset signal to reset the URF to its initial state.
- read_addr: Input signal to specify the address for read operations.
- write_addr: Input signal to specify the address for write operations.
- write_data: Input signal to provide data for write operations.
- write_enable: Input signal to enable/disable write operations.
- read_enable: Input signal to enable/disable read operations.

#### Outputs

- read_data: Output signal to provide the data read from the specified address.
- busy: Output signal to indicate whether the URF is busy with a read or write operation.

## Explanation of URF Logic

- The URF is a block of registers where each register can store data of width DATA_WIDTH.
- The number of registers in the URF is determined by the DEPTH parameter, allowing for a configurable number of storage locations.
- The URF operates synchronously with the input clock (clk).
- The asynchronous reset (rst) signal is used to reset the URF to its initial state, clearing all register contents.
- To perform a read operation, the user provides the read address (read_addr). The URF outputs the data stored at the specified address on the read_data signal.
- To perform a write operation, the user provides the write address (write_addr) and the data to be written (write_data). The write_enable signal is used to enable the write operation. When write_enable is asserted, the URF writes the provided data to the specified address.
- The URF supports read and write operations on successive clock cycles, allowing for pipelined data processing.
- write_enable & read_enable can't happen at the same time

## Testbench Module

Instantiate the URF module and generate test stimuli to perform read and write operations on the URF.
Verify the correctness of the read and write operations by comparing the expected results with the actual results obtained from the URF.

You can start by defining the URF module with the specified inputs and outputs. Then, implement the read and write operations inside the URF module based on the provided addresses and data. Finally, create a testbench to verify the functionality of the URF module using different test cases.
