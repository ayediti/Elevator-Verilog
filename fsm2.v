module FSM(
  input clk,
  input reset,               // reset elevator
  input [2:0] req_floor,     // requested floor
  input req_valid,           // new input request valid (to latch requests safely)
  input emergency_stop,      // emergency stop button
  input ir_blocked,          // obstruction sensor for door
  input overload,            // overload sensor

  output reg door,           // door: 1=open, 0=closed
  output reg [2:0] current_floor,
  output reg Up,
  output reg Down,
  output reg idle,
  output reg overload_warn
);

  // State encoding
  localparam 
    IDLE           = 3'd0,
    MOVING_UP      = 3'd1,
    MOVING_DOWN    = 3'd2,
    DOOR_OPEN      = 3'd3,
    EMERGENCY_STOP = 3'd4;

  reg [2:0] state, next_state;

  // Requests bit vector: 8 floors (0-7)
  reg [7:0] requests;

  // max and min requested floor
  reg [2:0] max_request, min_request;

  integer i;

  // State register
  always @(posedge clk or posedge reset) begin
    if (reset)
      state <= IDLE;
    else
      state <= next_state;
  end

  // Current floor update
  always @(posedge clk or posedge reset) begin
    if (reset)
      current_floor <= 3'd0;
    else if (state == MOVING_UP && !requests[current_floor])
      current_floor <= current_floor + 1;
    else if (state == MOVING_DOWN && !requests[current_floor])
      current_floor <= current_floor - 1;
  end

  // Request latch - only latch on req_valid to avoid glitches
  always @(posedge clk or posedge reset) begin
    if (reset)
      requests <= 8'b0;
    else if (req_valid)
      requests[req_floor] <= 1'b1;
  end

  // Clear request when serviced (door open at floor)
  always @(posedge clk or posedge reset) begin
    if (reset)
      requests <= 8'b0;
    /*else if (state == DOOR_OPEN)
      requests[current_floor] <= 1'b0;*/
  end

  // Compute max and min requested floors
  always @(*) begin
    max_request = 3'd0;
    min_request = 3'd7;
    for (i = 0; i < 8; i = i + 1) begin
      if (requests[i]) begin
        if (i > max_request)
          max_request = i[2:0];
        if (i < min_request)
          min_request = i[2:0];
      end
    end
  end

  // Next state and output logic
  always @(*) begin
    // Defaults
    next_state = state;
    door = 0;
    idle = 0;
    Up = 0;
    Down = 0;
    overload_warn = 0;

    case (state)
      IDLE: begin
        idle = 1;
        door = 0;
        if (emergency_stop)
          next_state = EMERGENCY_STOP;
        else if (requests[current_floor])
          next_state = DOOR_OPEN;
        else if (max_request > current_floor)
          next_state = MOVING_UP;
        else if (min_request < current_floor)
          next_state = MOVING_DOWN;
      end

      MOVING_UP: begin
        Up = 1;
        idle = 0;
        door = 0;
        if (emergency_stop)
          next_state = EMERGENCY_STOP;
        else if (requests[current_floor])
          next_state = DOOR_OPEN;
        else if (current_floor == max_request)
          next_state = MOVING_DOWN;  // change direction at max floor
      end

      MOVING_DOWN: begin
        Down = 1;
        idle = 0;
        door = 0;
        if (emergency_stop)
          next_state = EMERGENCY_STOP;
        else if (requests[current_floor])
          next_state = DOOR_OPEN;
        else if (current_floor == min_request)
          next_state = MOVING_UP;    // change direction at min floor
      end

      DOOR_OPEN: begin
        door = 1;
        idle = 1;
        overload_warn = overload;
        requests[current_floor] = 0;
        if (emergency_stop)
          next_state = EMERGENCY_STOP;
        else if (overload) 
          next_state = DOOR_OPEN;    // stay open while overloaded
        else if (!ir_blocked)
          next_state = IDLE;         // close door if no obstruction
      end

      EMERGENCY_STOP: begin
        door = 1;
        idle = 1;
        overload_warn = overload;
        if (!emergency_stop)
          next_state = IDLE;         // resume normal operation
      end

      default: next_state = IDLE;
    endcase
  end

endmodule