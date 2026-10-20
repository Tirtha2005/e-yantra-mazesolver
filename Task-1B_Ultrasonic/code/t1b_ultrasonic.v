/*
Module HC_SR04 Ultrasonic Sensor

This module will detect objects present in front of the range, and give the distance in mm.

Input:  clk_50M - 50 MHz clock
        reset   - reset input signal (Use negative reset)
        echo_rx - receive echo from the sensor

Output: trig    - trigger sensor for the sensor
        op     -  output signal to indicate object is present.
        distance_out - distance in mm, if object is present.
*/

// module Declaration
module t1b_ultrasonic(
    input clk_50M, reset, echo_rx,
    output reg trig,
    output op,
    output wire [15:0] distance_out
);

initial begin
    trig = 0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

// State machine registers
    

    reg [2:0] state;            // FSM current state
    reg detection;               // Object detected flag
    reg [15:0] distance;         // Measured distance in mm

    // Counters for timing different phases
    integer delay_counter = 0;      // Small delay before sending trigger
    integer trigger_counter = 0;    // Duration of trigger pulse
    integer echo_counter = 0;       // Duration of echo pulse high
    integer wait_counter = 0;       // Wait time before next measurement

    // Sum of counters for debugging/monitoring
    reg [31:0] sum_counters;
    // FSM state definitions
   
    localparam DELAY = 0,                // Wait before sending trigger
               TRIG_PHASE = 1,           // Send trigger pulse
               MONITOR = 2,              // Measure echo pulse width
               CALCULATION = 3,          // (Optional) distance calculation
               OBJECT_DETERMINATION = 4, // Check if object is within threshold
               FINISHED = 5;             // Wait before restarting measurement

    // Initial values
    initial begin 
        state = DELAY;
        detection = 0;
        distance = 0;
        delay_counter = 0;
        trigger_counter = 0;
        echo_counter = 0; 
        wait_counter = 0;
        sum_counters = 0;
    end

    // Main state machine
    always @(posedge clk_50M) begin
        if (reset == 0) begin
            // Reset all counters and flags
            state <= DELAY;
            detection <= 0;
            distance <= 0;
            delay_counter <= 0;
            trigger_counter <= 0;
            echo_counter <= 0;
            wait_counter <= 0;
            trig <= 0;
            sum_counters <= 0;
        end
        else begin
            case (state)
               
                // DELAY: small waiting period before trigger pulse
               
                DELAY: begin
                    if (delay_counter != 50) delay_counter <= delay_counter + 1;
                    else begin
                        delay_counter <= 0;
                        state <= TRIG_PHASE; // Move to trigger phase
                    end
                end

               
                // TRIG_PHASE: generate trigger pulse
              
                TRIG_PHASE: begin
                    trig <= 1; // Start trigger
                    if (trigger_counter != 500) trigger_counter <= trigger_counter + 1;
                    else begin
                        trigger_counter <= 0;
                        trig <= 0; // Stop trigger
                        state <= MONITOR; // Start monitoring echo
                    end
                end
               
                // MONITOR: measure duration of echo pulse
           
                MONITOR: begin
                    if (echo_rx) echo_counter <= echo_counter + 1; // Count echo pulse high time
                    else begin
                        distance <= (echo_counter * 34) / 10000; // Convert counter to distance in mm
                        echo_counter <= 0;
                        state <= OBJECT_DETERMINATION; // Check object distance
                    end
                    wait_counter <= wait_counter + 1; // Increment general wait counter
                end

            
                // OBJECT_DETERMINATION: check if object is within threshold
            
                OBJECT_DETERMINATION: begin
                    if (distance <= 16'd70) detection <= 1; // Object detected
                    else detection <= 0;                     // No object
                    wait_counter <= wait_counter + 1;       // Continue wait for next measurement
                    state <= FINISHED;
                end

            
                // FINISHED: wait before starting next measurement
           
                FINISHED: begin
                    if (wait_counter != 600001) wait_counter <= wait_counter + 1;
                    else begin
                        wait_counter <= 0;
                        state <= DELAY; // Restart measurement cycle
                    end
                end
            endcase

            // Update sum of all counters (for monitoring/debugging)
            sum_counters <= delay_counter + trigger_counter + echo_counter + wait_counter;
        end
    end    

  
    // Output assignments

    assign distance_out = distance;      // Output measured distance
    assign op = ~echo_rx;               // Output object detection flag
    assign sum_out = sum_counters;       // Output sum of counters
	 
//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule