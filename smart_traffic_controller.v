module smart_traffic_controller (
    input clk,
    input reset,
    
    input [1:0] sensor_north, sensor_south, sensor_east, sensor_west,
    
    // North lights
    output reg light_north_red,
    output reg light_north_yellow,
    output reg light_north_green_straight,
    output reg light_north_green_right,
    
    // South lights  
    output reg light_south_red,
    output reg light_south_yellow,
    output reg light_south_green_straight,
    output reg light_south_green_right,
    
    // East lights
    output reg light_east_red,
    output reg light_east_yellow,
    output reg light_east_green_straight,
    output reg light_east_green_right,
    
    // West lights
    output reg light_west_red,
    output reg light_west_yellow,
    output reg light_west_green_straight,
    output reg light_west_green_right
);

    reg [3:0] state;
    reg start_timer;  // Changed from start_timer_pulse
    reg [31:0] duration;
    wire timeout;
    reg prev_timeout;  // To detect timeout edge

    // Instantiate timer module
    timer t1 (
        .clk(clk),
        .reset(reset),
        .start_timer(start_timer),
        .load_value(duration),
        .timeout(timeout)
    );

    // Dynamic Green Time Based on Sensor
    function [31:0] get_dynamic_green_total;
        input [1:0] sensor;
        begin
            case(sensor)
                2'b00: get_dynamic_green_total = 30;   // No traffic
                2'b01: get_dynamic_green_total = 45;   // Low traffic
                2'b10: get_dynamic_green_total = 70;   // Medium traffic
                2'b11: get_dynamic_green_total = 100;  // High traffic
                default: get_dynamic_green_total = 45;
            endcase
        end
    endfunction

    // Function to get straight+right duration (70% of total)
    function [31:0] get_straight_right_duration;
        input [1:0] sensor;
        begin
            get_straight_right_duration = (get_dynamic_green_total(sensor) * 7) / 10;
        end
    endfunction

    // Function to get straight-only duration (30% of total)
    function [31:0] get_straight_only_duration;
        input [1:0] sensor;
        begin
            get_straight_only_duration = get_dynamic_green_total(sensor) - get_straight_right_duration(sensor);
        end
    endfunction

    // FSM - 10 states as requested
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 1;
            start_timer <= 1;
            duration <= get_straight_right_duration(sensor_south);
            prev_timeout <= 0;
        end 
        else begin
            prev_timeout <= timeout;
            
            // Detect rising edge of timeout
            if (timeout && !prev_timeout) begin
                start_timer <= 0; // Stop current timer
                case (state)
                    1: begin // South straight+right
                        state <= 2;
                        duration <= get_straight_only_duration(sensor_south);
                    end
                    2: begin // South straight + North straight
                        state <= 3;
                        duration <= 5; // Yellow duration
                    end
                    3: begin // South yellow, North straight
                        state <= 4;
                        duration <= get_straight_right_duration(sensor_north);
                    end
                    4: begin // North straight+right
                        state <= 5;
                        duration <= 5; // Yellow duration
                    end
                    5: begin // North yellow
                        state <= 6;
                        duration <= get_straight_right_duration(sensor_east);
                    end
                    6: begin // East straight+right
                        state <= 7;
                        duration <= get_straight_only_duration(sensor_east);
                    end
                    7: begin // East straight + West straight
                        state <= 8;
                        duration <= 5; // Yellow duration
                    end
                    8: begin // East yellow, West straight
                        state <= 9;
                        duration <= get_straight_right_duration(sensor_west);
                    end
                    9: begin // West straight+right
                        state <= 10;
                        duration <= 5; // Yellow duration
                    end
                    10: begin // West yellow
                        state <= 1;
                        duration <= get_straight_right_duration(sensor_south);
                    end
                endcase
                start_timer <= 1; // Start new timer in next cycle
            end
            else if (!timeout) begin
                start_timer <= 0; // Keep start_timer low when timer is running
            end
        end
    end

    // Output Logic
    always @(*) begin
        // Default all lights red
        light_north_red = 1; light_north_yellow = 0; 
        light_north_green_straight = 0; light_north_green_right = 0;
        
        light_south_red = 1; light_south_yellow = 0; 
        light_south_green_straight = 0; light_south_green_right = 0;
        
        light_east_red = 1; light_east_yellow = 0; 
        light_east_green_straight = 0; light_east_green_right = 0;
        
        light_west_red = 1; light_west_yellow = 0; 
        light_west_green_straight = 0; light_west_green_right = 0;

        case (state)
            1: begin // South straight+right
                light_south_red = 0;
                light_south_green_straight = 1;
                light_south_green_right = 1;
            end
            2: begin // South straight + North straight
                light_south_red = 0;
                light_south_green_straight = 1;
                light_north_red = 0;
                light_north_green_straight = 1;
            end
            3: begin // South yellow, North straight continues
                light_south_red = 0;
                light_south_yellow = 1;
                light_north_red = 0;
                light_north_green_straight = 1;
            end
            4: begin // North straight+right
                light_north_red = 0;
                light_north_green_straight = 1;
                light_north_green_right = 1;
            end
            5: begin // North yellow
                light_north_red = 0;
                light_north_yellow = 1;
            end
            6: begin // East straight+right
                light_east_red = 0;
                light_east_green_straight = 1;
                light_east_green_right = 1;
            end
            7: begin // East straight + West straight
                light_east_red = 0;
                light_east_green_straight = 1;
                light_west_red = 0;
                light_west_green_straight = 1;
            end
            8: begin // East yellow, West straight continues
                light_east_red = 0;
                light_east_yellow = 1;
                light_west_red = 0;
                light_west_green_straight = 1;
            end
            9: begin // West straight+right
                light_west_red = 0;
                light_west_green_straight = 1;
                light_west_green_right = 1;
            end
            10: begin // West yellow
                light_west_red = 0;
                light_west_yellow = 1;
            end
        endcase
    end

endmodule
