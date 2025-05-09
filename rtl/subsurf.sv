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
logic subdiv_start, copy_start, neighbor_start, averager_start;
logic subdiv_busy, copy_busy, neighbor_busy, averager_busy;

/* subdiv RAM signals */
logic en0_s, en1_s, en2_s;
logic [8:0] a0_s, a1_s, a2_s;
logic [3:0] we0_s, we1_s, we2_s;
logic [31:0] di0_s, di1_s, di2_s;

/* copy RAM signals */
logic enX_c, enY_c;
logic [8:0] aX_c, aY_c;
logic [3:0] weX_c, weY_c;
logic [31:0] diY_c, doX_c;

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
enum {NONE, SUBDIV, COPY, NEIGHBOR, AVERAGER} in_use = NONE;

/* debug state - simulation only */
`ifndef SYNTHESIS
logic [63:0] state_string;
always_comb begin
    case (in_use)
        NONE:       state_string = "NONE    ";
        SUBDIV:     state_string = "SUBDIV  ";
        COPY:       state_string = "COPY    ";
        NEIGHBOR:   state_string = "NEIGHBOR";
        AVERAGER:   state_string = "AVERAGER";
        default:    state_string = "UNKNOWN ";
    endcase
end
`endif

/* instantiate modules */
subdiv sbdv (
    .clk(clk),
    .start(subdiv_start),
    .RAM1_Do(do0),
    .RAM2_Do(do1),
    .RAM3_Do(do2),
    .RAM1_EN(en0_s),
    .RAM2_EN(en1_s),
    .RAM3_EN(en2_s),
    .RAM1_A(a0_s),
    .RAM2_A(a1_s),
    .RAM3_A(a2_s),
    .RAM1_WE(we0_s),
    .RAM2_WE(we1_s),
    .RAM3_WE(we2_s),
    .RAM1_Di(di0_s),
    .RAM2_Di(di1_s),
    .RAM3_Di(di2_s),
    .busy(subdiv_busy),
    .new_vertex_count(vertex_count),
    .new_face_count(face_count)
);

copy cpy(
    .clk(clk),
    .start(copy_start),
    .RAM_X_Do(doX_c),
    .RAM_X_EN(enX_c),
    .RAM_Y_EN(enY_c),
    .RAM_X_A(aX_c),
    .RAM_Y_A(aY_c),
    .RAM_X_WE(weX_c),
    .RAM_Y_WE(weY_c),
    .RAM_Y_Di(diY_c),
    .busy(copy_busy)
);

neighbor nbr(
    .clk(clk),
    .start(neighbor_start),
    .vertex_count(vertex_count),
    .face_count(face_count),
    .RAM_OBJ_Do(do1),
    .RAM_NBR_Do(do0),
    .RAM_OBJ_EN(en1_n),
    .RAM_NBR_EN(en0_n),
    .RAM_OBJ_A(a1_n),
    .RAM_NBR_A(a0_n),
    .RAM_OBJ_WE(we1_n),
    .RAM_NBR_WE(we0_n),
    .RAM_OBJ_Di(di1_n),
    .RAM_NBR_Di(di0_n),
    .busy(neighbor_busy)
);

averager avgr(
    .clk(clk),
    .start(averager_start),
    .vertex_count(vertex_count),
    .face_count(face_count),
    .RAM_OBJ_Do(do1),
    .RAM_NBR_Do(do0),
    .RAM_RES_Do(do2),
    .RAM_OBJ_EN(en1_a),
    .RAM_NBR_EN(en0_a),
    .RAM_RES_EN(en2_a),
    .RAM_OBJ_A(a1_a),
    .RAM_NBR_A(a0_a),
    .RAM_RES_A(a2_a),
    .RAM_OBJ_WE(we1_a),
    .RAM_NBR_WE(we0_a),
    .RAM_RES_WE(we2_a),
    .RAM_OBJ_Di(di1_a),
    .RAM_NBR_Di(di0_a),
    .RAM_RES_Di(di2_a),
    .busy(averager_busy)
);

/* assign RAM signals */
always_comb begin
    case (in_use)
        SUBDIV: begin
            doX_c = 32'b0;
            en0 = en0_s;
            en1 = en1_s;
            en2 = en2_s;
            a0 = a0_s;
            a1 = a1_s;
            a2 = a2_s;
            we0 = we0_s;
            we1 = we1_s;
            we2 = we2_s;
            di0 = di0_s;
            di1 = di1_s;
            di2 = di2_s;
        end
        COPY: begin /* copy ram1 to ram2 */
            doX_c = do1;
            en0 = 1'b0;
            en1 = enX_c;
            en2 = enY_c;
            a0 = 9'b0;
            a1 = aX_c;
            a2 = aY_c;
            we0 = 4'b0;
            we1 = weX_c;
            we2 = weY_c;
            di0 = 32'b0;
            di1 = 32'b0;
            di2 = diY_c;
        end
        NEIGHBOR: begin
            doX_c = 32'b0;
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
            doX_c = 32'b0;
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
            doX_c = 32'b0;
            en0 = 1'b0;
            en1 = 1'b0;
            en2 = 1'b0;
            a0 = 9'b0;
            a1 = 9'b0;
            a2 = 9'b0;
            we0 = 4'b0;
            we1 = 4'b0;
            we2 = 4'b0;
            di0 = 32'b0;
            di1 = 32'b0;
            di2 = 32'b0;
        end
    endcase
end

always_ff@(posedge clk) begin
    case (in_use)
        NONE: begin
            if (start == 1'b1) begin
                i <= 2'b00;
                busy <= 1'b1;
                in_use <= SUBDIV;
            end
        end
        SUBDIV: begin
            if (i == 2'b00) begin
                subdiv_start <= 1'b1;
                i <= i + 1;
            end
            else if (i == 2'b01)
                i <= i + 1;
            else if (i == 2'b10) begin
                subdiv_start <= 1'b0;
                i <= i + 1;
            end
            else if (i == 2'b11) begin
                if (subdiv_busy == 1'b0) begin
                    i <= 2'b00;
                    in_use <= COPY;
                end
            end
        end
        COPY: begin
            if (i == 2'b00) begin
                copy_start <= 1'b1;
                i <= i + 1;
            end
            else if (i == 2'b01)
                i <= i + 1;
            else if (i == 2'b10) begin
                copy_start <= 1'b0;
                i <= i + 1;
            end
            else if (i == 2'b11) begin
                if (copy_busy == 1'b0) begin
                    i <= 2'b00;
                    in_use <= NEIGHBOR;
                end
            end
        end
        NEIGHBOR: begin
            if (i == 2'b00) begin
                neighbor_start <= 1'b1;
                i <= i + 1;
            end
            else if (i == 2'b01)
                i <= i + 1;
            else if (i == 2'b10) begin
                neighbor_start <= 1'b0;
                i <= i + 1;
            end
            else if (i == 2'b11) begin
                if (neighbor_busy == 1'b0) begin
                    i <= 2'b00;
                    in_use <= AVERAGER;
                end
            end
        end
        AVERAGER: begin
            if (i == 2'b00) begin
                averager_start <= 1'b1;
                i <= i + 1;
            end
            else if (i == 2'b01)
                i <= i + 1;
            else if (i == 2'b10) begin
                averager_start <= 1'b0;
                i <= i + 1;
            end
            else if (i == 2'b11) begin
                if (averager_busy == 1'b0)
                    in_use <= NONE;
            end
        end
    endcase
end

endmodule

