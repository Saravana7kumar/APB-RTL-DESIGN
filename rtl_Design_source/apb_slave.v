module apb_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter WAIT_ADDR_THRESH = 8'h10,
    parameter WAIT_CYCLES = 2  
)(
    input wire PCLK,
    input wire PRESETn,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [ADDR_WIDTH-1:0] PADDR,
    input wire [DATA_WIDTH-1:0] PWDATA,
    output reg [DATA_WIDTH-1:0] PRDATA,
    output reg PREADY,
    output reg PSLVERR,
    output reg wr_en,
    output reg  rd_en,
    output wire [ADDR_WIDTH-1:0] mem_addr,
    output wire [DATA_WIDTH-1:0] mem_wdata,
    input  wire [DATA_WIDTH-1:0] mem_rdata
);

    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;
 
    reg [1:0] state, next_state;
    reg [3:0] wait_cnt;
    wire slow_access = (PADDR >= WAIT_ADDR_THRESH);
    assign mem_addr  = PADDR;
    assign mem_wdata = PWDATA;
 
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            wait_cnt <= 4'd0;
        end else if (state == SETUP) begin
            wait_cnt <= slow_access ? WAIT_CYCLES[3:0] : 4'd0;
        end else if (state == ACCESS && wait_cnt != 4'd0) begin
            wait_cnt <= wait_cnt - 4'd1;
        end
    end

    always @(*) begin
        case (state)
            IDLE:    next_state = PSEL ? SETUP : IDLE;
            SETUP:   next_state = (PSEL && PENABLE) ? ACCESS : IDLE;
            ACCESS:  next_state = (wait_cnt == 4'd0) ? IDLE : ACCESS;
            default: next_state = IDLE;
        endcase
    end

    always @(*) begin
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        PREADY  = 1'b0;
        PSLVERR = 1'b0;
        PRDATA  = {DATA_WIDTH{1'b0}};
 
        case (state)
            SETUP: begin
                rd_en  = !PWRITE;
            end
 
            ACCESS: begin
                PREADY = (wait_cnt == 4'd0);
                if (PWRITE) begin
                    wr_en = PREADY; 
                end else begin
                    rd_en  = 1'b1;
                    PRDATA = mem_rdata;
                end
                PSLVERR = (PADDR > 8'h1F);
            end
 
            default: ;
        endcase
    end
 
endmodule