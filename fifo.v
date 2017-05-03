module fifo #(parameter 
                BUFFER_SIZE = 127, // From 1 to 127 values
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

    reg [DATA_WIDTH-1:0] Buffer[BUFFER_SIZE-1:0];

    // Data in logic
    always @(posedge clock_in or negedge rst_in_n) begin
        if (rst_in_n) begin
            // reset
            
        end
        else if (data_in_valid) begin
            
        end
    end

    // Data out logic
    always @(posedge clock_out or negedge rst_out_n) begin
        if (rst_out_n) begin
            // reset
            
        end
        else if (data_out_valid) begin
            
        end
    end

endmodule