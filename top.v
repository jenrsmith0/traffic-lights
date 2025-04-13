module top(input CLOCK, input [2:0] KEYS, input [1:0] SWITCHES, 
	output [7:0] NS_SEG, output [7:0] EW_SEG);

	traffic_light_controller t1(.clk(CLOCK), 
		.reset(~KEYS[0]), 
		.ns_pedestrian(~KEYS[1]),
		.ew_pedestrian(~KEYS[2]),
		.error(SWITCHES[0]),
		.four_way_stop(SWITCHES[1]),
		.ns_light(NS_SEG), 
		.ew_light(EW_SEG));
endmodule