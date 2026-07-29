module register_file #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 8
)(
    input wire PCLK,
    input wire PRESETn, 
    input wire wr_en, 
    input wire rd_en, 
    input wire [ADDR_WIDTH-1:0] addr, 
    input wire [DATA_WIDTH-1:0] wdata,
    output reg  [DATA_WIDTH-1:0] rdata
);
 
    localparam SEL_WIDTH = $clog2(NUM_REGS);
    reg [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];
    wire [SEL_WIDTH-1:0] reg_sel = addr[SEL_WIDTH+1:2];
    integer i;
    
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            for (i = 0; i < NUM_REGS; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else if (wr_en) begin
            regs[reg_sel] <= wdata;
        end
    end
 
    always @(*) begin
        if (rd_en)
            rdata = regs[reg_sel];
        else
            rdata = {DATA_WIDTH{1'b0}};
    end
 
endmodule
 