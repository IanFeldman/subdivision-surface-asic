`timescale 1ns/1ps

`define ADDR_WIDTH 11
`define Q_ONE 32'h00010000
`define BETA_SHIFT 3

module averager #(parameter MAX_NEIGHBOR_COUNT=10)
(
    input clk, start,
    input [31:0] vertex_count, face_count,
    input signed [31:0] RAM_OBJ_Do, RAM_NBR_Do,
    output logic RAM_OBJ_EN, RAM_NBR_EN, RAM_RES_EN,
    output logic [(`ADDR_WIDTH - 1):0] RAM_OBJ_A, RAM_NBR_A, RAM_RES_A,
    output logic [3:0] RAM_OBJ_WE, RAM_NBR_WE, RAM_RES_WE,
    output logic [31:0] RAM_OBJ_Di, RAM_NBR_Di, RAM_RES_Di,
    output logic busy
);

logic [(`ADDR_WIDTH - 1):0] address;
logic [31:0] count, curr_vertex, neighbor_count, neighbors_read;
logic signed [31:0] sum_x, sum_y, sum_z;
logic signed [31:0] neighbor_count_q, neighbor_vertex_weight, curr_vertex_weight;
logic [1:0] i;
logic signed [63:0] product_64; /* for curr vertex weight multiplication */

/* continuous assignments */
assign neighbor_count_q = neighbor_count << 16;
assign neighbor_vertex_weight = (RAM_OBJ_Do >>> `BETA_SHIFT);
assign product_64 = $signed(RAM_OBJ_Do) * $signed(`Q_ONE - (neighbor_count_q >>> `BETA_SHIFT));
assign curr_vertex_weight = product_64[47:16];

enum {IDLE, COPY, GET_NEIGHBOR, READ_NEIGHBOR_VERTEX,
      READ_CURR_VERTEX, WRITE_CURR_VERTEX, DONE} state;

`ifndef OPENLANE
logic [63:0] state_string;
always_comb begin
    case (state)
        IDLE:                   state_string = "IDLE    ";
        COPY:                   state_string = "COPY    ";
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

always_ff @(negedge clk) begin
    case (state)
        IDLE: begin
            busy <= 1'b0;
            /* update state */
            if (start == 1'b1) begin
                /* init various signals */
                i <= 2'b0;
                curr_vertex <= 32'b0; /* idx of curr vert, 0 -> (vertex_count - 1) */
                neighbor_count <= 32'b0;
                neighbors_read <= 32'b0;
                sum_x <= 32'b0;
                sum_y <= 32'b0;
                sum_z <= 32'b0;
                address <= `ADDR_WIDTH'b0;
                count <= 32'b0;
                /* init object ram signals */
                RAM_OBJ_Di <= 32'b0;
                RAM_OBJ_EN <= 1'b1;
                RAM_OBJ_WE <= 4'b0;
                RAM_OBJ_A <= `ADDR_WIDTH'b0;
                /* init neighbor ram signals */
                RAM_NBR_Di <= 32'b0;
                RAM_NBR_EN <= 1'b1;
                RAM_NBR_WE <= 4'b0;
                RAM_NBR_A <= `ADDR_WIDTH'b0;
                /* init result ram signals */
                RAM_RES_Di <= 32'b0;
                RAM_RES_EN <= 1'b1;
                RAM_RES_WE <= 4'b1111;
                RAM_RES_A <= `ADDR_WIDTH'b0;
                busy <= 1'b1;
                state <= COPY;
            end
        end
        /* copy counts and faces from RAM_OBJ to RAM_RES */
        COPY: begin
            if (i == 2'b00) begin
                RAM_RES_Di <= RAM_OBJ_Do;
                RAM_OBJ_A <= vertex_count[(`ADDR_WIDTH - 1):0] * 3 + 1;
                address <= vertex_count[(`ADDR_WIDTH - 1):0] * 3 + 1;
                RAM_RES_A <= address;
                count <= count + 1;
                i <= i + 1;
            end
            else if (i == 2'b01) begin
                RAM_RES_Di <= RAM_OBJ_Do;
                RAM_OBJ_A <= RAM_OBJ_A + 1;
                address <= address + 1;
                RAM_RES_A <= address;
                count <= count + 1;
                if (count > face_count * 3) begin
                    i <= 2'b00;
                    state <= GET_NEIGHBOR;
                end
            end
        end
        GET_NEIGHBOR: begin
            /* check if we have gone through all neighbors */
            if (neighbors_read > neighbor_count) begin
                /* move to next vertex */
                curr_vertex <= curr_vertex + 1;
                /* check if done */
                if (curr_vertex + 1 == vertex_count)
                    state <= IDLE;
                else begin
                    RAM_NBR_A <= (curr_vertex[(`ADDR_WIDTH - 1):0] + 1) * MAX_NEIGHBOR_COUNT;
                    neighbors_read <= 32'b0;
                end
            end
            /* first time read in neighbor count */
            else if (neighbors_read == 0) begin
                neighbor_count <= RAM_NBR_Do;
                RAM_NBR_A <= RAM_NBR_A + 1;
                neighbors_read <= neighbors_read + 1;
                /* reset sums */
                sum_x <= 32'b0;
                sum_y <= 32'b0;
                sum_z <= 32'b0;
            end
            else begin
                /* translate neighbor index to ram address */
                RAM_OBJ_A <= RAM_NBR_Do[(`ADDR_WIDTH - 1):0] * 3 - 2; /* idx by 1 */
                RAM_NBR_A <= RAM_NBR_A + 1;
                neighbors_read <= neighbors_read + 1;
                state <= READ_NEIGHBOR_VERTEX;
            end
        end
        READ_NEIGHBOR_VERTEX: begin
            /* read in x */
            if (i == 2'b00) begin
                sum_x <= sum_x + neighbor_vertex_weight;
                RAM_OBJ_A <= RAM_OBJ_A + 1;
                i <= i + 1;
            end
            /* read in y */
            else if (i == 2'b01) begin
                sum_y <= sum_y + neighbor_vertex_weight;
                RAM_OBJ_A <= RAM_OBJ_A + 1;
                i <= i + 1;
            end
            /* read in z */
            else if (i == 2'b10) begin
                sum_z <= sum_z + neighbor_vertex_weight;
                i <= 2'b00;
                /* only read curr vertex at the end */
                if (neighbors_read > neighbor_count) begin
                    /* translate current index to ram address */
                    RAM_OBJ_A <= curr_vertex[(`ADDR_WIDTH - 1):0] * 3 + 1;
                    state <= READ_CURR_VERTEX;
                end
                else
                    state <= GET_NEIGHBOR;
            end
        end
        READ_CURR_VERTEX: begin
            /* read in x */
            if (i == 2'b00) begin
                sum_x <= sum_x + curr_vertex_weight;
                i <= i + 1;
            end
            /* read in y */
            else if (i == 2'b01) begin
                sum_y <= sum_y + curr_vertex_weight;
                i <= i + 1;
            end
            /* read in z */
            else if (i == 2'b10) begin
                sum_z <= sum_z + curr_vertex_weight;
                i <= 2'b00;
                state <= WRITE_CURR_VERTEX;
            end
            RAM_OBJ_A <= RAM_OBJ_A + 1;
        end
        WRITE_CURR_VERTEX: begin
            /* setup write */
            if (i == 2'b00) begin
                RAM_RES_A <= curr_vertex[(`ADDR_WIDTH - 1):0] * 3 + 1;
                RAM_RES_Di <= sum_x;
                RAM_RES_WE <= 4'b1111;
            end
            /* write x */
            else if (i == 2'b01) begin
                RAM_RES_A <= RAM_RES_A + 1;
                RAM_RES_Di <= sum_y;
            end
            /* write y */
            else if (i == 2'b10) begin
                RAM_RES_A <= RAM_RES_A + 1;
                RAM_RES_Di <= sum_z;
            end
            /* write z */
            else begin
                /* stop writing and move to next neighbor */
                RAM_RES_WE <= 4'b0;
                state <= GET_NEIGHBOR;
            end
            i <= i + 1;
        end
        default: begin
        end
    endcase
end

endmodule

