module soc_top (
    input  logic clk, //clock signal thats driving CPU and RAM
    input  logic resetn //active low reset (0 -> resets picoRV32, 1 -> lets it run)
);

    // ----------------------------
    // PicoRV32 memory interface (mem. bus signals)
    // ----------------------------
    logic        mem_valid; //CPU->memory (cpu is now requesting a memory access)
    logic        mem_ready; //memory->CPU (cpu request is complete / data is valid)
    logic [31:0] mem_addr; //CPU->memory (address is being accessed)
    logic [31:0] mem_wdata; //CPU->memory (data to write for stores)
    logic [3:0]  mem_wstrb; //CPU->memory (if its 0, its a read. if its 1, its a write. mem_wstrb[0] writes bits 0 to 7. mem_wstrb[1] writes bits 8 to 15 and so on)
    logic [31:0] mem_rdata; //memory->CPU (data returned for reads)

    // ----------------------------
    // PicoRV32 instance
    // ----------------------------
    picorv32 #(
        .PROGADDR_RESET(32'h0000_0000), //after reset, program counter (PC) starts fetching instructions at addr 0x0000_0000
        .STACKADDR     (32'h0000_8000) //initial stack pointer target
    ) cpu (
        //Next 8 lines are to hook CPU memory bus to the signals above
        .clk        (clk),
        .resetn     (resetn),
        .mem_valid  (mem_valid),
        .mem_ready  (mem_ready),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (mem_rdata),
        .irq        (32'b0) //means no interrupts. CPU will never take an IRQ.
    );

    // ----------------------------
    // Simple 64 KB RAM
    // ----------------------------
    localparam RAM_WORDS = 16384; //the RAM is word-addressed 32-bit words. (16384 * 4 bytes/word = 65536 = 64kB)
    logic [31:0] ram [0:RAM_WORDS-1]; //ram[0] corresponds to byte address 0x0000_0000. ram[1] corresponds to byte address 0x0000_0004, etc.

    initial begin //'initial' runs once at program start
        $readmemh("out/prog.hex", ram); //loads compiled program into RAM before the CPU runs
        $display("Loaded out/prog.hex, ram[0]=%08x ram[1]=%08x", ram[0], ram[1]); //prints value of ram[0] to see if the program was loaded into ram
    end

    wire ram_access = mem_valid && (mem_addr < 32'h0001_0000); //means CPU is requesting an address in the first 64kB(0x0001_0000). so anything less than 0x0001_0000 maps to ram.
    wire [13:0] ram_addr = mem_addr[15:2]; //drops the bottom 2 bits as those are byte offsets inside a 32-bit word. mem_addr = 0x0000_0008(1000 in binary) becomes ram_addr = 0x0000_0002 (10 in binary).

    wire exit_access = mem_valid && (mem_addr == 32'h2000_0000); // a single 'magic register' at 0x2000_0000. the test program writes here to end the sim.


    // ----------------------------
    // Memory / MMIO handling (sync style)
    //   - mem_ready asserted 1 cycle after mem_valid (posedge)
    //   - writes commit on posedge
    //   - reads sampled on negedge (data valid before next posedge)
    // ----------------------------

    // 1) Handshake: 1-cycle latency memory
    always_ff @(posedge clk) begin
        if (!resetn) begin
            mem_ready <= 1'b0;
        end else begin
            mem_ready <= mem_valid;
        end
    end

    // 2) WRITE + exit MMIO on posedge
    always_ff @(posedge clk) begin
        if (!resetn) begin
            // nothing required
        end else begin
            // RAM writes
            if (mem_valid && |mem_wstrb && ram_access) begin
                if (mem_wstrb[0]) ram[ram_addr][ 7: 0] <= mem_wdata[ 7: 0];
                if (mem_wstrb[1]) ram[ram_addr][15: 8] <= mem_wdata[15: 8];
                if (mem_wstrb[2]) ram[ram_addr][23:16] <= mem_wdata[23:16];
                if (mem_wstrb[3]) ram[ram_addr][31:24] <= mem_wdata[31:24];
            end

            // EXIT MMIO write
            if (mem_valid && |mem_wstrb && exit_access) begin
                $display("TEST_EXIT: code=0x%08x", mem_wdata);
                if (mem_wdata == 32'h2) begin
                    $display("PASS");
                    $finish;
                end else begin
                    $display("FAIL");
                    $finish;
                end
            end
        end
    end

    // 3) READ on negedge
    always_ff @(negedge clk) begin
        if (!resetn) begin
            mem_rdata <= 32'h0;
        end else if (mem_valid && !|mem_wstrb) begin
            if (ram_access) begin
                mem_rdata <= ram[ram_addr];
            end else begin
                // exit/unmapped reads return 0
                mem_rdata <= 32'h0;
            end
        end
    end



endmodule
