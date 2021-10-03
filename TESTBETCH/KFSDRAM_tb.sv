
`define TB_CYCLE        20
`define TB_FINISH_COUNT 20000

module KFSDRAM_tm();

    timeunit        1ns;
    timeprecision   10ps;

    //
    // Generate wave file to check
    //
`ifdef IVERILOG
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
    end
`endif

    //
    // Generate clock
    //
    logic   clock;
    initial clock = 1'b0;
    always #(`TB_CYCLE / 2) clock = ~clock;

    //
    // Generate reset
    //
    logic reset;
    initial begin
        reset = 1'b1;
            # (`TB_CYCLE * 10)
        reset = 1'b0;
    end

    //
    // Cycle counter
    //
    logic   [31:0]  tb_cycle_counter;
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            tb_cycle_counter <= 32'h0;
        else
            tb_cycle_counter <= tb_cycle_counter + 32'h1;
    end

    always_comb begin
        if (tb_cycle_counter == `TB_FINISH_COUNT) begin
            $display("***** SIMULATION TIMEOUT ***** at %d", tb_cycle_counter);
`ifdef IVERILOG
            $finish;
`elsif  MODELSIM
            $stop;
`else
            $finish;
`endif
        end
    end

    //
    // Module under test
    //
    parameter sdram_row_width   = 13;
    parameter sdram_col_width   = 10;
    parameter sdram_bank_width  = 2;
    parameter sdram_data_width  = 16;

    logic                               sdram_clock;
    logic                               sdram_reset;

    logic   [sdram_col_width
            + sdram_row_width
            + sdram_bank_width-1:0]     address;
    logic   [sdram_col_width-1:0]       access_num;
    logic   [sdram_data_width-1:0]      data_in;
    logic   [sdram_data_width-1:0]      data_out;
    logic                               write_request;
    logic                               read_request;
    logic                               write_flag;
    logic                               read_flag;
    logic                               idle;

    logic   [sdram_row_width-1:0]       sdram_address;
    logic                               sdram_cke;
    logic                               sdram_cs;
    logic                               sdram_ras;
    logic                               sdram_cas;
    logic                               sdram_we;
    logic   [sdram_bank_width-1:0]      sdram_ba;
    logic   [sdram_data_width-1:0]      sdram_dq_in;
    logic   [sdram_data_width-1:0]      sdram_dq_out;
    logic                               sdram_dq_io;

    assign  sdram_clock = clock;
    assign  sdram_reset = reset;

    KFSDRAM u_KFSDRAM (.*);

    defparam u_KFSDRAM.sdram_init_wait     = 16'd10;
    defparam u_KFSDRAM.sdram_refresh_cycle = 16'd20;

    //
    // Task : Initialization
    //
    task TASK_INIT();
    begin
        #(`TB_CYCLE * 0);
        address         = 25'b00_0000000000000_0000000000;
        access_num      = 10'd0000;
        data_in         = 16'h0000;
        write_request   = 1'b0;
        read_request    = 1'b0;
        #(`TB_CYCLE * 12);
    end
    endtask

    logic   dummy;

    //
    // Test pattern
    //
    initial begin
        TASK_INIT();
        dummy = 1;
        #(`TB_CYCLE * 100);
        address         = 25'b11_0000000000010_0000000001;
        access_num      = 10'd0002;
        data_in         = 16'h1234;
        write_request   = 1'b1;
        read_request    = 1'b0;
        #(`TB_CYCLE * 1);
        write_request   = 1'b0;
        #(`TB_CYCLE * 7);
        data_in         = 16'h5678;
        #(`TB_CYCLE * 20);
        address         = 25'b11_0000000000010_0000000001;
        access_num      = 10'd0002;
        data_in         = 16'h0000;
        write_request   = 1'b0;
        read_request    = 1'b1;
        #(`TB_CYCLE * 1);
        read_request    = 1'b0;
        #(`TB_CYCLE * 10);
        sdram_dq_in     = 16'hABCD;
        #(`TB_CYCLE * 1);
        sdram_dq_in     = 16'hEF01;
        #(`TB_CYCLE * 1);
        sdram_dq_in     = 16'hxxxx;
        #(`TB_CYCLE * 20);


        // End of simulation
`ifdef IVERILOG
        $finish;
`elsif  MODELSIM
        $stop;
`else
        $finish;
`endif
    end

endmodule

