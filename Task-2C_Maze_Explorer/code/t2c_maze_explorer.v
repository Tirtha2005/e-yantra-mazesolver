// Task 2C - MazeSolver Bot

module t2c_maze_explorer (
    input clk,
    input rst_n,
    input left, mid, right, // 0 - no wall, 1 - wall
    output reg [2:0] move
);

/*

| cmd | move  | meaning   |
|-----|-------|-----------|
| 000 | 0     | STOP      |
| 001 | 1     | FORWARD   |
| 010 | 2     | LEFT      |
| 011 | 3     | RIGHT     | 
| 100 | 4     | U_TURN    |

START POS   : 4,0
EXIT POS    : 4,8
DEADENDS    : 9

*/
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

reg [1:0] current_state;          // FSM current state
reg [1:0] facing_direction;       // Current facing direction of the bot
reg [6:0] iterator;               // Loop iterator for initialization
reg [6:0] path_left;              // Left path index
reg [6:0] path_right;             // Right path index
reg [6:0] path_forward;           // Forward path index
reg [6:0] path_backward;          // Backward path index
reg [6:0] cell_now;               // Current cell position in maze
reg [6:0] cell_next;              // Next cell position after a move

reg [1:0] visit_log [0:80];       // Track how many times each cell was visited

// FSM State Definitions
parameter S_IDLE   = 2'd0;        // Idle / reset state
parameter S_DECIDE = 2'd1;        // Decision-making state
parameter S_MOVE   = 2'd2;        // Move execution state

// Direction Definitions
parameter DIR_NORTH = 2'd0;       // Facing upward (north)
parameter DIR_SOUTH = 2'd1;       // Facing downward (south)
parameter DIR_EAST  = 2'd2;       // Facing right (east)
parameter DIR_WEST  = 2'd3;       // Facing left (west)


// Initialization Block: Clear visit log at start

initial begin 
    for (iterator = 0; iterator < 81; iterator = iterator + 1)
        visit_log[iterator] = 0;
end



// Direction Logic: Calculate next cell indices
// based on the bot's current facing direction

always @(*) begin
    case (facing_direction)
        DIR_NORTH: begin
            path_forward  = cell_now - 9;   
            path_left     = cell_now - 1;   
            path_right    = cell_now + 1;
            path_backward = cell_now + 9;   
        end

        DIR_SOUTH: begin
            path_forward  = cell_now + 9;   
            path_left     = cell_now + 1;  
            path_right    = cell_now - 1;  
            path_backward = cell_now - 9; 
        end

        DIR_EAST: begin
            path_forward  = cell_now + 1;   
            path_left     = cell_now - 9;   
            path_right    = cell_now + 9;  
            path_backward = cell_now - 1;
        end

        DIR_WEST: begin
            path_forward  = cell_now - 1;   
            path_left     = cell_now + 9;   
            path_right    = cell_now - 9;  
            path_backward = cell_now + 1; 
        end
    endcase
end

// Main FSM (Finite State Machine) for Maze Solver

always @(posedge clk) begin
    if (!rst_n) begin
        // Reset condition
        move <= 3'b000;                  // Stop initially
        cell_now <= 7'd76;               // Start position (4,0)
        current_state <= S_IDLE;
        facing_direction <= DIR_NORTH;   // Initially facing north
    end else begin
        case (current_state)

   
            // IDLE: Waits briefly, then enters decision mode
           
            S_IDLE: begin
                move <= 3'b000;
                current_state <= S_DECIDE;
            end

            // DECIDE: Choose direction based on wall sensors
          
            S_DECIDE: begin
                visit_log[cell_now] <= visit_log[cell_now] + 1;  

                // All directions blocked → perform U-turn
                if (mid && left && right) begin
                    move <= 3'b100;
                    cell_next <= path_backward;
                end

                // Front and right blocked → turn left
                else if (mid && right && !left) begin
                    move <= 3'b010;
                    cell_next <= path_left;
                end

                // Front and left blocked → turn right
                else if (mid && left && !right) begin
                    move <= 3'b011;
                    cell_next <= path_right;
                end

                // Both sides blocked, forward free → move forward
                else if (left && right && !mid) begin
                    move <= 3'b001;
                    cell_next <= path_forward;
                end

                // Right blocked, left open → prefer unvisited left path
                else if (right && !left && !mid) begin
                    if (visit_log[path_left] == 0) begin
                        move <= 3'b010; 
                        cell_next <= path_left;
                    end else begin
                        move <= 3'b001;
                        cell_next <= path_forward;
                    end
                end

                // Left blocked, right open → prefer unvisited right path
                else if (left && !right && !mid) begin
                    if (visit_log[path_right] == 0) begin
                        move <= 3'b011; 
                        cell_next <= path_right;
                    end else begin
                        move <= 3'b001; 
                        cell_next <= path_forward;
                    end
                end

                // Front blocked, both sides open → prefer unvisited side
                else if (mid && !left && !right) begin
                    if (visit_log[path_left] == 0) begin
                        move <= 3'b010; 
                        cell_next <= path_left;
                    end else begin
                        move <= 3'b011;
                        cell_next <= path_right;
                    end
                end

                // Proceed to execute movement
                current_state <= S_MOVE;
            end


            // MOVE: Execute the chosen move and update direction
           
            S_MOVE: begin
                case (move)
                    3'b001: begin  // FORWARD
                        cell_now <= cell_next;
                    end

                    3'b010: begin  // LEFT TURN
                        cell_now <= cell_next;                       
                        case (facing_direction)
                            DIR_NORTH: facing_direction <= DIR_WEST;
                            DIR_WEST:  facing_direction <= DIR_SOUTH;
                            DIR_SOUTH: facing_direction <= DIR_EAST;
                            DIR_EAST:  facing_direction <= DIR_NORTH;
                        endcase
                    end

                    3'b011: begin  // RIGHT TURN
                        cell_now <= cell_next;
                        case (facing_direction)
                            DIR_NORTH: facing_direction <= DIR_EAST;
                            DIR_EAST:  facing_direction <= DIR_SOUTH;
                            DIR_SOUTH: facing_direction <= DIR_WEST;
                            DIR_WEST:  facing_direction <= DIR_NORTH;
                        endcase
                    end

                    3'b100: begin  // U-TURN
                        cell_now <= cell_next;
                        case (facing_direction)
                            DIR_NORTH: facing_direction <= DIR_SOUTH;
                            DIR_SOUTH: facing_direction <= DIR_NORTH;
                            DIR_EAST:  facing_direction <= DIR_WEST;
                            DIR_WEST:  facing_direction <= DIR_EAST;
                        endcase
                    end
                endcase

                // After movement, return to decision state
                current_state <= S_DECIDE;
            end

        endcase
    end
end
//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule