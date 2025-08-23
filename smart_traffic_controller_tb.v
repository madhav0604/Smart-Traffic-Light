`timescale 1ns / 1ps

module smart_traffic_controller_tb;

    reg clk = 0;
    reg reset = 0;

    reg [1:0] sensor_north = 2'b01;  // Start with some traffic
    reg [1:0] sensor_south = 2'b01;
    reg [1:0] sensor_east = 2'b01;
    reg [1:0] sensor_west = 2'b01;

    // Updated wire declarations for separate straight and right lights
    wire light_north_red, light_north_yellow, light_north_green_straight, light_north_green_right;
    wire light_south_red, light_south_yellow, light_south_green_straight, light_south_green_right;
    wire light_east_red, light_east_yellow, light_east_green_straight, light_east_green_right;
    wire light_west_red, light_west_yellow, light_west_green_straight, light_west_green_right;

    // Clock generation (10ns period = 100MHz)
    always #5 clk = ~clk;

    // Instantiate DUT with updated port connections
    smart_traffic_controller dut (
        .clk(clk),
        .reset(reset),
        .sensor_north(sensor_north),
        .sensor_south(sensor_south),
        .sensor_east(sensor_east),
        .sensor_west(sensor_west),
        .light_north_red(light_north_red),
        .light_north_yellow(light_north_yellow),
        .light_north_green_straight(light_north_green_straight),
        .light_north_green_right(light_north_green_right),
        .light_south_red(light_south_red),
        .light_south_yellow(light_south_yellow),
        .light_south_green_straight(light_south_green_straight),
        .light_south_green_right(light_south_green_right),
        .light_east_red(light_east_red),
        .light_east_yellow(light_east_yellow),
        .light_east_green_straight(light_east_green_straight),
        .light_east_green_right(light_east_green_right),
        .light_west_red(light_west_red),
        .light_west_yellow(light_west_yellow),
        .light_west_green_straight(light_west_green_straight),
        .light_west_green_right(light_west_green_right)
    );

    // Monitor task for better output formatting
    task display_lights;
        begin
            $display("Time: %0t ns, State: %0d, Timer: %0d, Timeout: %b", 
                     $time, dut.state, dut.t1.counter, dut.timeout);
            $display("  North: R=%b Y=%b GS=%b GR=%b", 
                     light_north_red, light_north_yellow, 
                     light_north_green_straight, light_north_green_right);
            $display("  South: R=%b Y=%b GS=%b GR=%b", 
                     light_south_red, light_south_yellow, 
                     light_south_green_straight, light_south_green_right);
            $display("  East:  R=%b Y=%b GS=%b GR=%b", 
                     light_east_red, light_east_yellow, 
                     light_east_green_straight, light_east_green_right);
            $display("  West:  R=%b Y=%b GS=%b GR=%b", 
                     light_west_red, light_west_yellow, 
                     light_west_green_straight, light_west_green_right);
            $display("  Sensors: N=%b S=%b E=%b W=%b", 
                     sensor_north, sensor_south, sensor_east, sensor_west);
            $display("---");
        end
    endtask

    // Task to change traffic conditions
    task change_traffic;
        input [1:0] n, s, e, w;
        input [8*20:1] description;
        begin
            $display("\n=== %s ===", description);
            sensor_north = n;
            sensor_south = s;
            sensor_east = e;
            sensor_west = w;
            display_lights();
        end
    endtask

    initial begin
        $dumpfile("traffic_controller_tb.vcd");
        $dumpvars(0, smart_traffic_controller_tb);

        $display("Starting Smart Traffic Controller Testbench");
        $display("===========================================");
        $display("Clock Period: 10ns, Simulation will run for multiple traffic cycles");
        $display("Traffic Levels: 00=No traffic, 01=Low, 10=Medium, 11=High");

        // Reset pulse
        reset = 1; 
        #20; 
        reset = 0;
        
        $display("\nReset released - Starting with low traffic everywhere");
        display_lights();

        // Let it run through first complete cycle with low traffic
        $display("\n=== Phase 1: Low traffic everywhere - Observing complete cycle ===");
        repeat(2000) begin  // Run for 2000 clock cycles
            @(posedge clk);
            if (dut.timeout) begin  // Display on every state change
                #10; // Small delay to let signals settle
                display_lights();
            end
        end

        // Change to high traffic on South
        change_traffic(2'b01, 2'b11, 2'b01, 2'b01, "High South Traffic");
        repeat(1500) begin
            @(posedge clk);
            if (dut.timeout) begin
                #10;
                display_lights();
            end
        end

        // Change to high traffic on East
        change_traffic(2'b00, 2'b01, 2'b11, 2'b00, "High East Traffic");
        repeat(1500) begin
            @(posedge clk);
            if (dut.timeout) begin
                #10;
                display_lights();
            end
        end

        // Change to high traffic on West
        change_traffic(2'b01, 2'b00, 2'b00, 2'b11, "High West Traffic");
        repeat(1500) begin
            @(posedge clk);
            if (dut.timeout) begin
                #10;
                display_lights();
            end
        end

        // Change to high traffic on North
        change_traffic(2'b11, 2'b01, 2'b00, 2'b01, "High North Traffic");
        repeat(1500) begin
            @(posedge clk);
            if (dut.timeout) begin
                #10;
                display_lights();
            end
        end

        // Peak hour scenario - high traffic everywhere
        change_traffic(2'b11, 2'b11, 2'b11, 2'b11, "Peak Hour - Heavy Traffic All Directions");
        repeat(2500) begin
            @(posedge clk);
            if (dut.timeout) begin
                #10;
                display_lights();
            end
        end

        // Late night scenario - minimal traffic
        change_traffic(2'b00, 2'b00, 2'b00, 2'b00, "Late Night - Minimal Traffic");
        repeat(1000) begin
            @(posedge clk);
            if (dut.timeout) begin
                #10;
                display_lights();
            end
        end

        // Mixed traffic scenario
        change_traffic(2'b10, 2'b01, 2'b11, 2'b00, "Mixed Traffic Conditions");
        repeat(2000) begin
            @(posedge clk);
            if (dut.timeout) begin
                #10;
                display_lights();
            end
        end

        $display("\n=== Simulation Summary ===");
        $display("Total simulation time: %0t ns", $time);
        $display("Total clock cycles: %0d", $time/10);
        $display("Testbench completed successfully!");
        $finish;
    end

    // Safety timeout - much longer now
    initial begin
        #200000;  // 200,000ns = 200μs timeout
        $display("Testbench safety timeout reached at %0t ns!", $time);
        $display("This is normal for extended simulation");
        $finish;
    end

    // Optional: Monitor state changes continuously
    reg [3:0] prev_state = 0;
    always @(posedge clk) begin
        if (dut.state != prev_state) begin
            prev_state <= dut.state;
            $display("State changed to %0d at time %0t ns", dut.state, $time);
        end
    end

endmodule
