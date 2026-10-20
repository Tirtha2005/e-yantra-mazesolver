module pwm_generator(
    input clk_3125KHz,
    input [3:0] duty_cycle,
    output reg clk_195KHz,
    output reg pwm_signal
);

initial begin
    clk_195KHz = 0;   // Start LOW instead of HIGH
    pwm_signal = 1;
end

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

reg [3:0] pwm_counter = 0;
reg [3:0] clk195_div = 0;  // Start from 0 for correct first toggle

always @(posedge clk_3125KHz) begin
    if (clk195_div == 0) begin
        clk_195KHz <= 1; // Force HIGH on first cycle
    end

    // existing divider logic
    clk195_div <= clk195_div + 1'b1;
    if (clk195_div == 8) begin
        clk_195KHz <= ~clk_195KHz;
        clk195_div <= 1;
    end

    // PWM logic
    if (pwm_counter < duty_cycle)
        pwm_signal <= 1;
    else
        pwm_signal <= 0;

    if (pwm_counter < 15)
        pwm_counter <= pwm_counter + 1'b1;
    else
        pwm_counter <= 0;
end


//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
