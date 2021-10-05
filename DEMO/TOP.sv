//
// KFSDRAM DEMO
//
// Written by kitune-san
//
module TOP #(
    parameter sdram_col_width       = 10,
    parameter sdram_row_width       = 13,
    parameter sdram_bank_width      = 2,
    parameter sdram_data_width      = 16
) (
    input   logic           CLK,

    // SDRAM
    output  logic                               sdram_clock,
    output  logic   [sdram_row_width-1:0]       sdram_address,
    output  logic                               sdram_cke,
    output  logic                               sdram_cs,
    output  logic                               sdram_ras,
    output  logic                               sdram_cas,
    output  logic                               sdram_we,
    output  logic   [sdram_bank_width-1:0]      sdram_ba,
    inout   logic   [sdram_data_width-1:0]      sdram_dq,

    output  logic                               sdram_ldqm,
    output  logic                               sdram_udqm,

    // Display
    output  logic   [6:0]   HEX0,
    output  logic   [6:0]   HEX1,
    output  logic   [6:0]   HEX2,
    output  logic   [6:0]   HEX3,
    output  logic   [6:0]   HEX4,
    output  logic   [6:0]   HEX5
);

    logic   reset;

    //
    // PLL
    //
    PLL PLL (
        .refclk     (CLK),
        .rst        (1'b0),
        .outclk_0   (sdram_clock),  // 100MHz
    );

    //
    // Power On Reset
    //
    `define POR_MAX 16'hffff
    logic   [15:0]  por_count;

    always_ff @(posedge CLK)
    begin
        if (por_count != `POR_MAX) begin
            reset <= 1'b1;
            por_count <= por_count + 16'h0001;
        end
        else begin
            reset <= 1'b0;
            por_count <= por_count;
        end
    end

    //
    // Install SDRAM
    //
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
    logic   [sdram_data_width-1:0]      sdram_dq_in;
    logic   [sdram_data_width-1:0]      sdram_dq_out;
    logic                               sdram_dq_io;

    KFSDRAM KFSDRAM (
        .sdram_clock        (sdram_clock),
        .sdram_reset        (reset),
        .address            (address),
        .access_num         (access_num),
        .data_in            (data_in),
        .data_out           (data_out),
        .write_request      (write_request),
        .read_request       (read_request),
        .write_flag         (write_flag),
        .read_flag          (read_flag),
        .idle               (idle),
        .sdram_address      (sdram_address),
        .sdram_cke          (sdram_cke),
        .sdram_cs           (sdram_cs),
        .sdram_ras          (sdram_ras),
        .sdram_cas          (sdram_cas),
        .sdram_we           (sdram_we),
        .sdram_ba           (sdram_ba),
        .sdram_dq_in        (sdram_dq_in),
        .sdram_dq_out       (sdram_dq_out),
        .sdram_dq_io        (sdram_dq_io)
    );

    defparam KFSDRAM.sdram_col_width    = sdram_col_width;
    defparam KFSDRAM.sdram_row_width    = sdram_row_width;
    defparam KFSDRAM.sdram_bank_width   = sdram_bank_width;
    defparam KFSDRAM.sdram_data_width   = sdram_data_width;
    defparam KFSDRAM.sdram_no_refresh   = 1'b0;

    assign  sdram_dq    = (sdram_dq_io) ? 16'hzzzz : sdram_dq_out;
    assign  sdram_dq_in = sdram_dq;

    assign  sdram_ldqm  = 1'b0;
    assign  sdram_udqm  = 1'b0;

    //
    // Read/Write Test
    //
    `define CHECK_START_ADDRESS 25'b01_0000000000001_0000000000;

    logic   [15:0]  control_state;
    logic   [1:0]   access_count;
    logic   [15:0]  write_data[3] = '{ 16'h00AB, 16'h00CD, 16'h00EF };

    always_ff @(posedge sdram_clock, posedge reset) begin
        if (reset) begin
            address         <= `CHECK_START_ADDRESS;
            access_num      <= 10'h000;
            data_in         <= 16'h0000;
            write_request   <= 1'b0;
            read_request    <= 1'b0;
            access_count    <= 2'h0;
            control_state   <= 16'h0000;
        end
        else begin
            casez (control_state)
                // Write Ooeration
                16'h0000: begin
                    address         <= address;
                    access_num      <= 10'h001;
                    data_in         <= write_data[access_count];
                    write_request   <= 1'b1;
                    read_request    <= 1'b0;
                    access_count    <= access_count;
                    control_state   <= (write_flag) ? (control_state + 16'h0001) : control_state;
                end
                16'h0001: begin
                    address         <= address;
                    access_num      <= 10'h001;
                    data_in         <= write_data[access_count];
                    write_request   <= 1'b0;
                    read_request    <= 1'b0;
                    access_count    <= access_count;
                    control_state   <= (~write_flag) ? (control_state + 16'h0001) : control_state;
                end
                16'h0002: begin
                    address         <= (access_count != 2'b11) ? address + 1        : `CHECK_START_ADDRESS;
                    access_num      <= 10'h000;
                    data_in         <= write_data[access_count];
                    write_request   <= 1'b0;
                    read_request    <= 1'b0;
                    access_count    <= (access_count != 2'b11) ? (access_count + 1) : 2'b00;
                    control_state   <= (access_count != 2'b11) ? 16'h0000           : (control_state + 16'h0001);
                end
                // Read Operation
                16'h0003: begin
                    address         <= address;
                    access_num      <= 10'h001;
                    data_in         <= 16'h0000;
                    write_request   <= 1'b0;
                    read_request    <= 1'b1;
                    access_count    <= access_count;
                    control_state   <= (read_flag) ? (control_state + 16'h0001) : control_state;
                end
                16'h0004: begin
                    address         <= address;
                    access_num      <= 10'h001;
                    data_in         <= 16'h0000;
                    write_request   <= 1'b0;
                    read_request    <= 1'b0;
                    access_count    <= access_count;
                    control_state   <= (~read_flag) ? (control_state + 16'h0001) : control_state;
                end
                16'h0005: begin
                    address         <= (access_count != 2'b11) ? address + 1        : `CHECK_START_ADDRESS;
                    access_num      <= 10'h000;
                    data_in         <= 16'h0000;
                    write_request   <= 1'b0;
                    read_request    <= 1'b0;
                    access_count    <= (access_count != 2'b11) ? (access_count + 1) : 2'b00;
                    control_state   <= 16'h0003;
                end
                default: begin
                    address         <= `CHECK_START_ADDRESS;
                    access_num      <= 10'h000;
                    data_in         <= 16'h0000;
                    write_request   <= 1'b0;
                    read_request    <= 1'b0;
                    access_count    <= 16'h0000;
                    control_state   <= 16'h0000;
                end
            endcase
        end
    end

    logic   [15:0]  read_buffer[4];
    logic   [1:0]   bit_select[4] = '{ 2'b00, 2'b01, 2'b10, 2'b11 };

    genvar i;
    generate
    for (i = 0; i < 4; i = i + 1) begin : BUFFER
        always_ff @(posedge sdram_clock, posedge reset) begin
            if (reset)
                read_buffer[i]  <= 16'hFFFF;
            else if ((read_flag) && (bit_select[i] == access_count))
                read_buffer[i]  <= data_out;
            else
                read_buffer[i]  <= read_buffer[i];
        end
    end
    endgenerate

    //
    // Display
    //
    function [6:0] CONV7SEG (input logic [3:0] data);
    begin
        case (data)
            4'h0:    CONV7SEG = 7'b1000000;
            4'h1:    CONV7SEG = 7'b1111001;
            4'h2:    CONV7SEG = 7'b0100100;
            4'h3:    CONV7SEG = 7'b0110000;
            4'h4:    CONV7SEG = 7'b0011001;
            4'h5:    CONV7SEG = 7'b0010010;
            4'h6:    CONV7SEG = 7'b0000010;
            4'h7:    CONV7SEG = 7'b1011000;
            4'h8:    CONV7SEG = 7'b0000000;
            4'h9:    CONV7SEG = 7'b0010000;
            4'ha:    CONV7SEG = 7'b0001000;
            4'hb:    CONV7SEG = 7'b0000011;
            4'hc:    CONV7SEG = 7'b1000110;
            4'hd:    CONV7SEG = 7'b0100001;
            4'he:    CONV7SEG = 7'b0000110;
            4'hf:    CONV7SEG = 7'b0001110;
            default: CONV7SEG = 7'b1111111;
        endcase
    end
    endfunction

    assign HEX0 = CONV7SEG(read_buffer[2][3:0]);
    assign HEX1 = CONV7SEG(read_buffer[2][7:4]);
    assign HEX2 = CONV7SEG(read_buffer[1][3:0]);
    assign HEX3 = CONV7SEG(read_buffer[1][7:4]);
    assign HEX4 = CONV7SEG(read_buffer[0][3:0]);
    assign HEX5 = CONV7SEG(read_buffer[0][7:4]);

endmodule

