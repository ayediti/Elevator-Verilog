module Lift8(
  input clk,
  input reset,               // to reset the elevator
  input [2:0] req_floor,     // requested floor [input]
  input emergency_stop,      // emergency stop button 
  input ir_blocked,          // turns 1 if someone is obstructing the door, necessary to check before closing the door
  input overload,            // weight sensor output, turns 1 if the elevator is overloaded
  output reg door,                      // door = 1 when open, door = 0 when closed
  output reg [2:0] max_request,         // the maximum floor requested
  output reg [2:0] min_request,         // the minimum floor requested
  output reg Up,
  output reg Down,                      // defines direction of movement of elevator
  output reg idle,                      // idle = 1 when elevator is stationary, idle = 0 when elevator is moving
  output reg [2:0] current_floor,       // the current floor
  output reg [7:0] requests,            // reg i  turns 1 when ith floor is requested
  output reg overload_warn              // warning is given when the elevator is overloaded
);

  reg flag;                    // memory variable for emergency button

  initial begin                // initially 
    flag = 0;
    requests = 8'b0;
    door = 0;
    Up = 1;                    // initially the elevator is at level 0 so the predefined direction of movement is Up
    Down = 0;
    idle = 0;
    current_floor = 3'b000;
    max_request = 3'b000;
    min_request = 3'b111;
    overload_warn = 0;
  end

  always @(req_floor) begin                     // Update requests on floor request
    requests[req_floor] = 1;                    // reg i  turns 1 when ith floor is requested

    if (max_request < req_floor)
      max_request = req_floor;                  

    if (min_request > req_floor)
      min_request = req_floor;                  // updating max and min requests

    if (requests[max_request] == 0 && req_floor > current_floor)
      max_request = req_floor; // when max_request is reached, the elevator goes down. if requested floor is above current floor, it will be the new max_request

    if (requests[min_request] == 0 && req_floor < current_floor)
      min_request = req_floor; // when min_request is reached, the elevator goes up. if requested floor is below current floor, it will be the new min_request
  end

  // Main control FSM
  always @(posedge clk) begin

    if (emergency_stop) begin                            // emergency!!!
      idle <= 1;                                         // elevator halts
      flag <= 1;                                         // memory updated
      door <= 1;                                         // door opened
    end

    else if (!emergency_stop && flag) begin              // executes when emergency button is unpressed after pressing
      flag <= 0;                                         // elevator clears for normal operation
    end

    else if (reset) begin                                // elevator reset condition
      flag <= 0;
      current_floor <= 3'b000;
      idle <= 0;
      door <= 0;
      Up <= 1;
      Down <= 0;
      max_request <= 3'b000;
      min_request <= 3'b111;
      requests <= 8'b0;
    end


    else if (door) begin                                           // when door is opened and no emergency (case covered above)
      overload_warn = overload;                                          // warning given in case of overload

      if (!ir_blocked && !overload) begin                                // door closes in case of no obstruction and no overloading
        door <= 0; 
      end
    end

    else if (requests[current_floor] == 1) begin                         // check if current floor is requested
      idle <= 1;                                                         // elevator halts
      door <= 1;                                                         // door opened
      requests[current_floor] <= 0;                                      // request cleared
    end

    else begin
      if (min_request < current_floor && Down == 1) begin                // in case of Down
        current_floor <= current_floor - 1;
        door <= 0;
        idle <= 0;
      end
      else if (max_request > current_floor && Up == 1) begin             // in case of Up
        current_floor <= current_floor + 1;
        door <= 0;
        idle <= 0;
      end
      else if (req_floor == current_floor) begin               // if the req floor is current floor ie there are no new requests, the elevator must stay stationary
        door <= 1;
        idle <= 1;
      end
      else if (max_request == current_floor) begin             // at max_request, switch direction
        Up <= 0;
        Down <= 1;
      end
      else if (min_request == current_floor) begin             // at min_request, switch direction
        Up <= 1;
        Down <= 0;
      end
    end
  end
endmodule