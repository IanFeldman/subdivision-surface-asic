`timescale 1ns/1ps
`define ADDR_WIDTH 9

/* copies contents of RAM_X into RAM_Y */
module copy
(
    input clk, start,
    input [31:0] RAM_X_Do,
    output logic RAM_X_EN, RAM_Y_EN,
    output logic [(`ADDR_WIDTH - 1):0] RAM_X_A, RAM_Y_A,
    output logic [3:0] RAM_X_WE, RAM_Y_WE,
    output logic [31:0] RAM_Y_Di,
    output logic busy
);

enum {IDLE, BUSY} state = IDLE;
logic started;
logic [(`ADDR_WIDTH - 1):0] address;

always_ff@(negedge clk) begin
    case (state)
        IDLE: begin
            if (start == 1'b1) begin
                busy <= 1'b1;
                state <= BUSY;
                RAM_X_EN <= 1'b1;
                RAM_Y_EN <= 1'b1;
                RAM_X_WE <= 4'b0;
                RAM_Y_WE <= 4'b0;
                RAM_X_A <= `ADDR_WIDTH'b0;
                RAM_X_A <= `ADDR_WIDTH'b0;
                address <= `ADDR_WIDTH'b0;
                started <= 1'b0;
            end
        end
        BUSY: begin
            started <= 1'b1;
            RAM_Y_WE <= 4'b1111;
            RAM_Y_Di <= RAM_X_Do;
            RAM_X_A <= RAM_X_A + 1;
            address <= address + 1;
            RAM_Y_A <= address;
            if (started == 1'b1 && address == `ADDR_WIDTH'b0) begin
                state <= IDLE;
                busy <= 1'b0;
            end
        end
    endcase
end

endmodule

