module t2a_dht(
    input clk_50M,
    input reset,
    inout sensor,
    output reg [7:0] T_integral,
    output reg [7:0] RH_integral,
    output reg [7:0] T_decimal,
    output reg [7:0] RH_decimal,
    output reg [7:0] Checksum,
    output reg data_valid
);

    initial begin
        T_integral = 0;
        RH_integral = 0;
        T_decimal = 0;
        RH_decimal = 0;
        Checksum = 0;
        data_valid = 0;
    end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

reg io_ctrl_dir;          // Direction control for the sensor pin (drive vs high-impedance)
reg io_output_sig;        // Value driven onto the sensor pin when driving
reg [5:0] bit_ptr;        // Bit pointer/index for reading 40 bits from sensor
assign sensor = (io_ctrl_dir) ? io_output_sig : 1'bz;  // Tri-state sensor line
wire io_input_sig = sensor;                           // Input signal from sensor when not driving

// FSM states for the communication protocol with DHT sensor
parameter IDLE_LOW   = 4'b0000,  // Generating the initial low start signal
          IDLE_HIGH  = 4'b0001,  // Pulled high after start low, waiting for sensor response
          RESP_LOW   = 4'b0010,  // Sensor drives low in response phase
          RESP_HIGH  = 4'b0011,  // Sensor drives high in response phase
          BIT_LOW    = 4'b0100,  // Start of each bit: sensor pulls low
          BIT_HIGH   = 4'b0101,  // Sensor pulls high, length determines bit value
          VERIFY_SUM = 4'b0110,  // Checksum verification state
          SEND_OUT   = 4'b0111;  // Assign output registers and reset to idle

// Timing threshold parameters based on 50 MHz clock
parameter THR_LOW_START     = 899990; // Duration to hold start low
parameter THR_HIGH_START    = 1990;   // Duration of high after start low
parameter THR_LOW_RESP      = 3990;   // Duration of response low from sensor
parameter THR_HIGH_RESP     = 3990;   // Duration of response high from sensor
parameter THR_LOW_BIT       = 2490;   // Duration of bit low pulse
parameter THR_HIGH_ONE      = 2390;   // Threshold for high pulse representing ‘1’
parameter THR_HIGH_ZERO     = 1290;   // Threshold for high pulse representing ‘0’

reg [3:0]  fsm_state     = 0;         // Current state of FSM
reg [39:0] read_store     = 0;        // Buffer to accumulate the 40 data bits
reg [31:0] time_count     = 0;        // Counter for measuring pulse durations
reg        data_ok_flag   = 0;        // Flag indicating successful checksum

always @(posedge clk_50M) begin
    // Active-low reset handling
    if (!reset) begin
        fsm_state     <= IDLE_LOW;
        io_output_sig <= 1'b0;
        T_integral    <= 0;
        RH_integral   <= 0;
        T_decimal     <= 0;
        RH_decimal    <= 0;
        Checksum      <= 0;
        data_ok_flag  <= 0;
        time_count    <= 0;
        io_ctrl_dir   <= 0;
        bit_ptr       <= 0;
    end
    else begin
        case (fsm_state)

        // Start sequence: drive sensor line low for start signal
        IDLE_LOW: begin
            io_ctrl_dir   <= 1'b1;
            io_output_sig <= 1'b0;
            time_count    <= time_count + 1;
            data_ok_flag  <= 0;

            if (time_count >= THR_LOW_START) begin
                fsm_state     <= IDLE_HIGH;
                io_output_sig <= 1'b1;
                time_count    <= 0;
                io_ctrl_dir   <= 1'b1;
            end
        end

        // Release the line (drive high) and wait for sensor to respond
        IDLE_HIGH: begin
            time_count <= time_count + 1;
            if (time_count >= THR_HIGH_START) begin
                fsm_state   <= RESP_LOW;
                time_count  <= 0;
                io_ctrl_dir <= 0;  // sensor now drives the line
            end
        end

        // Sensor response low pulse: detecting sensor's acknowledgment
        RESP_LOW: begin
            if (io_input_sig == 0) begin
                time_count <= time_count + 1;
                if (time_count >= THR_LOW_RESP) begin
                    fsm_state  <= RESP_HIGH;
                    time_count <= 0;
                end
            end
        end

        // Sensor response high pulse: further acknowledgment stage
        RESP_HIGH: begin
            if (io_input_sig == 1) begin
                time_count <= time_count + 1;
                if (time_count >= THR_HIGH_RESP) begin
                    fsm_state  <= BIT_LOW;
                    time_count <= 0;
                    bit_ptr    <= 0;   // initialize bit pointer
                end
            end
        end

        // Bit transmission low phase: waiting for sensor to drive line low before value
        BIT_LOW: begin
            if (bit_ptr >= 40) begin
                fsm_state  <= VERIFY_SUM;
                time_count <= 0;
            end
            else if (io_input_sig == 0) begin
                time_count <= time_count + 1;
                if (time_count >= THR_LOW_BIT) begin
                    fsm_state  <= BIT_HIGH;
                    time_count <= 0;
                end
            end
        end

        // Bit transmission high phase: measure how long the line stays high to determine bit value
        BIT_HIGH: begin
            if (io_input_sig == 1) begin
                time_count <= time_count + 1;
            end
            else begin
                if (bit_ptr <= 40) begin
                    if (time_count >= THR_HIGH_ONE) begin
                        // Received bit = 1
                        read_store[39 - bit_ptr] <= 1'b1;
                        bit_ptr    <= bit_ptr + 1;
                        time_count <= 0;
                        fsm_state  <= BIT_LOW;
                    end
                    else if (time_count >= THR_HIGH_ZERO && time_count <= THR_HIGH_ONE) begin
                        // Received bit = 0
                        read_store[39 - bit_ptr] <= 1'b0;
                        bit_ptr    <= bit_ptr + 1;
                        time_count <= 0;
                        fsm_state  <= BIT_LOW;
                    end
                end
            end
        end

        // Verify the checksum: sum of first four bytes must equal the fifth
        VERIFY_SUM: begin
            if (read_store[7:0] == (read_store[15:8] + read_store[23:16] + read_store[31:24] + read_store[39:32])) begin
                data_ok_flag <= 1'b1;
                fsm_state    <= SEND_OUT;
            end
            else begin
                data_ok_flag <= 1'b0;
                fsm_state    <= SEND_OUT;
            end
        end

        // Output the captured data into the registers and restart FSM
        SEND_OUT: begin
            T_integral  <= read_store[23:16];
            RH_integral <= read_store[39:32];
            T_decimal   <= read_store[15:8];
            RH_decimal  <= read_store[31:24];
            Checksum    <= read_store[7:0];
            fsm_state   <= IDLE_LOW;
            data_ok_flag <= 0;
        end

        // Default safe fallback: reset everything and go to IDLE_LOW
        default: begin
            fsm_state   <= IDLE_LOW;
            T_integral  <= 0;
            RH_integral <= 0;
            T_decimal   <= 0;
            RH_decimal  <= 0;
            Checksum    <= 0;
            data_ok_flag <= 0;
        end

        endcase
    end
end

// Propagate internal validity flag to the output register synchronously
always @(posedge clk_50M) begin
    data_valid <= data_ok_flag;
end
////////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule