`timescale 1ns / 1ps

 `define BLK_LEN  4
 `define BLK_SIZE (`BLK_LEN*32)

module DCache(
    input  wire         cpu_clk,
    input  wire         cpu_rst,        // high active
    // Interface to CPU
    input  wire [ 3:0]  data_ren,       // ����CPU�Ķ�ʹ���ź�
    input  wire [31:0]  data_addr,      // ����CPU�ĵ�ַ������д���ã�
    output reg          data_valid,     // �����CPU��������Ч�ź�
    output reg  [31:0]  data_rdata,     // �����CPU�Ķ�����
    input  wire [ 3:0]  data_wen,       // ����CPU��дʹ���ź�
    input  wire [31:0]  data_wdata,     // ����CPU��д����
    output reg          data_wresp,     // �����CPU��д��Ӧ���ߵ�ƽ��ʾDCache�����д������
    // Interface to Write Bus
    input  wire         dev_wrdy,       // �����д�����źţ��ߵ�ƽ��ʾ����ɽ���DCache��д����
    output reg  [ 3:0]  dev_wen,        // ����������дʹ���ź�
    output reg  [31:0]  dev_waddr,      // ����������д��ַ
    output reg  [31:0]  dev_wdata,      // ����������д����
    // Interface to Read Bus
    input  wire         dev_rrdy,       // ����Ķ������źţ��ߵ�ƽ��ʾ����ɽ���DCache�Ķ�����
    output reg  [ 3:0]  dev_ren,        // ���������Ķ�ʹ���ź�
    output reg  [31:0]  dev_raddr,      // ���������Ķ���ַ
    input  wire         dev_rvalid,     // ���������������Ч�ź�
    input  wire [`BLK_SIZE-1:0] dev_rdata   // ��������Ķ�����
);

    // Peripherals access should be uncached.
    wire uncached = (data_addr[31:16] == 16'hFFFF) & (data_ren != 4'h0 | data_wen != 4'h0) ? 1'b1 : 1'b0;

`ifdef ENABLE_DCACHE    /******** ��Ҫ�޸Ĵ��д��� ********/


    wire [4:0] tag_from_cpu   = data_addr[14:10]/* TODO */;    // �����ַ��TAG
    wire [1:0] offset         =  data_addr[3:2]/* TODO */;    // 32λ��ƫ����
    wire       valid_bit      = cache_line_r[133];  /* TODO */;    // Cache�е���Чλ
    wire [4:0] tag_from_cache = cache_line_r[132:128]/* TODO */;    // Cache�е�TAG

    // TODO: ����DCache��״̬����״̬����
    parameter R_IDLE = 0;
    parameter R_TAG_CHK = 1;
    parameter R_REFILL = 2;
    reg [1:0] r_state, r_next;

    wire hit_r = (valid_bit && (tag_from_cpu == tag_from_cache)) && (r_state == R_TAG_CHK) && !uncached;       // ������
    wire hit_w = (valid_bit && (tag_from_cpu == tag_from_cache)) && (w_state == W_TAG_CHK) && !uncached;      // д����

    always @(*) begin
        data_valid = hit_r;
        case (offset)
            2'b00: data_rdata = {(ren_next[3] ? cache_line_r[31:24] : 8'h0),
                                (ren_next[2] ? cache_line_r[23:16] : 8'h0),
                                (ren_next[1] ? cache_line_r[15:8] : 8'h0),
                                (ren_next[0] ? cache_line_r[7:0] : 8'h0)};
            2'b01: data_rdata = {(ren_next[3] ? cache_line_r[63:56] : 8'h0),
                                (ren_next[2] ? cache_line_r[55:48] : 8'h0),
                                (ren_next[1] ? cache_line_r[47:40] : 8'h0),
                                (ren_next[0] ? cache_line_r[39:32] : 8'h0)};
            2'b10: data_rdata = {(ren_next[3] ? cache_line_r[95:88] : 8'h0),
                                (ren_next[2] ? cache_line_r[87:80] : 8'h0),
                                (ren_next[1] ? cache_line_r[79:72] : 8'h0),
                                (ren_next[0] ? cache_line_r[71:64] : 8'h0)};
            2'b11: data_rdata = {(ren_next[3] ? cache_line_r[127:120] : 8'h0),
                                (ren_next[2] ? cache_line_r[119:112] : 8'h0),
                                (ren_next[1] ? cache_line_r[111:104] : 8'h0),
                                (ren_next[0] ? cache_line_r[103:96] : 8'h0)};
            default: data_rdata = 32'h0;
        endcase
end


    reg [133:0] cache_w;
    wire  cache_we = ((r_state == R_REFILL) && dev_rvalid) || write ;   /* TODO */;     // DCache�洢���дʹ���ź�
    wire [5:0] cache_index = data_addr[9:4];/* TODO */;     // �����ַ��Cache���� / DCache�洢��ĵ�ַ
    wire [133:0] cache_line_w = write? cache_w : {1'b1, data_addr[14:10], dev_rdata}; /* TODO */;     // ��д��DCache��Cache��
    wire [133:0] cache_line_r;                  // ��DCache������Cache��

    // DCache�洢�壺Block RAM IP��
    blk_mem_gen_1 U_dsram (
        .clka   (cpu_clk),
        .wea    (cache_we),
        .addra  (cache_index),
        .dina   (cache_line_w),
        .douta  (cache_line_r)
    );

    // TODO: ��дDCache��״̬����̬�ĸ����߼�
     always @(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst)
            r_state <= R_IDLE;
        else
            r_state <= r_next;
    end

    // TODO: ��д״̬����״̬ת���߼���ע�⴦��uncached���ʣ�
    always @(*) begin
        case(r_state)
            R_IDLE: begin
                if(|data_ren) 
                    r_next = R_TAG_CHK;
                else 
                    r_next = R_IDLE;
            end
            R_TAG_CHK: begin
                if (hit_r || uncached) 
                    r_next = R_IDLE;
                else begin
                    if(dev_rrdy) 
                        r_next = R_REFILL;
                    else 
                        r_next = R_TAG_CHK;
                end
            end
            R_REFILL: begin
                if(dev_rvalid) 
                    r_next = R_TAG_CHK;
                else 
                    r_next = R_REFILL;
            end 
        endcase
    end
reg [3:0] ren_next;
    // TODO: ����״̬��������ź�
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            data_valid <= 0;
        end
        else begin
            case(r_state)
                R_IDLE: begin
                    data_valid <= 0;
                    dev_ren <= 0;
                    ren_next <= data_ren;
                end
                R_TAG_CHK: begin
                    if(dev_rrdy && !hit_r) begin
                        dev_raddr = {data_addr[31:4], 4'b0};
                        dev_ren = ren_next;
                    end
                end
                R_REFILL: begin
                    dev_raddr <= 0;
                    dev_ren <= 4'b0;
                end
            endcase
        end    
    end

    ///////////////////////////////////////////////////////////
    // TODO: ����DCacheд״̬����״̬����
    parameter W_IDLE = 0;
    parameter W_TAG_CHK = 1;
    parameter W_REFILL = 2;
    parameter W_OVER = 3;
    reg [1:0] w_state, w_next;
    // TODO: ��дDCacheд״̬������̬�����߼�
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst)
            w_state <= W_IDLE;
        else
            w_state <= w_next;
    end

    // DCacheд״̬����״̬ת���߼�
    always @(*) begin
        case(w_state)
            W_IDLE: begin
                if(|data_wen) 
                    w_next = W_TAG_CHK;
                else 
                    w_next = W_IDLE;
            end
            W_TAG_CHK: begin
                if(dev_wrdy) 
                    w_next = W_REFILL;
                else 
                    w_next = W_TAG_CHK;
            end
            W_REFILL: begin
                w_next = W_OVER;
            end
            W_OVER:begin
                if(dev_wrdy) w_next = W_IDLE;
                else w_next = W_OVER;
            end 
          
        endcase
    end
reg [3:0] wen_next;
reg [31:0] data_next;
    // ����DCacheд״̬��������ź�
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            data_wresp <= 0;
            dev_wen <= 0;
            write <= 0;
        end
        else begin
            case(w_state)
                W_IDLE: begin
                    data_wresp <= 0;
                    write <= 0;
                    if(|data_wen) begin
                        wen_next <= data_wen;
                        data_next <= data_wdata;
                    end else
                        dev_wen <= 0;
                        
                end
                W_TAG_CHK: begin
                    if(dev_wrdy) begin
                        dev_waddr = data_addr;
                        dev_wen = wen_next;
                        if (dev_wen[0]) dev_wdata[7:0] = data_next[7:0];
                        if (dev_wen[1]) dev_wdata[15:8] = data_next[15:8];
                        if (dev_wen[2]) dev_wdata[23:16] = data_next[23:16];
                        if (dev_wen[3]) dev_wdata[31:24] = data_next[31:24];
                    end
                end
                W_REFILL: begin
                    
                    dev_waddr <= 0;
                    dev_wen <= 4'b0;
                    
                end
                W_OVER:begin
                    if(dev_wrdy)
                        data_wresp <= 1;
                        wen_next <= 0;
                end
            endcase
        end    
    end
    // TODO: д����ʱ��ֻ���޸�Cache���е�����һ���֡����ڴ�ʵ��֮��
reg write;
    always @(posedge cpu_clk) begin
    if (hit_w) begin
        cache_w = cache_line_r;
        case (offset)
            2'b00: begin
                if (dev_wen[0]) cache_w[7:0] = data_next[7:0];
                if (dev_wen[1]) cache_w[15:8] = data_next[15:8];
                if (dev_wen[2]) cache_w[23:16] = data_next[23:16];
                if (dev_wen[3]) cache_w[31:24] = data_next[31:24];
            end
            2'b01: begin
                if (dev_wen[0]) cache_w[39:32] = data_next[7:0];
                if (dev_wen[1]) cache_w[47:40] = data_next[15:8];
                if (dev_wen[2]) cache_w[55:48] = data_next[23:16];
                if (dev_wen[3]) cache_w[63:56] = data_next[31:24];
            end
            2'b10: begin
                if (dev_wen[0]) cache_w[71:64] = data_next[7:0];
                if (dev_wen[1]) cache_w[79:72] = data_next[15:8];
                if (dev_wen[2]) cache_w[87:80] = data_next[23:16];
                if (dev_wen[3]) cache_w[95:88] = data_next[31:24];
            end
            2'b11: begin
                if (dev_wen[0]) cache_w[103:96] = data_next[7:0];
                if (dev_wen[1]) cache_w[111:104] = data_next[15:8];
                if (dev_wen[2]) cache_w[119:112] = data_next[23:16];
                if (dev_wen[3]) cache_w[127:120] = data_next[31:24];
            end
        endcase
        write = 1;
    end
end


    /******** ��Ҫ�޸����´��� ********/
`else

    localparam R_IDLE  = 2'b00;
    localparam R_STAT0 = 2'b01;
    localparam R_STAT1 = 2'b11;
    reg [1:0] r_state, r_nstat;
    reg [3:0] ren_r;

    always @(posedge cpu_clk or posedge cpu_rst) begin
        r_state <= cpu_rst ? R_IDLE : r_nstat;
    end

    always @(*) begin
        case (r_state)
            R_IDLE:  r_nstat = (|data_ren) ? (dev_rrdy ? R_STAT1 : R_STAT0) : R_IDLE;
            R_STAT0: r_nstat = dev_rrdy ? R_STAT1 : R_STAT0;
            R_STAT1: r_nstat = dev_rvalid ? R_IDLE : R_STAT1;
            default: r_nstat = R_IDLE;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            data_valid <= 1'b0;
            dev_ren    <= 4'h0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    data_valid <= 1'b0;

                    if (|data_ren) begin
                        if (dev_rrdy)
                            dev_ren <= data_ren;
                        else
                            ren_r   <= data_ren;

                        dev_raddr <= data_addr;
                    end else
                        dev_ren   <= 4'h0;
                end
                R_STAT0: begin
                    dev_ren    <= dev_rrdy ? ren_r : 4'h0;
                end   
                R_STAT1: begin
                    dev_ren    <= 4'h0;
                    data_valid <= dev_rvalid ? 1'b1 : 1'b0;
                    data_rdata <= dev_rvalid ? dev_rdata : 32'h0;
                end
                default: begin
                    data_valid <= 1'b0;
                    dev_ren    <= 4'h0;
                end 
            endcase
        end
    end

    localparam W_IDLE  = 2'b00;
    localparam W_STAT0 = 2'b01;
    localparam W_STAT1 = 2'b11;
    reg  [1:0] w_state, w_nstat;
    reg  [3:0] wen_r;
    wire       wr_resp = dev_wrdy & (dev_wen == 4'h0) ? 1'b1 : 1'b0;

    always @(posedge cpu_clk or posedge cpu_rst) begin
        w_state <= cpu_rst ? W_IDLE : w_nstat;
    end

    always @(*) begin
        case (w_state)
            W_IDLE:  w_nstat = (|data_wen) ? (dev_wrdy ? W_STAT1 : W_STAT0) : W_IDLE;
            W_STAT0: w_nstat = dev_wrdy ? W_STAT1 : W_STAT0;
            W_STAT1: w_nstat = wr_resp ? W_IDLE : W_STAT1;
            default: w_nstat = W_IDLE;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            data_wresp <= 1'b0;
            dev_wen    <= 4'h0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    data_wresp <= 1'b0;

                    if (|data_wen) begin
                        if (dev_wrdy)
                            dev_wen <= data_wen;
                        else
                            wen_r   <= data_wen;

                        dev_waddr  <= data_addr;
                        dev_wdata  <= data_wdata;
                    end else
                        dev_wen    <= 4'h0;
                end
                W_STAT0: begin
                    dev_wen    <= dev_wrdy ? wen_r : 4'h0;
                end
                W_STAT1: begin
                    dev_wen    <= 4'h0;
                    data_wresp <= wr_resp ? 1'b1 : 1'b0;
                end
                default: begin
                    data_wresp <= 1'b0;
                    dev_wen    <= 4'h0;
                end
            endcase
        end
    end

`endif

endmodule
