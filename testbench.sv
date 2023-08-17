`timescale 1ns / 1ps

parameter int DEPTH = 32;
parameter int DATA_WIDTH = 8;
parameter int MAX_EXEC_TIME_NS = 500;

//////////////////////////////////////////////////////////////////////////////////
// INTERFASE
//////////////////////////////////////////////////////////////////////////////////
// In the interface the variables are declared as datatypes only, and
// in clocking block and modport we define skew and directions respectively.
interface ura_if #(int DEPTH = 16, int DATA_WIDTH = 32) ();
	logic clk;
	logic rst;
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
	endclocking

	// If connected to an interface modport, a module sees only:
	// ● Ports defined in that modport
	// ● Methods imported from that modport
	// To restrict interface access within a module, there are modport lists with directions declared
	// within the interface. The keyword modport indicates that the directions are declared as if
	// inside the module.
	// Modports create different views of an interface. --> access / direction
	modport DRIVER_MP(clocking driver_cb);

	// Clocking blocks are used to define skew for signals
	// and synchronization.
	clocking monitor_cb @(posedge clk);
		default input #1 output #1;
		input read_data;
		input busy;
	endclocking

	// If connected to an interface modport, a module sees only:
	// ● Ports defined in that modport
	// ● Methods imported from that modport
	// To restrict interface access within a module, there are modport lists with directions declared
	// within the interface. The keyword modport indicates that the directions are declared as if
	// inside the module.
	// Modports create different views of an interface.
	modport MONITOR_MP(clocking monitor_cb);


endinterface

//////////////////////////////////////////////////////////////////////////////////
// TRANSACTION_ITEM
//////////////////////////////////////////////////////////////////////////////////
class transaction_item #(int DEPTH, int DATA_WIDTH);
	// data properties:
	rand logic clk;
	rand logic rst;
	rand logic [DEPTH-1:0] read_addr;
	rand logic [DEPTH-1:0] write_addr;
	rand logic [DATA_WIDTH-1:0] write_data;
	rand logic write_en;
	rand logic read_en;
	rand logic [DATA_WIDTH-1:0] read_data;
	rand logic busy;

	// data property constraints:
	constraint rd_c { (read_en != 0) -> write_en != read_en;}
	constraint wr_c { (write_en != 0) -> write_en != read_en;}

	// constructor:
	function new();
		$display("Time = %0t\t[TRANS ITEM] : new trans item", $time);
	endfunction

	function void print();
		$display("Time = %0t\t[TRANS ITEM] : %p", $time, this);
	endfunction

endclass

//////////////////////////////////////////////////////////////////////////////////
// GENERATOR
//////////////////////////////////////////////////////////////////////////////////
class generator;
	int tr_count = 1;
	int tr_qty_to_generate;
	event transaction_ended;
	transaction_item #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH)) tr_item;
	mailbox g2d_mbx;

	function new(mailbox g2d_mbx, event transaction_ended);
		$display("Time = %0t\t[GEN] : new generator instance", $time);
		this.g2d_mbx = g2d_mbx;
		this.transaction_ended = transaction_ended;
		tr_item = new();
	endfunction

	// task to generate -N- of qty of transactions to be processed:
	task main();
		$display("============================================================================\nTime = %0t\t[GEN] : Sending item to g2d mailbox ===> packet # %0d]", $time, tr_count);
		// putting transaction inn to mailbox to driver:
		g2d_mbx.put(tr_item);
		tr_item.print();
		$display("Time = %0t\t[GEN] : item pushed to g2d mailbox", $time);
		tr_count++;
		@(transaction_ended);
	endtask

endclass

//////////////////////////////////////////////////////////////////////////////////
// DRIVER
//////////////////////////////////////////////////////////////////////////////////
class driver;
	event transaction_received; 
	int tr_count = 1;
	virtual ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf;
	mailbox g2d_mbx;
	transaction_item #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH)) tr_item;

	function new(virtual ura_if #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH)) vinf, mailbox g2d_mbx, event transaction_received);
		$display("Time = %0t\t[DRV] : new driver instance", $time);
		this.vinf = vinf;
		this.g2d_mbx = g2d_mbx;
		this.tr_item = new();
		this.transaction_received = transaction_received;
	endfunction

	task reset();
		wait (vinf.rst);
		$display("Time = %0t\t[DRV] : reset started", $time);
		vinf.DRIVER_MP.driver_cb.rst		<= 0;
		vinf.DRIVER_MP.driver_cb.read_addr	<= 0;
		vinf.DRIVER_MP.driver_cb.write_addr <= 0;
		vinf.DRIVER_MP.driver_cb.write_data <= 0;
		vinf.DRIVER_MP.driver_cb.write_en	<= 0;
		vinf.DRIVER_MP.driver_cb.read_en	<= 0;
		wait (!vinf.rst);
		$display("Time = %0t\t[DRV] : reset ended", $time);
	endtask

	task main();
		g2d_mbx.get(tr_item);	// getting data from generator
		$display("============================================================================\nTime = %0t\t[DRV] : Receiving item from g2d mailbox ===> packet # %0d ]", $time, tr_count);		
		$display("Time = %0t\t[DRV] : Item received ===> packet # %0d", $time, tr_count);
		tr_item.print();
		$display("Time = %0t\t[DRV] : Putting item into the interface", $time);	
		@(posedge vinf.clk); 
		vinf.DRIVER_MP.driver_cb.rst			<= 	tr_item.rst;
		vinf.DRIVER_MP.driver_cb.read_addr		<=	tr_item.read_addr;
		vinf.DRIVER_MP.driver_cb.write_addr		<=	tr_item.write_addr;
		vinf.DRIVER_MP.driver_cb.write_data		<=	tr_item.write_data;
		vinf.DRIVER_MP.driver_cb.write_en		<=	tr_item.write_en;
		vinf.DRIVER_MP.driver_cb.read_en		<=	tr_item.read_en;
		tr_count++;
		-> transaction_received;
	endtask


endclass

//////////////////////////////////////////////////////////////////////////////////
// MONITOR
//////////////////////////////////////////////////////////////////////////////////
class monitor;
	virtual ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf;
	mailbox m2s_mbx;

	function new(virtual ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf, mailbox m2s_mbx);
		$display("Time = %0t\t[MON] : new monitor instance", $time);
		this.m2s_mbx = m2s_mbx;
		this.vinf = vinf;
	endfunction
endclass

//////////////////////////////////////////////////////////////////////////////////
// SCOREBOARD
//////////////////////////////////////////////////////////////////////////////////
class scoreboard;
	// communication:
	mailbox m2s_mbx;

	function new(mailbox m2s_mbx);
		this.m2s_mbx = m2s_mbx;
	endfunction
endclass

//////////////////////////////////////////////////////////////////////////////////
// AGENT
//////////////////////////////////////////////////////////////////////////////////
class agent;
	// module communication:
	virtual ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf;
	mailbox g2d_mbx;
	mailbox m2s_mbx;
	event transaction_g2d_ready;

	// components:
	generator gen;
	driver drv;
	monitor mon;

	function new(virtual ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf, mailbox m2s_mbx);
		$display("Time = %0t\t[AGNT] : new agent instance", $time);
		this.m2s_mbx = m2s_mbx;
		this.vinf = vinf;

		g2d_mbx = new();
		m2s_mbx = new();

		gen = new(g2d_mbx, transaction_g2d_ready);
		drv = new(vinf, g2d_mbx, transaction_g2d_ready);
		mon = new(vinf, m2s_mbx);
	endfunction
endclass

//////////////////////////////////////////////////////////////////////////////////
// ENVIRONMENT
//////////////////////////////////////////////////////////////////////////////////
class environment;
	// communication:
	virtual interface ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf;
	mailbox m2s_mbx;

	// components:
	scoreboard scb;
	agent agnt;

	function new(virtual interface ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf);
	$display("\nSETTING UP ENVIRONMENT");	
	$display("Time = %0t\t[ENV] : new env instance", $time);
		this.vinf = vinf;
		m2s_mbx = new();
		scb = new(m2s_mbx);
		agnt = new(vinf, m2s_mbx);
	endfunction

endclass

//////////////////////////////////////////////////////////////////////////////////
// BASE_TEST
//////////////////////////////////////////////////////////////////////////////////
class base_test;
	environment env;
	string test_name;
	virtual ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf;
	transaction_item #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH)) tr_queue [$];
	int tr_queue_size = 10;

	function new(string test_name, virtual ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf);
		this.vinf = vinf;
		env = new(vinf);
		this.test_name = test_name; 
	endfunction

	virtual task generate_tr_queue_data();
	endtask
	
	task run();
		$display("\n=================\tBEGINING %s TEST\t=================", test_name);
		generate_tr_queue_data();

		// beginning to sent data to generator and then to driver one by one from tr_queue:
		while(tr_queue.size() > 0) begin
			env.agnt.gen.tr_item = tr_queue.pop_front();
			fork
				env.agnt.gen.main();
				env.agnt.drv.main();
			join_any
		end
		$display("\n=================\t%s TEST FINISHED\t=================\n", test_name);
	endtask
	
endclass

//////////////////////////////////////////////////////////////////////////////////
// RANDOM_TEST
//////////////////////////////////////////////////////////////////////////////////
class random_test extends base_test;
	transaction_item #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH)) tr;
	function new(string test_name, virtual ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf);
		super.new(test_name, vinf);
	endfunction

	task generate_tr_queue_data();
		int cnt = 1;
		for (int i=0; i<tr_queue_size; ++i) begin
			tr = new();
			if(!tr.randomize()) $fatal("FATAL on randomization at random_test");
			if(cnt == 1) begin
				tr.rst = 1;
			end else tr.rst = 0;
			tr_queue.push_back(tr);
			$display("-> Transaction # %0d pushed to queue", cnt);
			cnt++;
		end
	endtask
endclass

//////////////////////////////////////////////////////////////////////////////////
// WR_RD_TEST
//////////////////////////////////////////////////////////////////////////////////
class wr_rd_test extends base_test;
	transaction_item #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH)) tr;
	function new(string test_name, virtual ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) vinf);
		super.new(test_name, vinf);
	endfunction

	task generate_tr_queue_data();
		int cnt = 1;
		tr = new();
		tr.rst = 1;
		tr.write_en = 0;
		tr.read_en = 0;
		tr.read_addr = 0;
		tr.write_addr = 0;
		tr.write_data = 0;
		tr_queue.push_back(tr);
		$display("-> Transaction # %0d pushed to queue", cnt);
		cnt++;
		// writing in URA 0
		tr = new();
		tr.rst = 0;
		tr.write_en = 1;
		tr.read_en = 0;
		tr.read_addr = 'x;
		tr.write_addr = 0;
		tr.write_data = 10;
		tr_queue.push_back(tr);
		$display("-> Transaction # %0d pushed to queue", cnt);
		cnt++;
		// reading from URA 0
		tr = new();
		tr.rst = 0;
		tr.write_en = 0;
		tr.read_en = 1;
		tr.read_addr = 0;
		tr.write_addr = 'x;
		tr.write_data = 'x;
		tr_queue.push_back(tr);
		$display("-> Transaction # %0d pushed to queue", cnt);
		cnt++;
		// writing in URA 0
		tr = new();
		tr.rst = 0;
		tr.write_en = 1;
		tr.read_en = 0;
		tr.read_addr = 'x;
		tr.write_addr = 2;
		tr.write_data = 20;
		tr_queue.push_back(tr);
		$display("-> Transaction # %0d pushed to queue", cnt);
		cnt++;
		// reading from URA 0
		tr = new();
		tr.rst = 0;
		tr.write_en = 0;
		tr.read_en = 1;
		tr.read_addr = 2;
		tr.write_addr = 'x;
		tr.write_data = 'x;
		tr_queue.push_back(tr);
		$display("-> Transaction # %0d pushed to queue", cnt);
		cnt++;
	endtask
endclass


//////////////////////////////////////////////////////////////////////////////////
// TESTBENCH
//////////////////////////////////////////////////////////////////////////////////
module testbench;
	logic clk = 0;
	// free running clock:
	always #10 clk = ~clk;

	// Interface - test/DUT - cominucation:
	ura_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) infc ();

	assign infc.clk = clk;
	universal_reg_array #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) DUT (
			.clk(infc.clk),
			.rst(infc.rst),
			.read_addr(infc.read_addr),
			.write_addr(infc.write_addr),
			.write_data(infc.write_data),
			.write_en(infc.write_en),
			.read_en(infc.read_en),
			.read_data(infc.read_data),
			.busy(infc.busy)
	);
	
	initial begin
		wr_rd_test wr_rd_T = new("WR + RD", infc);
		random_test random_T = new("RANDOM", infc);
		wr_rd_T.run();
		random_T.run();
		
	end
	initial begin
		#(MAX_EXEC_TIME_NS);
		$finish;
	end

	initial begin
		$dumpfile("dump.vcd");
		$dumpvars();
	end

endmodule


