//------------------------------------------------------------------------------
// Project: URF - Universal Regiter File
// File:    universal_reg_array.sv
// Author:  Esteban Rodríguez Quintana
// Date:    <Date Created/Modified>
//
// Description: universal reg, memory like implemented with variable size
//
// Revision History:
// - <Date>: <Version / Modification Description>
//
//------------------------------------------------------------------------------

module universal_reg_array #(
    parameter int DATA_WIDTH,
    parameter int DEPTH
) (
    input logic clk,
    input logic rst,
    input logic [DEPTH-1:0] read_addr,
    input logic [DEPTH-1:0] write_addr,
    input logic [DATA_WIDTH-1:0] write_data,
    input logic write_en,
    input logic read_en,

    output logic [DATA_WIDTH-1:0] read_data,
    output logic busy
);

  logic [DATA_WIDTH-1:0] reg_array[DEPTH-1:0];

  // write and read control logic:
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // posedge rst:
      // cleaning out data:
      read_data <= 0;
      busy <= 0;
      // cleaning reg array:
      foreach (reg_array[i, j]) begin
        reg_array[i][j] <= 0;
      end
    end else begin
      // posedge clk:
      if (write_en) begin
        reg_array[write_addr] <= write_data;
        busy <= 1;
      end else if (read_en) begin     // reading data from reg array at read_addr and assigning
                                      // to output
        busy <= 1;
        read_data <= reg_array[read_addr];
      end else begin
        busy <= 0;  // not write nor read ocurring, then not busy
      end
    end
  end


endmodule
