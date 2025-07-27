module FSMTB();

  reg clk, reset;
  reg [2:0] req_floor;
  reg req_valid;
  reg ir_blocked, overload, emergency_stop;

  wire door;
  wire [2:0] current_floor;
  wire Up, Down, idle, overload_warn;

  // Instantiate the DUT
  FSM dut (
    .clk(clk),
    .reset(reset),
    .req_floor(req_floor),
    .req_valid(req_valid),
    .emergency_stop(emergency_stop),
    .ir_blocked(ir_blocked),
    .overload(overload),
    .door(door),
    .current_floor(current_floor),
    .Up(Up),
    .Down(Down),
    .idle(idle),
    .overload_warn(overload_warn)
  );

  // Clock generation: 10 time units period
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpfile("Lift8_waveform.vcd");
    $dumpvars(0, FSMTB);

    // Initialize signals
    reset = 1;
    req_floor = 3'b000;
    req_valid = 0;
    ir_blocked = 0;
    overload = 0;
    emergency_stop = 0;

    #20;            // Hold reset for 2 clock cycles
    reset = 0;

    // Request floor 3
    req_floor = 3'b011;
    req_valid = 1;
    #10;
    req_valid = 0;

    #30;            // Wait some cycles for elevator to start moving

    // Request floor 5
    req_floor = 3'b101;
    req_valid = 1;
    #10;
    req_valid = 0;

    #30;

    // Request floor 7
    req_floor = 3'b111;
    req_valid = 1;
    #10;
    req_valid = 0;

    #50;

    // Test IR obstruction (door should stay open)
    ir_blocked = 1;
    #70;
    ir_blocked = 0;

    // Test overload (door open, warning asserted)
    overload = 1;
    #20;
    overload = 0;

    // Emergency stop pressed (door opens, elevator halts)
    emergency_stop = 1;
    #30;
    emergency_stop = 0;

    #50;

    // Request floor 1 after emergency cleared
    req_floor = 3'b010;
    req_valid = 1;
    #10;
    req_valid = 0;


    #10;
    req_floor = 3'b101;
    req_valid = 1;
    #10;
    req_valid = 0;

    // Let elevator run for a while
    #150;

    $finish;
  end

endmodule
