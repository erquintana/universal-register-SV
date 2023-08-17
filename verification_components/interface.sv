// In the interface the variables are declared as datatypes only, and 
// in clocking block and modport we define skew and directions respectively.
interface URA_inf #(DEPTH, DATA_WIDTH)(input clk, rst);
    logic [DEPTH-1:0] read_addr;
    logic [DEPTH-1:0] write_addr;
    logic [DATA_WIDTH-1:0] write_data;
    logic write_en;
	logic read_en;
    logic [DATA_WIDTH-1:0] read_data;
    logic busy;

    // Clocking blocks are used to define skew for signals and also acces
    // and synchronization.
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output rst;
        output read_addr;
        output write_addr;
        output write_data;
        output write_en;
        output read_en;
        output read_data;
        output busy;
    endclocking

    // If connected to an interface modport, a module sees only:
        // ● Ports defined in that modport
        // ● Methods imported from that modpor
    // To restrict interface access within a module, there are modport lists with directions declared 
    // within the interface. The keyword modport indicates that the directions are declared as if 
    // inside the module.
    // Modports create different views of an interface. --> access / direction
    modport driver_mp (clocking driver_cb, input clk, rst);

    // Clocking blocks are used to define skew for signals
    // and synchronization.
    clocking monitor_cb @(posedge clk);
        default input #1 output #1;
        input rst;
        input read_addr;
        input write_addr;
        input write_data;
        input write_en;
        input read_en;
        input read_data;
        input busy;
    endclocking

    // If connected to an interface modport, a module sees only:
        // ● Ports defined in that modport
        // ● Methods imported from that modpor
    // To restrict interface access within a module, there are modport lists with directions declared 
    // within the interface. The keyword modport indicates that the directions are declared as if 
    // inside the module.
    // Modports create different views of an interface.
    modport monitor_mp (clocking monitor_cb, input clk, rst);

endinterface