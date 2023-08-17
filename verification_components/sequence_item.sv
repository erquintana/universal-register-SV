class sequence_item #(DEPTH, DATA_WIDTH);
    logic clk;
    logic rst;
    logic [DEPTH-1:0] read_addr;
    logic [DEPTH-1:0] write_addr;
    logic [DATA_WIDTH-1:0] write_data;
    logic write_en;
	logic read_en;
    logic [DATA_WIDTH-1:0] read_data;
    logic busy;

endclass
