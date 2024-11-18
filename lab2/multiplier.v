`timescale 1ns / 1ps

module multiplier (
    input  wire         clk,
	input  wire         rst,        // high active
	input  wire [31:0]  x,          // multiplicand
	input  wire [31:0]  y,          // multiplier
	input  wire         start,      // 1 - multiplication should begin
	output reg  [63:0]  z,          // product
	output reg          busy        // 1 - performing multiplication; 0 - multiplication ends
);

    // ****************************************************
    // Delete this block of code and write your own
//    reg [31:0] x_r, y_r;
//    always @(posedge clk or posedge rst) begin
//        busy <= rst ? 1'b0 : start;
//        if (start) begin
//            x_r <= x;
//            y_r <= y;
//            busy <= 1;
//        end
//    end
//    always @(*) z = $signed(x_r) * $signed(y_r);
    // ****************************************************



    // TODO
reg [5:0] cnt = 32;
reg [31:0] xc;
reg [31:0] yc;
reg [32:0] ya;
wire [31:0] xm = ~xc + 1;
reg [31:0] pr = 0;
reg [64:0] next = 0;

    // TODO
always @(posedge clk or posedge rst) begin
    if (rst)begin
        xc <= 0;
        yc <= 0;
        busy <= 0;
        cnt <= 32;
        pr <= 0;
    end
end

always @(posedge clk) begin
    if(start) begin
        xc <= x;


        yc <= y;
        busy <= 1;
        cnt <= 32;
        pr <= 0;
        
    end
end


always @(posedge clk)begin
    if(busy)begin
        ya = {yc, 1'b0};
        while(cnt > 0)begin
            if(ya[0] - ya[1] == 1)
                pr = pr + xc;
            else if (ya[0] - ya[1] == -1)
                pr = pr + xm;
            next = {pr,ya};
            next = next >> 1;
            next[64] = next[63];
            pr = next[64:33];
            ya = next[32:0];
            cnt = cnt - 1;
        end
        z <= {pr,ya[32:1]};
        busy <= 0;
    end
end
    
endmodule
