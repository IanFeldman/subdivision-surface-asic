`timescale 1ns/1ps

/* top module */
module subsurf
(
    input clk, start,
    input [31:0] do0, do1, do2,
    output logic en0, en1, en2,
    output logic [8:0] a0, a1, a2,
    output logic [3:0] we0, we1, we2,
    output logic [31:0] di0, di1, di2,
    output logic busy
);

logic [31:0] vertex_count, face_count;
logic neighbor_start, averager_start;
logic neighbor_busy, averager_busy;

/* neighbor RAM signals */
logic en0_n, en1_n;
logic [8:0] a0_n, a1_n;
logic [3:0] we0_n, we1_n;
logic [31:0] di0_n, di1_n;

/* averager RAM signals */
logic en0_a, en1_a, en2_a;
logic [8:0] a0_a, a1_a, a2_a;
logic [3:0] we0_a, we1_a, we2_a;
logic [31:0] di0_a, di1_a, di2_a;

/* control signals */
logic [1:0] i;
enum {IDLE, NEIGHBOR, AVERAGER} in_use = IDLE;

neighbor nbr(
    .clk(clk),
    .start(neighbor_start),
    .vertex_count(vertex_count),
    .face_count(face_count),
    .RAM_OBJ_Do(do0),
    .RAM_NBR_Do(do1),
    .RAM_OBJ_EN(en0_n),
    .RAM_NBR_EN(en1_n),
    .RAM_OBJ_A(a0_n),
    .RAM_NBR_A(a1_n),
    .RAM_OBJ_WE(we0_n),
    .RAM_NBR_WE(we1_n),
    .RAM_OBJ_Di(di0_n),
    .RAM_NBR_Di(di1_n),
    .busy(neighbor_busy)
);

averager avgr(
    .clk(clk),
    .start(averager_start),
    .vertex_count(vertex_count),
    .face_count(face_count),
    .RAM_OBJ_Do(do0),
    .RAM_NBR_Do(do1),
    .RAM_RES_Do(do2),
    .RAM_OBJ_EN(en0_a),
    .RAM_NBR_EN(en1_a),
    .RAM_RES_EN(en2_a),
    .RAM_OBJ_A(a0_a),
    .RAM_NBR_A(a1_a),
    .RAM_RES_A(a2_a),
    .RAM_OBJ_WE(we0_a),
    .RAM_NBR_WE(we1_a),
    .RAM_RES_WE(we2_a),
    .RAM_OBJ_Di(di0_a),
    .RAM_NBR_Di(di1_a),
    .RAM_RES_Di(di2_a),
    .busy(averager_busy)
);

/* for testing */
initial begin
    vertex_count = 12;
    face_count = 20;
end

always_comb begin
    case (in_use)
        NEIGHBOR: begin
            en0 = en0_n;
            en1 = en1_n;
            en2 = 1'b0;
            a0 = a0_n;
            a1 = a1_n;
            a2 = 9'b0;
            we0 = we0_n;
            we1 = we1_n;
            we2 = 4'b0;
            di0 = di0_n;
            di1 = di1_n;
            di2 = 32'b0;
        end
        AVERAGER: begin
            en0 = en0_a;
            en1 = en1_a;
            en2 = en2_a;
            a0 = a0_a;
            a1 = a1_a;
            a2 = a2_a;
            we0 = we0_a;
            we1 = we1_a;
            we2 = we2_a;
            di0 = di0_a;
            di1 = di1_a;
            di2 = di2_a;
        end
        default: begin
        end
    endcase
end

always_ff@(posedge clk) begin
    case (in_use)
        IDLE: begin
            if (start == 1'b1) begin
                i <= 2'b00;
                busy <= 1'b1;
                in_use <= NEIGHBOR;
            end
        end
        NEIGHBOR: begin
            if (i == 2'b00) begin
                neighbor_start <= 1'b1;
                i <= i + 1;
            end
            if (i == 2'b01)
                i <= i + 1;
            else if (i == 2'b10) begin
                neighbor_start <= 1'b0;
                i <= i + 1;
            end
            else if (i == 2'b11) begin
                if (neighbor_busy == 1'b0)
                    in_use <= AVERAGER;
            end
        end
        AVERAGER: begin
        end
    endcase
end

endmodule

