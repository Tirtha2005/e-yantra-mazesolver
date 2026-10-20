module uart_rx(
    input clk_3125,
    input rx,
    output reg [7:0] rx_msg,
    output reg rx_parity,
    output reg rx_complete
    );

initial begin
    rx_msg = 8'b0;
    rx_parity = 1'b0;
    rx_complete = 1'b0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

// ----- FSM States -----
localparam [2:0] 
    S_IDLE   = 3'b000,
    S_START  = 3'b001,
    S_MSG    = 3'b010,
    S_PARITY = 3'b011,
    S_STOP   = 3'b100;

reg [2:0] state = S_IDLE;
reg [8:0] rx_buf = 9'd0;

// Use smallest counters possible
reg [4:0] clk_cnt = 5'd0;   // Counts 0–26 (needs 5 bits)
reg [3:0] bit_cnt = 4'd0;
reg [3:0] done_cnt = 4'd0;

// Constant for bit duration
localparam [4:0] BIT_DUR = 5'd27;

// Precomputed parity to reduce combinational fan-in
wire parity_calc = ^rx_buf[8:1];

always @(posedge clk_3125) begin
    case (state)
        // ---------------------------------------------------------
        S_IDLE: begin
            state <= S_START;  // Start bit detection
        end

        // ---------------------------------------------------------
        S_START: begin
            rx_complete <= 1'b0;
            bit_cnt <= 4'd0;

            if (~rx) begin
                if (clk_cnt == (BIT_DUR - 2)) begin
                    clk_cnt <= 5'd0;
                    state <= S_MSG;
                end else begin
                    clk_cnt <= clk_cnt + 1'b1;
                end
            end
        end

        // ---------------------------------------------------------
        S_MSG: begin
            if (clk_cnt == (BIT_DUR >> 1)) begin
                rx_buf[8] <= rx;
                clk_cnt <= 5'd0;
                bit_cnt <= 4'd1;
                state <= S_PARITY;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end

        // ---------------------------------------------------------
        S_PARITY: begin
            if (bit_cnt < 9) begin
                if (clk_cnt == (BIT_DUR - 1)) begin
                    rx_buf[8 - bit_cnt] <= rx;
                    bit_cnt <= bit_cnt + 1'b1;
                    clk_cnt <= 5'd0;
                end else begin
                    clk_cnt <= clk_cnt + 1'b1;
                end
            end else if (clk_cnt < (BIT_DUR >> 1)) begin
                clk_cnt <= clk_cnt + 1'b1;
            end else begin
                clk_cnt <= 5'd0;
                state <= S_STOP;
            end
        end

        // ---------------------------------------------------------
        S_STOP: begin
            if (clk_cnt == (BIT_DUR - 1)) begin
                // Check parity
                if (rx_buf[0] == parity_calc) begin
                    rx_msg <= rx_buf[8:1];
                    rx_parity <= rx_buf[0];
                end else begin
                    rx_msg <= 8'h3F;
                    rx_parity <= rx_buf[0];
                end

                // Limit rx_complete trigger to 8 times
                if (done_cnt < 8) begin
                    rx_complete <= 1'b1;
                    done_cnt <= done_cnt + 1'b1;
                end else begin
                    rx_complete <= 1'b0;
                end

                clk_cnt <= 5'd0;
                state <= S_START;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end
    endcase
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////
endmodule
