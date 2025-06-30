module Lift8_Tb();

  logic clk, reset;
  logic [2:0] req_floor;
  logic ir_blocked, overload, emergency_stop;
  logic door;
  logic [2:0] max_request, min_request, current_floor;
  logic [7:0] requests;
  logic Up, Down, idle, overload_warn;

  Lift8 dut(
    .clk(clk),
    .reset(reset),
    .req_floor(req_floor),
    .emergency_stop(emergency_stop),
    .ir_blocked(ir_blocked),
    .overload(overload)
  );

  always #5 clk = ~clk;  // clock generation

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, Lift8_Tb);

    // Initial values
    clk = 0;
    reset = 1;
    req_floor = 3'b000;
    ir_blocked = 0;
    overload = 0;
    emergency_stop = 0;

    #10 reset = 0;

    // Requesting floors
    #10 req_floor = 3;
    #10 req_floor = 5;
    #10 req_floor = 7;

    // Check IR functionality
    #20 ir_blocked = 1;
    #10 ir_blocked = 0;

    // Check overloading
    overload = 1;
    #10 overload = 0;

    // Emergency stop button check
    #10 emergency_stop = 1;
    #20 emergency_stop = 0;

    #20 req_floor = 1;

    #120;

    $finish;
  end

endmodule
