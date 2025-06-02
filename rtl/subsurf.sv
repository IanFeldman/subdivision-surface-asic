`timescale 1ns/1ps
`define ADDR_WIDTH 11

/* top module */
module subsurf
(
    input clk, start,
    input [31:0] do0, do1, do2,
    output logic en0, en1, en2,
    output logic [(`ADDR_WIDTH-1):0] a0, a1, a2,
    output logic [3:0] we0, we1, we2,
    output logic [31:0] di0, di1, di2,
    output logic busy
);

logic [31:0] vertex_count, face_count;
logic subdiv_start, neighbor_start, averager_start;
logic subdiv_busy, neighbor_busy, averager_busy;

/* subdiv RAM signals */
logic en0_s, en1_s, en2_s;
logic [(`ADDR_WIDTH-1):0] a0_s, a1_s, a2_s;
logic [3:0] we0_s, we1_s, we2_s;
logic [31:0] di0_s, di1_s, di2_s;

/* neighbor RAM signals */
logic en0_n, en1_n;
logic [(`ADDR_WIDTH-1):0] a0_n, a1_n;
logic [3:0] we0_n, we1_n;
logic [31:0] di0_n, di1_n;

/* averager RAM signals */
logic en0_a, en1_a, en2_a;
logic [(`ADDR_WIDTH-1):0] a0_a, a1_a, a2_a;
logic [3:0] we0_a, we1_a, we2_a;
logic [31:0] di0_a, di1_a, di2_a;

/* control signals */
logic [1:0] i;
enum {NONE, SUBDIV, NEIGHBOR, AVERAGER} in_use;

/* debug state - simulation only */
`ifndef OPENLANE
logic [63:0] state_string;
always_comb begin
    case (in_use)
        NONE:       state_string = "NONE    ";
        SUBDIV:     state_string = "SUBDIV  ";
        NEIGHBOR:   state_string = "NEIGHBOR";
        AVERAGER:   state_string = "AVERAGER";
        default:    state_string = "UNKNOWN ";
    endcase
end
`endif

/* instantiate modules */

/* OBJ: 0, RES: 1, MAP: 2 */
subdiv sbdv (
    .clk(clk),
    .start(subdiv_start),
    .RAM0_Do(do0),
    .RAM2_Do(do2),
    .RAM0_EN(en0_s),
    .RAM1_EN(en1_s),
    .RAM2_EN(en2_s),
    .RAM0_A(a0_s),
    .RAM1_A(a1_s),
    .RAM2_A(a2_s),
    .RAM0_WE(we0_s),
    .RAM1_WE(we1_s),
    .RAM2_WE(we2_s),
    .RAM0_Di(di0_s),
    .RAM1_Di(di1_s),
    .RAM2_Di(di2_s),
    .busy(subdiv_busy),
    .new_vertex_count(vertex_count),
    .new_face_count(face_count)
);

/* OBJ: 1, NBR: 0 */
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

/* OBJ: 1, RES: 2, NBR: 0 */
averager avgr(
    .clk(clk),
    .start(averager_start),
    .vertex_count(vertex_count),
    .face_count(face_count),
    .RAM_OBJ_Do(do1),
    .RAM_NBR_Do(do0),
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
        NEIGHBOR: begin
            en0 = en0_n;
            en1 = en1_n;
            en2 = 1'b0;
            a0 = a0_n;
            a1 = a1_n;
            a2 = `ADDR_WIDTH'b0;
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
            en0 = 1'b0;
            en1 = 1'b0;
            en2 = 1'b0;
            a0 = `ADDR_WIDTH'b0;
            a1 = `ADDR_WIDTH'b0;
            a2 = `ADDR_WIDTH'b0;
            we0 = 4'b0;
            we1 = 4'b0;
            we2 = 4'b0;
            di0 = 32'b0;
            di1 = 32'b0;
            di2 = 32'b0;
        end
    endcase
end

always_ff @(posedge clk) begin
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
                if (averager_busy == 1'b0) begin
                    in_use <= NONE;
                    busy <= 0;
                end
            end
        end
    endcase
end

endmodule

