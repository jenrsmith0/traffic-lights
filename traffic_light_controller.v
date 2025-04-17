module traffic_light_controller (
    input clk,
    input reset,
    input ns_pedestrian,
    input ew_pedestrian,
    input error,
    input four_way_stop,
    output reg [7:0] ns_light,
    output reg [7:0] ew_light
);

// States, 7 states, represented by 3 bits
// all LED's are on for 2 seconds
parameter INIT = 3'b000;
// NS = Green, EW = Red
parameter NS_GO = 3'b001;
// NS = Yellow, EW = Red
parameter NS_YIELD = 3'b010;
// NS = Red, EW = Green
parameter EW_GO = 3'b011;
// NS = Red, EW = Yellow
parameter EW_YIELD = 3'b100;
// All blinking Yellow, 1 second interval
parameter FOUR_WAY = 3'b101;
// All blinking error, 1/2 second interval
parameter ERROR = 3'b110;

// Timing constants
parameter GREEN_TIME_MAX = 32'd750_000_000; // 15 seconds
parameter GREEN_TIME_MIN = 32'd250_000_000; // 5 seconds
parameter YELLOW_TIME = 32'd100_000_000; // 2 seconds
parameter FOUR_WAY_TIME = 32'd50_000_000;	// 1 second
parameter ERROR_TIME = 32'd25_000_000;		// 1/2 second

// Segments
parameter RED_SEG = 8'b10001000;
parameter YELLOW_SEG = 8'b10011001;
parameter GREEN_SEG = 8'b10000010;
parameter ERROR_SEG = 8'b10000000;
parameter OFF_SEG = 8'b11111111;

// States and Counters
reg [2:0] state;
reg [2:0] next_state;
reg [31:0] counter;
reg ns_ped_pressed = 1'b0;
reg ns_pedestrian_prev = 1'b0;
reg ew_ped_pressed = 1'b0;
reg ew_pedestrian_prev = 1'b0;
reg flash = 1'b0;

// State Transition
always @ (posedge clk or posedge reset) begin
	// If we are reseting, go back to INIT state
	if (reset) begin
		state <= INIT;
		counter <= 0;
	// Check if pedestrian present, only store if respective light is on
	end else begin
		if (!ns_pedestrian_prev && ns_pedestrian) begin
            if (state == EW_GO) ns_ped_pressed <= 1;
        end
        
        if (!ew_pedestrian_prev && ew_pedestrian) begin
            if (state == NS_GO) ew_ped_pressed <= 1;
        end
		
		// Check error switch
		if (error == 1) begin
			if (state != ERROR) begin
				state <= ERROR;
				flash <= 0;
				counter <= 0;
			end else if (counter >= ERROR_TIME) begin 
				counter <= 0;
				flash <= ~flash;
			end else counter <= counter + 1;
		end
		// Check four way stop switch
		else if (four_way_stop == 1) begin
			if (state != FOUR_WAY) begin
				state <= FOUR_WAY;
				flash <= 0;
				counter <= 0;
			end else if (counter >= FOUR_WAY_TIME) begin 
				counter <= 0;
				flash <= ~flash;
			end else counter <= counter + 1;
		// If the switches are off and our previous state was error or four way
		end else if (((state == ERROR) || (state == FOUR_WAY)) && ((error == 0) || (four_way_stop == 0))) begin
			state <= next_state;
			counter <= 0;
		end
		// Check if a pedestrian pressed a button
		else if ((state == EW_GO) && (ns_ped_pressed) && (counter >= GREEN_TIME_MIN)) begin
			state <= next_state;
			counter <= 0;
			ns_ped_pressed <= 0;
		end
		else if ((state == NS_GO) && (ew_ped_pressed) && (counter >= GREEN_TIME_MIN)) begin
			state <= next_state;
			counter <= 0;
			ew_ped_pressed <= 0;
		end
		// If our current state is a GREEN LIGHT, we wait for GREEN TIME before next state
		else if ((((state == NS_GO) || (state == EW_GO)) && (counter == GREEN_TIME_MAX))) begin
			state <= next_state;
			counter <= 0;
		end
		// If our current state is a YELLOW LIGHT, we wait for YELLOW TIME before next state
		else if (((state == INIT) || (state == NS_YIELD) || (state == EW_YIELD)) && (counter == YELLOW_TIME)) begin
			state <= next_state;
			counter <= 0;
		end else counter <= counter + 1;
		
		ns_pedestrian_prev <= ns_pedestrian;
		ew_pedestrian_prev <= ew_pedestrian;
	end
end

// Next State Logic
always @ (*) begin
	case (state)
		INIT: next_state = NS_GO;
		NS_GO: next_state = NS_YIELD;
		NS_YIELD: next_state = EW_GO;
		EW_GO: next_state = EW_YIELD;
		EW_YIELD: next_state = NS_GO;
		ERROR: next_state = NS_GO;
		FOUR_WAY: next_state = NS_GO;
		default: next_state = INIT;
	endcase
end

// Output Logic
always @ (*) begin
	case (state)
		INIT: begin
			ns_light = ERROR_SEG;
			ew_light = ERROR_SEG;
		end
		NS_GO: begin
			ns_light = GREEN_SEG;
			ew_light = RED_SEG;
		end
		NS_YIELD: begin
			ns_light = YELLOW_SEG;
			ew_light = RED_SEG;
		end
		EW_GO: begin
			ns_light = RED_SEG;
			ew_light = GREEN_SEG;
		end
		EW_YIELD: begin
			ns_light = RED_SEG;
			ew_light = YELLOW_SEG;
		end
		FOUR_WAY: begin
			// If the light is currently RED, switch off. Otherwise, turn RED
			ns_light = (flash == 1) ? OFF_SEG : RED_SEG;
			ew_light = (flash == 1) ? OFF_SEG : RED_SEG;
		end
		ERROR: begin
			// If the light is currently ERROR, switch off. Otherwise, turn ERROR
			ns_light = (flash == 1) ? OFF_SEG : ERROR_SEG;
			ew_light = (flash == 1) ? OFF_SEG : ERROR_SEG;
		end
		default: begin
			ns_light = 8'b11111111;
			ew_light = 8'b11111111;
		end
	endcase
end

endmodule
