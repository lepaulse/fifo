`timescale 1ns/1ps

module fifo_tb;
parameter BUFFER_SIZE = 4;//128;
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

reg [31:0] COMPARE[0:255]; 
reg [7:0] in_index, out_index;

initial begin // data in
    in_index = 8'b00000000;
    clock_in = 1'b0;
    rst_in_n = 1'b0;
    data_in_valid = 1'b0;
    data_in = 32'h00000000;
    #5;
    //clock_in = 1'b1;
    rst_in_n = 1'b1;
    data_in_valid = 1'b1;   
    //#5;
    repeat (100) begin
        if(!data_in_full) begin
            if(clock_in) begin // change data on negedge
                // if(data_in != 0) begin
                    data_in = (data_in) + 1;
                    COMPARE[in_index] <= (data_in);
                    in_index <= in_index + 1;  
                // end
                // else begin
                //     data_in <= 1'b1;
                //     COMPARE[in_index] <= 32'h00000001;
                // end
            end
            else begin  
            end
        end
        clock_in = ~clock_in;
        #5;
    end
end

initial begin // data out
    out_index = 8'b00000000;
    clock_out = 1'b0;
    rst_out_n = 1'b0;
    data_out_ack = 1'b0;
    #5;
    rst_out_n = 1'b1;
    data_out_ack = 1'b1;
    #220;
    clock_out = 1'b1;


    repeat (360) begin
        #5;
        if (data_out_valid) begin
            if(clock_out) begin
                if (data_out == COMPARE[out_index]) begin
                    $monitor("data match");
                end
                else begin
                    $monitor("data missmatch: out_index: %d: %d != %d",out_index, COMPARE[out_index], data_out);      
                end 
            end
            else begin
                out_index = out_index + 1;
            end
        end
        clock_out = ~clock_out;
    end
end




endmodule