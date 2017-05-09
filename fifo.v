// **************************************************************************************
// Asynchronous fifo    
// 08.05.17                
// Norwegian University of Science and Technology              
// Lars Erik Songe Paulsen             
// **************************************************************************************

// **************************************************************************************
// TODO LIST:    
// **************************************************************************************
// No "almost full" or "almost empty" signaling logic implemented            
// **************************************************************************************
`timescale 1ns/1ps

module fifo #(parameter 
                BUFFER_SIZE = 128,                
                DATA_WIDTH = 32,    
                ADDRESS_WIDTH = clogb2(BUFFER_SIZE) - 1
             )
    (
    // ----------------------------------------------------------------------------------
    // Data in interface
    // ----------------------------------------------------------------------------------
    input  wire rst_in_n,
    input  wire clock_in,
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire data_in_valid,
    output reg  data_in_full,

    // ----------------------------------------------------------------------------------
    // Data out interface
    // ----------------------------------------------------------------------------------
    input  wire rst_out_n,
    input  wire clock_out,
    output wire [DATA_WIDTH-1:0] data_out,
    output reg  data_out_valid,
    input  wire data_out_ack
    );

    // ----------------------------------------------------------------------------------
    // Functions
    // ----------------------------------------------------------------------------------
    // ceil log_2
    function integer clogb2;
        input integer depth;
              for (clogb2=0; depth>0; clogb2=clogb2+1)
                    depth = depth >> 1;
    endfunction

    // ----------------------------------------------------------------------------------
    // Memory interface and logic
    // Low latency version(no output register)
    // See XilinxSimpleDualPort1ClockBlockRamExample.v for detailed documentation
    // ----------------------------------------------------------------------------------
    /* FROM VHDL EXAMPLE:
    -- Note :
    -- If the chosen width and depth values are low, Synthesis will infer Distributed RAM.
    -- C_RAM_DEPTH should be a power of 2
    TODO: Check if applicable for verilog version*/ 
    reg [DATA_WIDTH-1:0] Buffer[BUFFER_SIZE-1:0];

    // Initialize memory values to all zeros
    generate 
        integer ram_index;
        initial
            for(ram_index = 0; ram_index < BUFFER_SIZE; ram_index = ram_index + 1)
                Buffer[ram_index] = {DATA_WIDTH{1'b0}};
    endgenerate

    // Conditional sampling of data_in
    always @(posedge clock_in) begin
        if (data_in_valid && !data_in_full)
            Buffer[BufferWriteAddress] <= data_in;
    end

    // data_out must only be sampled when data_out_valid is asserted
    assign data_out = Buffer[BufferReadAddress];

    // MSB used for checking fifo full condition
    // Remainder is actuall Buffer address
    reg  [ADDRESS_WIDTH:0]   ExtendedBufferWriteAddress, ExtendedBufferReadAddress; 

    // Used for addressing memory
    wire [ADDRESS_WIDTH-1:0] BufferWriteAddress, BufferReadAddress;       

    // Binary coded (ADDRESS_WIDTH) bit memory next address
    wire [ADDRESS_WIDTH:0]   WriteNextAddress, ReadNextAddress; 

    // Gray coded Pointers for generating full/empty signals
    reg  [ADDRESS_WIDTH:0]   WriteGrayPointer, ReadGrayPointer;

    // Gray coded Next Pointers for syncronizing across clock domains
    wire [ADDRESS_WIDTH:0]   WriteGrayNextPointer, ReadGrayNextPointer;

    // Gray coded pointers for synchronizing accross clock domains
    // 2 registers used to avoid metastability
    reg [ADDRESS_WIDTH:0]    WriteGrayPointer2Read1, ReadGrayPointer2Write1;
    reg [ADDRESS_WIDTH:0]    WriteGrayPointer2Read2, ReadGrayPointer2Write2;

    // Wires to signal fifo status
    wire DataInFull, DataOutEmpty;

    // ----------------------------------------------------------------------------------
    // Write side logic
    // ----------------------------------------------------------------------------------
    // Check full condition
    assign DataInFull           = (WriteGrayNextPointer ==
                                 {~ReadGrayPointer2Write2[ADDRESS_WIDTH:ADDRESS_WIDTH-1],
                                   ReadGrayPointer2Write2[ADDRESS_WIDTH-2:0]});
    // Remove MSB before memory indexing
    assign BufferWriteAddress   = ExtendedBufferWriteAddress[ADDRESS_WIDTH-1:0];
    // Increase Write address if conditions are met
    assign WriteNextAddress     = ExtendedBufferWriteAddress + 
                                 (data_in_valid & ~data_in_full);
    // Binary to Gray code conversion
    assign WriteGrayNextPointer = (WriteNextAddress>>1) ^ WriteNextAddress;

    always @(posedge clock_in or negedge rst_in_n) begin
        if (!rst_in_n) begin
            data_in_full               <= 0;
            ExtendedBufferWriteAddress <= 0;
            WriteGrayPointer           <= 0;
            WriteGrayPointer2Read1     <= 0;
            WriteGrayPointer2Read2     <= 0;
        end
        else begin
            // Update data in full register
            data_in_full               <= DataInFull;
            // Update Write adress register
            ExtendedBufferWriteAddress <= WriteNextAddress;
            // Update current Gray code writepointer
            WriteGrayPointer           <= WriteGrayNextPointer;
            // Send previous Gray code writepointer to Read side logic
            WriteGrayPointer2Read1     <= WriteGrayPointer;
            WriteGrayPointer2Read2     <= WriteGrayPointer2Read1;
        end
    end

    // ----------------------------------------------------------------------------------
    // Read side logic
    // ----------------------------------------------------------------------------------
    // Check empty condition
    assign DataOutEmpty        = (ReadGrayNextPointer==WriteGrayPointer2Read2);
    // Remove MSB before memory indexing
    assign BufferReadAddress   = ExtendedBufferReadAddress[ADDRESS_WIDTH-1:0];
    // Increase Read address if conditions are met
    assign ReadNextAddress     = ExtendedBufferReadAddress + (data_out_ack & data_out_valid);
    // Binary to Gray code conversion
    assign ReadGrayNextPointer = (ReadNextAddress>>1) ^ ReadNextAddress;

    always @(posedge clock_out or negedge rst_out_n) begin
        if (!rst_out_n) begin
            data_out_valid            <= 0;
            ExtendedBufferReadAddress <= 0;
            ReadGrayPointer           <= 0;
            ReadGrayPointer2Write1    <= 0;
            ReadGrayPointer2Write2    <= 0;
        end
        else begin
            // Update data out valid register
            data_out_valid            <= !DataOutEmpty;
            // Update Read adress register
            ExtendedBufferReadAddress <= ReadNextAddress;
            // Update current Gray code readpointer
            ReadGrayPointer           <= ReadGrayNextPointer;
            // Send previous Gray code readpointer to Write side logic
            ReadGrayPointer2Write1    <= ReadGrayPointer;
            ReadGrayPointer2Write2    <= ReadGrayPointer2Write1;
        end
    end
endmodule