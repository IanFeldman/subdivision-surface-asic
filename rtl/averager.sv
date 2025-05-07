`timescale 1ns/1ps
`define ADDR_WIDTH 9
`define Q_ONE 32'h00010000

module averager #(parameter MAX_NEIGHBOR_COUNT=10)
(
    input clk, start,
    input [31:0] vertex_count, face_count,
    input signed [31:0] RAM_OBJ_Do, RAM_NBR_Do, RAM_RES_Do,
    output logic RAM_OBJ_EN, RAM_NBR_EN, RAM_RES_EN,
    output logic [(`ADDR_WIDTH - 1):0] RAM_OBJ_A, RAM_NBR_A, RAM_RES_A,
    output logic [3:0] RAM_OBJ_WE, RAM_NBR_WE, RAM_RES_WE,
    output logic [31:0] RAM_OBJ_Di, RAM_NBR_Di, RAM_RES_Di,
    output logic busy
);

/* assume that RAM_OBJ = RAM_RES at the start */

logic [31:0] curr_vertex, neighbor_count, neighbors_read;
logic signed [31:0] sum_x, sum_y, sum_z;
logic signed [31:0] neighbor_count_q;
logic [1:0] i;
assign neighbor_count_q = neighbor_count << 16;

enum {IDLE, GET_NEIGHBOR, READ_NEIGHBOR_VERTEX,
      READ_CURR_VERTEX, WRITE_CURR_VERTEX, DONE} state = IDLE;

`ifndef SYNTHESIS
logic [63:0] state_string;
always_comb begin
    case (state)
        IDLE:                   state_string = "IDLE    ";
        GET_NEIGHBOR:           state_string = "GET_NBR ";
        READ_NEIGHBOR_VERTEX:   state_string = "RD_NBR_V";
        READ_CURR_VERTEX:       state_string = "RD_CUR_V";
        WRITE_CURR_VERTEX:      state_string = "WR_CUR_V";
        DONE:                   state_string = "DONE    ";
        default:                state_string = "UNKNOWN ";
    endcase
end
`endif

/* 
 * Wait for start to go high
 * Initialize all signals
 * 
 * For each vert, v, in neighbor ram
 *    Read in neighbor count, c
 *    For each neighbor, n, in neighbors
 *       Add n.x / B into sum_x, n.y / B into sum_y, n.z / B into sum_z
 *    Add v.x(1 - cB) into sum_x, v.y(1 - cB) into sum_y, v.z(1 - cB) into sum_z
 *    Save sum_x, sum_y, sum_z into result ram
 */

always_ff@(negedge clk) begin
    case (state)
        IDLE: begin
            busy <= 1'b0;
            /* update state */
            if (start == 1'b1) begin
                /* init various signals */
                i = 2'b0;
                curr_vertex = 32'b0; /* idx of curr vert, 0 -> (vertex_count - 1) */
                neighbor_count = 32'b0;
                neighbors_read = 32'b0;
                sum_x <= 32'b0;
                sum_y <= 32'b0;
                sum_z <= 32'b0;
                /* init object ram signals */
                RAM_OBJ_Di = 32'b0;
                RAM_OBJ_EN = 1'b1;
                RAM_OBJ_WE = 4'b0;
                RAM_OBJ_A = 9'b0;
                /* init neighbor ram signals */
                RAM_NBR_Di = 32'b0;
                RAM_NBR_EN = 1'b1;
                RAM_NBR_WE = 4'b0;
                RAM_NBR_A = 9'b0;
                /* init result ram signals */
                RAM_RES_Di = 32'b0;
                RAM_RES_EN = 1'b1;
                RAM_RES_WE = 4'b0;
                RAM_RES_A = 9'b0;
                busy <= 1'b1;
                state <= GET_NEIGHBOR;
            end
        end
        GET_NEIGHBOR: begin
            /* check if we have gone through all neighbors */
            if (neighbors_read > neighbor_count) begin
                /* move to next vertex */
                curr_vertex = curr_vertex + 1;
                /* check if done */
                if (curr_vertex == vertex_count)
                    state <= IDLE;
                else begin
                    RAM_NBR_A = curr_vertex[(`ADDR_WIDTH - 1):0] * MAX_NEIGHBOR_COUNT;
                    neighbors_read = 32'b0;
                end
            end
            /* first time read in neighbor count */
            else if (neighbors_read == 0) begin
                neighbor_count = RAM_NBR_Do;
                RAM_NBR_A = RAM_NBR_A + 1;
                neighbors_read = neighbors_read + 1;
            end
            else begin
                /* translate neighbor index to ram address */
                RAM_OBJ_A = RAM_NBR_Do[(`ADDR_WIDTH - 1):0] * 3 - 2; /* idx by 1 */
                RAM_NBR_A = RAM_NBR_A + 1;
                neighbors_read = neighbors_read + 1;
                state <= READ_NEIGHBOR_VERTEX;
            end
        end
        READ_NEIGHBOR_VERTEX: begin
            /* read in x */
            if (i == 2'b00) begin
                sum_x <= sum_x + (RAM_OBJ_Do >>> 4);
                RAM_OBJ_A = RAM_OBJ_A + 1;
            end
            /* read in y */
            else if (i == 2'b01) begin
                sum_y <= sum_y + (RAM_OBJ_Do >>> 4);
                RAM_OBJ_A = RAM_OBJ_A + 1;
            end
            /* read in z */
            else if (i == 2'b10) begin
                sum_z <= sum_z + (RAM_OBJ_Do >>> 4);
                i = 2'b11;
                /* only read curr vertex at the end */
                if (neighbors_read == neighbor_count) begin
                    /* translate current index to ram address */
                    RAM_OBJ_A = curr_vertex[(`ADDR_WIDTH - 1):0] * 3 + 1;
                    state <= READ_CURR_VERTEX;
                end
                else
                    state <= GET_NEIGHBOR;
            end
            i = i + 1;
        end
        READ_CURR_VERTEX: begin
            /* read in x */
            if (i == 2'b00)
                sum_x <= sum_x + ((RAM_OBJ_Do * (`Q_ONE - (neighbor_count_q >>> 4))) >>> 16);
            /* read in y */
            else if (i == 2'b01)
                sum_y <= sum_y + ((RAM_OBJ_Do * (`Q_ONE - (neighbor_count_q >>> 4))) >>> 16);
            /* read in z */
            else if (i == 2'b10) begin
                sum_z <= sum_z + ((RAM_OBJ_Do * (`Q_ONE - (neighbor_count_q >>> 4))) >>> 16);
                i = 2'b11;
                state <= WRITE_CURR_VERTEX;
            end
            RAM_OBJ_A = RAM_OBJ_A + 1;
            i = i + 1;
        end
        WRITE_CURR_VERTEX: begin
            /* setup write */
            if (i == 2'b00) begin
                RAM_RES_A = curr_vertex[(`ADDR_WIDTH - 1):0] * 3 + 1;
                RAM_RES_Di = sum_x;
                RAM_RES_WE = 4'b1111;
            end
            /* write x */
            else if (i == 2'b01) begin
                RAM_RES_A = RAM_RES_A + 1;
                RAM_RES_Di = sum_y;
            end
            /* write y */
            else if (i == 2'b10) begin
                RAM_RES_A = RAM_RES_A + 1;
                RAM_RES_Di = sum_z;
            end
            /* write z */
            else begin
                /* stop writing and move to next neighbor */
                RAM_RES_WE = 4'b0;
                state <= GET_NEIGHBOR;
            end
            i = i + 1;
        end
        default: begin
        end
    endcase
end

endmodule

