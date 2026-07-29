`timescale 1ns/1ps
 
module apb_tb;
 
    parameter ADDR_WIDTH  = 8;
    parameter DATA_WIDTH  = 32;
    parameter WAIT_CYCLES = 2;
    reg PCLK;
    reg PRESETn;
    reg PSEL;
    reg PENABLE;
    reg PWRITE;
    reg  [ADDR_WIDTH-1:0] PADDR;
    reg  [DATA_WIDTH-1:0] PWDATA;
    wire [DATA_WIDTH-1:0] PRDATA;
    wire PREADY;
    wire PSLVERR;
    integer errors = 0;
 
    apb_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS(8),
        .WAIT_ADDR_THRESH(8'h10),
        .WAIT_CYCLES(WAIT_CYCLES)
    ) dut (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PADDR   (PADDR),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR)
    );
    always #5 PCLK = ~PCLK;
    task apb_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data,
                    output integer wait_cycles_seen);
        begin
            wait_cycles_seen = 0;
            @(posedge PCLK); #1;
            PSEL    = 1'b1;
            PENABLE = 1'b0;
            PWRITE  = 1'b1;
            PADDR   = addr;
            PWDATA  = data;
            @(posedge PCLK); #1;
            PENABLE = 1'b1;
            @(posedge PCLK); #1;
            while (!PREADY) begin
                wait_cycles_seen = wait_cycles_seen + 1;
                @(posedge PCLK); #1;
            end
            PSEL    = 1'b0;
            PENABLE = 1'b0;
        end
    endtask

    task apb_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data,
                   output integer wait_cycles_seen);
        begin
            wait_cycles_seen = 0;
            @(posedge PCLK); #1;
            PSEL    = 1'b1;
            PENABLE = 1'b0;
            PWRITE  = 1'b0;
            PADDR   = addr;
            @(posedge PCLK); #1;
            PENABLE = 1'b1;
            @(posedge PCLK); #1;
            while (!PREADY) begin
                wait_cycles_seen = wait_cycles_seen + 1;
                @(posedge PCLK); #1;
            end
            data = PRDATA;
            PSEL    = 1'b0;
            PENABLE = 1'b0;
        end
    endtask
 
    reg [DATA_WIDTH-1:0] rdata;
    integer wcyc;
 
    initial begin
        PCLK    = 0;
        PRESETn = 0;
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;
 
        repeat (3) @(posedge PCLK);
        PRESETn = 1;
 
        apb_write(8'h00, 32'hDEAD_BEEF, wcyc);
        $display("WRITE  addr=00 wait_cycles=%0d (expect 0)", wcyc);
        if (wcyc !== 0) begin errors = errors + 1; $display("  -> FAIL: unexpected wait state"); end
 
        apb_read(8'h00, rdata, wcyc);
        $display("READ   addr=00 data=%h wait_cycles=%0d (expect 0)", rdata, wcyc);
        check(8'h00, rdata, 32'hDEAD_BEEF);
        if (wcyc !== 0) begin errors = errors + 1; $display("  -> FAIL: unexpected wait state"); end
 
        apb_write(8'h10, 32'hCAFE_BABE, wcyc);
        $display("WRITE  addr=10 wait_cycles=%0d (expect %0d)", wcyc, WAIT_CYCLES);
        if (wcyc !== WAIT_CYCLES) begin
            errors = errors + 1;
            $display("  -> FAIL: expected %0d wait states", WAIT_CYCLES);
        end
 
        apb_read(8'h10, rdata, wcyc);
        $display("READ   addr=10 data=%h wait_cycles=%0d (expect %0d)", rdata, wcyc, WAIT_CYCLES);
        check(8'h10, rdata, 32'hCAFE_BABE);
        if (wcyc !== WAIT_CYCLES) begin
            errors = errors + 1;
            $display("  -> FAIL: expected %0d wait states", WAIT_CYCLES);
        end
 
        if (errors == 0)
            $display("APB_TB: ALL TESTS PASSED");
        else
            $display("APB_TB: %0d TEST(S) FAILED", errors);
 
        $finish;
    end
 
    task check(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] got, input [DATA_WIDTH-1:0] exp);
        begin
            if (got !== exp) begin
                $display("  -> MISMATCH addr=%0h got=%h exp=%h", addr, got, exp);
                errors = errors + 1;
            end
        end
    endtask
 
endmodule