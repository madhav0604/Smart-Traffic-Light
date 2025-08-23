
module traffic_sensor(
    input clk,
    output reg [1:0] sensor
);
    always @(posedge clk) begin
        // Example: randomize sensor values
        sensor <= $random % 4; // produces 0,1,2,3
    end
endmodule