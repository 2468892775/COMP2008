`timescale 1ns / 1ps

module divider (
    input  wire         clk,
    input  wire         rst,        // high active
    input  wire [31:0]  x,          // dividend
    input  wire [31:0]  y,          // divisor
    input  wire         start,      // 1 - division should begin
    output reg  [31:0]  z,          // quotient
    output reg  [31:0]  r,          // remainder
    output reg          busy        // 1 - performing division; 0 - division ends
);

    // ****************************************************
    // Delete this block of code and write your own
//    reg [31:0] x_r, y_r;
//    always @(posedge clk or posedge rst) begin
//        busy <= rst ? 1'b0 : start;
//        if (start) begin
//            x_r <= x;
//            y_r <= y;
//        end
//    end
//    always @(*) z = {x_r[31] ^ y_r[31], x_r[30:0] / y_r[30:0]};
//    always @(*) r = {x_r[31], x_r[30:0] % y_r[30:0]};
    // ****************************************************



    // TODO
reg [4:0] cnt = 31;
reg [31:0] xc;
reg [31:0] yc;
wire [31:0] xu = {1'b0,xc[30:0]};
wire [31:0] yu = {1'b0,yc[30:0]};
wire [31:0] ym = ~yu + 1'b1;
wire [62:0] addu = yu << 31;
wire [62:0] addm = ym << 31;
reg [62:0]quo = 0;
reg [62:0] quo_next;
reg [31:0] res_next;
reg [31:0] res; 


    // TODO
always @(posedge clk or posedge rst) begin
    if (rst)begin
        r <= 0;
        xc <= 0;
        yc <= 0;
        busy <= 0;
        quo <= 0;
        cnt <= 31;
    end
end

always @(posedge clk) begin
    if(start) begin
        xc <= x;
        yc <= y;
        busy <= 1;
        cnt <= 31;
    end
end


always @(posedge clk)begin
    if(busy)begin
        quo =  xu + addm;
        while(cnt > 0)begin
            if(quo[62] == 0)begin
                res[0] = 1;
                quo_next = quo << 1;
                res_next = res << 1;
                quo_next = quo_next + addm;
            end else begin
                res[0] = 0;
                quo_next = quo << 1;
                res_next = res << 1;
                quo_next = quo_next + addu;
            end
            quo = quo_next;
            res = res_next;
            cnt = cnt - 1;
        end
        if (quo[62] == 0)begin
            res[0] = 1;
        end
        else begin
            res[0] = 0;
            quo = quo + addu;
        end
        z <= {xc[31]^yc[31], res[30:0]};
        r <= {xc[31], quo[61:31]};
        busy <= 0;
    end
end
    
    

endmodule
