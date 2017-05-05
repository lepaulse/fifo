`timescale 1ns/1ps

// ********************************************************************************
// Asynchronous fifo    
// TODO: last edit date                 
// Norwegian University of Science and Technology              
// Lars Erik Songe Paulsen             
// ********************************************************************************

// ********************************************************************************
// TODO LIST:    
// ********************************************************************************
//             
// ********************************************************************************

module fifo #(parameter 
                BUFFER_SIZE = 16, //Integers in range 1 to 128(divisible by 2)  
                DATA_WIDTH = 32,
                ADDRESS_WIDTH = clogb2(BUFFER_SIZE) - 1
             )
    (

    // ---------------------------------------------------------------------------
    // Data in interface
    // ---------------------------------------------------------------------------
    input wire rst_in_n,
    input wire clock_in,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire data_in_valid,
    output reg data_in_full,

    // ---------------------------------------------------------------------------
    // Data out interface
    // ---------------------------------------------------------------------------
    input wire rst_out_n,
    input wire clock_out,
    output wire [DATA_WIDTH-1:0] data_out,
    output reg data_out_valid,
    input wire data_out_ack
    );

    // ---------------------------------------------------------------------------
    // Functions
    // ---------------------------------------------------------------------------
    function integer clogb2;
        input integer depth;
              for (clogb2=0; depth>0; clogb2=clogb2+1)
                    depth = depth >> 1;
    endfunction

    // ---------------------------------------------------------------------------
    // Memory interface
    // Low latency version(no output register)
    // See XilinxSimpleDualPort1ClockBlockRamExample.v for detailed documentation
    // ---------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] Buffer[BUFFER_SIZE-1:0];

    // Initialize memory values to all zeros
    generate 
        integer ram_index;
        initial
            for (ram_index = 0; ram_index < BUFFER_SIZE; ram_index = ram_index + 1)
                Buffer[ram_index] = {DATA_WIDTH{1'b0}};
    endgenerate

    // Conditional sampling of data_in
    always @(posedge clock_in) begin
        if (data_in_valid && !data_in_full)
            Buffer[BWriteAddress] <= data_in;
    end

    // data_out must only be sampled when data_out_valid is asserted.
    assign data_out = Buffer[BReadAddress];






    wire [ADDRESS_WIDTH-1:0] BWriteAddress, BReadAddress;         // Binary memory address 

    // MSB used for checking fifo full condition
    reg [ADDRESS_WIDTH:0] WriteAddress, ReadAddress;         // Binary memory next address 
    wire [ADDRESS_WIDTH:0] WriteNextAddress, ReadNextAddress;         // Binary memory next address 
    wire [ADDRESS_WIDTH:0] WriteGrayNextPointer, ReadGrayNextPointer;
    reg [ADDRESS_WIDTH:0] WritePointer, ReadPointer;            /* Gray coded Pointers for 
                                                                   syncronizing across clock 
                                                                   domains */
    reg [ADDRESS_WIDTH:0] WritePointer2Read1, ReadPointer2Write1; // 
    reg [ADDRESS_WIDTH:0] WritePointer2Read2, ReadPointer2Write2; // 


    wire DataInFull;
    wire DataOutEmpty;
    //assign data_in_full = DataInFull;



    // Sync Read to Write
    always @(posedge clock_out or negedge rst_out_n) begin
        if (!rst_out_n) begin
            ReadPointer2Write1 <= 0;
            ReadPointer2Write2 <= 0;
        end
        else begin
            ReadPointer2Write1 <= ReadPointer;
            ReadPointer2Write2 <= ReadPointer2Write1;
        end
    end

    // Sync Write to Read
    always @(posedge clock_in or negedge rst_in_n) begin
        if (!rst_in_n) begin
            WritePointer2Read1 <= 0;
            WritePointer2Read2 <= 0;
        end
        else begin
            WritePointer2Read1 <= WritePointer;
            WritePointer2Read2 <= WritePointer2Read1;
        end
    end



    // Update Write adress to 
    always @(posedge clock_in or negedge rst_in_n) begin
        if (!rst_in_n) begin
            WriteAddress <= 0;
            WritePointer <= 0;
        end
        else begin
            WriteAddress <= WriteNextAddress;
            WritePointer <= WriteGrayNextPointer;
        end
    end

    // Address memory and check empty
    assign BWriteAddress = WriteAddress[ADDRESS_WIDTH-1:0];
    // NextAddress
    assign WriteNextAddress = WriteAddress + (data_in_valid & ~data_in_full);
    // Binary to Gray code conversion
    assign WriteGrayNextPointer = (WriteNextAddress>>1) ^ WriteNextAddress;
    // Check full condition
    assign DataInFull = (WriteGrayNextPointer=={~ReadPointer2Write2[ADDRESS_WIDTH:ADDRESS_WIDTH-1],ReadPointer2Write2[ADDRESS_WIDTH-2:0]});
    always @(posedge clock_in or negedge rst_in_n) begin
        if (!rst_in_n) begin
            data_in_full <= 1'b0;
        end
        else begin
            data_in_full <= DataInFull;
        end
    end

        // Update Read adress to 
    always @(posedge clock_out or negedge rst_out_n) begin
        if (!rst_out_n) begin
            ReadAddress <= 0;
            ReadPointer <= 0;
        end
        else begin
            ReadAddress <= ReadNextAddress;
            ReadPointer <= ReadGrayNextPointer;
        end
    end

    // Address memory and check empty
    assign BReadAddress = ReadAddress[ADDRESS_WIDTH-1:0];
    // NextAddress
    assign ReadNextAddress = ReadAddress + (data_out_ack & data_out_valid);
    // Binary to Gray code conversion
    assign ReadGrayNextPointer = (ReadNextAddress>>1) ^ ReadNextAddress;
    // Check full condition
    assign DataOutEmpty = (ReadGrayNextPointer==WritePointer2Read2);
    always @(posedge clock_out or negedge rst_out_n) begin
        if (!rst_out_n) begin
            data_out_valid <= 1'b0;
        end
        else begin
            data_out_valid <= !DataOutEmpty;
        end
    end



endmodule