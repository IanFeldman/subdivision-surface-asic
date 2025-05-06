`timescale 1ns/1ps

module averager #(parameter MAX_NEIGHBOR_COUNT=10)
(
    input clk, start,
    input [31:0] vertex_count, face_count,
    input [31:0] RAM_OBJ_Do, RAM_NBR_Do, RAM_AVG_Do,
    output logic RAM_OBJ_EN, RAM_NBR_EN, RAM_AVG_EN,
    output logic [8:0] RAM_OBJ_A, RAM_NBR_A, RAM_AVG_A,
    output logic [3:0] RAM_OBJ_WE, RAM_NBR_WE, RAM_AVG_WE,
    output logic [31:0] RAM_OBJ_Di, RAM_NBR_Di, RAM_AVG_Di,
    output logic busy
);

logic [31:0] vertex_a, vertex_b, vertex_c;
logic [1:0] i;

enum {IDLE, READ_FACE} state = IDLE;

always_ff@(posedge clk) begin
    case (state)
        IDLE: begin
            /* init various signals */
            busy <= 1'b0;
            i = 2'b0;
            /* init object ram signals */
            RAM_OBJ_Di <= 32'b0;
            RAM_OBJ_EN <= 1'b1;
            RAM_OBJ_WE <= 4'b0;
            RAM_OBJ_A = 9'b0;
            /* init neighbor ram signals */
            RAM_NBR_Di <= 32'b0;
            RAM_NBR_EN <= 1'b1;
            RAM_NBR_WE <= 4'b0;
            RAM_NBR_A = 9'b0;
            /* update state */
            if (start == 1'b1) begin
                busy <= 1'b1;
                RAM_OBJ_A = 2 + vertex_count[8:0] * 3;
                state <= READ_FACE;
            end
        end
        READ_FACE: begin
            if (i == 2'b00)
                vertex_a <= RAM_OBJ_Do;
            else if (i == 2'b01)
                vertex_b <= RAM_OBJ_Do;
            else if (i == 2'b10) begin
                vertex_c = RAM_OBJ_Do;
                i = 2'b11;
            end
            RAM_OBJ_A = RAM_OBJ_A + 1;
            i = i + 1;
        end
        default: begin
        end
    endcase
end

endmodule

