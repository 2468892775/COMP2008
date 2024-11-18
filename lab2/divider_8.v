`timescale 1ns / 1ps

module divider (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] x,
    input  wire [7:0] y,
    input  wire       start,
    output wire [7:0] z,
    output reg  [7:0] r,
    output reg        busy
);
reg [3:0] cnt = 7;
reg [7:0] xc;
reg [7:0] yc;
wire [7:0] xu = {1'b0,xc[6:0]};
wire [7:0] yu = {1'b0,yc[6:0]};
wire [7:0] ym = ~yu + 1'b1;
wire [14:0] addu = yu << 7;
wire [14:0] addm = ym << 7;
reg [14:0]quo = 0;
reg [14:0] quo_next;
reg [7:0] res_next;
reg [7:0] res; 
assign z = res;


    // TODO
always @(posedge clk or posedge rst) begin
    if (rst)begin
        r <= 8'b0;
        xc <= 8'b0;
        yc <= 8'b0;
        busy <= 0;
        quo <= 0;
        cnt <= 7;
    end
end

always @(posedge clk) begin
    if(start) begin
        xc <= x;
        yc <= y;
        busy <= 1;
        cnt <= 7;
        
    end
end


always @(posedge clk)begin
    if(busy)begin
        if(cnt == 7)begin
            quo = xu + addm;
        end
        if(cnt > 0)begin
            if(quo[14] == 0)begin
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
    end
end

always @(posedge clk)begin
    if(busy)begin
        if(cnt == 0)begin
            if (quo[14] == 0)begin
                res[0] = 1;
            end
            else begin
                res[0] = 0;
                quo = quo + addu;
            end
            res <= {xc[7]^yc[7], res[6:0]};
            r <= {xc[7], quo[13:7]};
            busy <= 0;
        end
    end
end

	
endmodule