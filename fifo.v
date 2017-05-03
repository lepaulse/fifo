module fifo #(parameter 
                BUFFER_SIZE = 127,
                DATA_WIDTH = 32
             )
    (
    // Data in interface
    input wire rst_in_n,
    input wire clock_in,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire data_in_valid,
    output reg data_in_full,

    // Data out interface
    input wire rst_out_n,
    input wire clock_out,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg data_out_valid,
    input wire data_out_ack
    );

endmodule