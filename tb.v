`timescale 1ns/1ps

module Lift8_Tb;

  reg clk, reset, emergency_stop;
  reg [2:0] req_floor;
  wire idle, door, Up, Down;
  wire [2:0] current_floor;
  wire [2:0] max_request, min_request;
  wire [7:0] requests;

  Lift8 dut(
    .clk(clk),
    .reset(reset),
    .req_floor(req_floor),
    .idle(idle),
    .door(door),
    .Up(Up),
    .Down(Down),
    .current_floor(current_floor),
    .max_request(max_request),
    .min_request(min_request),
    .requests(requests),
    .emergency_stop(emergency_stop)
  );

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, Lift8_Tb);

    clk = 0;
    emergency_stop = 0;
    reset = 1;
    #10;
    reset = 0;

    req_floor = 3'b001;
    #30;

    req_floor = 3'b100;
    #10;

    req_floor = 3'b011;
    #20;

    req_floor = 3'b111;
    #20;

    emergency_stop = 1;
    #20;

    emergency_stop = 0;
    #10;

    req_floor = 3'b010;
    #40;

    req_floor = 3'b110;
    #20;

    #20;
    req_floor = 3'b001;
  end

  initial begin
    $display("Starting simulation...");
    $monitor("Time=%t, clk=%b, reset=%b, req_floor=%b, idle=%b, door=%b, Up=%b, Down=%b, current_floor=%b, max_request=%b, min_request=%b, requests=%b",
              $time, clk, reset, req_floor, idle, door, Up, Down, current_floor, max_request, min_request, requests);
    #305;
    $display("Simulation finished.");
    $finish;
  end

  always #5 clk = ~clk;

endmodule