module Lift8(
  input clk,
  input reset,
  input [2:0] req_floor,
  input emergency_stop,
  output reg door,
  output reg [2:0] max_request,
  output reg [2:0] min_request,
  output reg Up,
  output reg Down,
  output reg idle,
  output reg [2:0] current_floor,
  output reg [7:0] requests
);

  reg door_timer;
  reg emergency_stopped;
  reg flag;

  // initialize values 
  initial begin
    flag = 0;
    requests = 8'b0;
    door = 0;
    Up = 1;
    Down = 0;
    idle = 0;
    current_floor = 3'b000;
    max_request = 3'b000;
    min_request = 3'b111;
    emergency_stopped = 0;
    door_timer = 0;
  end

  // Update requests on floor request
  always @(req_floor) begin
    requests[req_floor] = 1;

    if (max_request < req_floor)
      max_request = req_floor;

    if (min_request > req_floor)
      min_request = req_floor;

    if (requests[max_request] == 0 && req_floor > current_floor)
      max_request = req_floor;

    if (requests[min_request] == 0 && req_floor < current_floor)
      min_request = req_floor;
  end

  // Check if current floor is requested
  always @(current_floor) begin
    if (requests[current_floor] == 1) begin
      idle = 1;
      door = 1;
      requests[current_floor] = 0;
      door_timer = 1;
    end
  end

  // Main control FSM
  always @(posedge clk) begin
    if (door_timer == 1)
      door <= 0;  // close door after one cycle

    if (reset) begin
      flag <= 0;
      current_floor <= 3'b000;
      idle <= 0;
      door <= 0;
      Up <= 1;
      Down <= 0;
      max_request <= 3'b000;
      min_request <= 3'b111;
      requests <= 8'b0;
      emergency_stopped <= 0;
    end
    else if (requests == 8'b0 && !reset) begin
      current_floor <= current_floor;
      emergency_stopped <= 0;
    end
    else if (emergency_stop) begin
      idle <= 1;
      flag <= 1;
      emergency_stopped <= 1;
    end
    else if (emergency_stopped && emergency_stop) begin
      current_floor <= current_floor;
      door <= 0;
    end
    else if (!emergency_stop && flag) begin
      emergency_stopped <= 0;
      flag <= 0;
    end
    else begin
      if (max_request <= 3'b111) begin
        if (min_request < current_floor && Down == 1) begin
          current_floor <= current_floor - 1;
          door <= 0;
          idle <= 0;
        end
        else if (max_request > current_floor && Up == 1) begin
          current_floor <= current_floor + 1;
          door <= 0;
          idle <= 0;
        end
        else if (req_floor == current_floor) begin
          door <= 1;
          idle <= 1;
        end
        else if (max_request == current_floor) begin
          Up <= 0;
          Down <= 1;
        end
        else if (min_request == current_floor) begin
          Up <= 1;
          Down <= 0;
        end
      end
    end
  end
endmodule