
`timescale 1ns/1ps

module fifo_tb;
parameter BUFFER_SIZE = 127;
parameter DATA_WIDTH = 32;

    // Data in interface
    reg rst_in_n;
    reg clock_in;
    reg [DATA_WIDTH-1:0] data_in;
    reg data_in_valid;
    wire data_in_full;

    // Data out interface
    reg rst_out_n;
    reg clock_out;
    wire [DATA_WIDTH-1:0] data_out;
    wire data_out_valid;
    reg data_out_ack;

    reg [32-1:0] CheckData[64-1:0]; 
    reg [6-1:0] index;
 
fifo dut(.rst_in_n(rst_in_n),
         .clock_in(clock_in),
         .data_in(data_in),
         .data_in_valid(data_in_valid),
         .data_in_full(data_in_full),
         .rst_out_n(rst_out_n),
         .clock_out(clock_out),
         .data_out(data_out),
         .data_out_valid(data_out_valid),
         .data_out_ack(data_out_ack)
        );

initial begin // data in
    clock_in = 1'b0;
    rst_in_n = 1'b0;
    data_in = 32'h00000001;
    #5;
    clock_in = 1'b1;
    rst_in_n = 1'b1;
    repeat (16) begin
        #5;
        clock_in = ~clock_in;
        data_in = (data_in) * 2;
        data_in_valid = 1'b1;
    end
end

initial begin // data out
    clock_out = 1'b0;
    rst_out_n = 1'b0;
    data_in = 32'h00000001;
    #15;
    clock_out = 1'b1;
    rst_out_n = 1'b1;
    repeat (16) begin
        #5;
        clock_out = ~clock_out;
        //data_out_valid = 1'b1;
        data_out_ack = 1'b1;
    end
end


endmodule