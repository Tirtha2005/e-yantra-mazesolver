// MazeSolver Bot: Task 2B - UART Transmitter
/*
Instructions
-------------------
Students are not allowed to make any changes in the Module declaration.

This file is used to generate UART Tx data packet to transmit the messages based on the input data.

Recommended Quartus Version : 20.1
The submitted project file must be 20.1 compatible as the evaluation will be done on Quartus Prime Lite 20.1.

Warning: The error due to compatibility will not be entertained.
-------------------
*/

/*
Module UART Transmitter

Input:  clk_3125 - 3125 KHz clock
        parity_type - even(0)/odd(1) parity type
        tx_start - signal to start the communication.
        data    - 8-bit data line to transmit

Output: tx      - UART Transmission Line
        tx_done - message transmitted flag


        Baudrate : 115200 bps
*/

// module declaration
module uart_tx(
    input clk_3125,
    input parity_type,tx_start,
    input [7:0] data,
    output reg tx, tx_done
);

initial begin
    tx = 1'b1;
    tx_done = 1'b0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////
 // Local parameters for FSM states and timing configuration
localparam IDLE_STATE    = 3'b000;
localparam START_STATE   = 3'b001;
localparam DATA_STATE    = 3'b010;
localparam PARITY_STATE  = 3'b011;
localparam STOP_STATE    = 3'b100;

localparam BIT_TIME = 27;   // Duration of one UART bit period


// Internal registers

reg [2:0]  current_state = IDLE_STATE;  // FSM current state
reg [4:0]  clock_count = 0;             // Counter for bit timing
reg [2:0]  data_bit_count = 0;          // Bit counter for transmitted data
reg [8:0]  shift_reg;                   // Register storing data and parity bit
reg        parity_bit;                  // Calculated parity bit


// Combinational Block: Calculate parity and load buffer
// Even parity → XOR of data bits; Odd parity → Invert XOR
always @(*) begin
    parity_bit = (parity_type == 1'b0) ? (^data) : (~^data);
    shift_reg  = {data, parity_bit}; // Append parity bit at LSB position
end


// Sequential Block: Main FSM controlling UART transmission
always @(posedge clk_3125) begin
    
    // Default behavior: Transmission not yet completed
    tx_done <= 1'b0;

    case (current_state)

        // IDLE STATE: Wait until tx_start signal goes high
        IDLE_STATE: begin
            clock_count <= 0;
            data_bit_count <= 0;
            tx <= 1'b1; // UART line idle (logic high)

            if (tx_start) begin
                current_state <= START_STATE;
                tx <= 1'b0; // Start bit (logic low)
            end
        end

        // START STATE: Transmit start bit for one bit duration
        START_STATE: begin
            if (clock_count < BIT_TIME - 1)
                clock_count <= clock_count + 1;
            else begin
                clock_count <= 0;
                current_state <= DATA_STATE;
                tx <= shift_reg[8]; // Send MSB first
            end
        end

        // DATA STATE: Send all 8 data bits sequentially
        DATA_STATE: begin
            if (clock_count < BIT_TIME - 1)
                clock_count <= clock_count + 1;
            else begin
                clock_count <= 0;

                if (data_bit_count < 7) begin
                    data_bit_count <= data_bit_count + 1;
                    tx <= shift_reg[8 - (data_bit_count + 1)];
                end else begin
                    data_bit_count <= 0;
                    current_state <= PARITY_STATE;
                    tx <= shift_reg[0]; // Send parity bit
                end
            end
        end

        // PARITY STATE: Send the calculated parity bit
       
        PARITY_STATE: begin
            if (clock_count < BIT_TIME - 1)
                clock_count <= clock_count + 1;
            else begin
                clock_count <= 0;
                current_state <= STOP_STATE;
                tx <= 1'b1; // Stop bit
            end
        end

        // STOP STATE: Send stop bit and finish transmission
        STOP_STATE: begin
            if (clock_count < BIT_TIME - 2)
                clock_count <= clock_count + 1;
            else begin
                clock_count <= 0;
                current_state <= IDLE_STATE;
                tx <= 1'b1;
                tx_done <= 1'b1; // Transmission completed flag
            end
        end

        // DEFAULT CASE: Reset FSM to IDLE

        default: begin
            current_state <= IDLE_STATE;
            tx <= 1'b1;
        end
    endcase
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////

endmodule





