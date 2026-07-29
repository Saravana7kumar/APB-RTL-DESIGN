module apb_top #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS = 8,
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
    output wire [DATA_WIDTH-1:0] PRDATA,
    output wire PREADY,
    output wire PSLVERR
);
 
    wire wr_en, rd_en;
    wire [ADDR_WIDTH-1:0]  mem_addr;
    wire [DATA_WIDTH-1:0]  mem_wdata;
    wire [DATA_WIDTH-1:0]  mem_rdata;
 
    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .WAIT_ADDR_THRESH(WAIT_ADDR_THRESH),
        .WAIT_CYCLES(WAIT_CYCLES)
    ) u_apb_slave (
        .PCLK (PCLK),
        .PRESETn (PRESETn),
        .PSEL (PSEL),
        .PENABLE (PENABLE),
        .PWRITE (PWRITE),
        .PADDR (PADDR),
        .PWDATA (PWDATA),
        .PRDATA (PRDATA),
        .PREADY (PREADY),
        .PSLVERR (PSLVERR),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .mem_addr (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_rdata (mem_rdata)
    );
 
    register_file #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS  (NUM_REGS)
    ) u_register_file (
        .PCLK (PCLK),
        .PRESETn (PRESETn),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .addr (mem_addr),
        .wdata (mem_wdata),
        .rdata (mem_rdata)
    );
 
endmodule