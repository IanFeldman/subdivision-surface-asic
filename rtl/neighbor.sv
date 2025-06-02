`timescale 1ns/1ps
`define ADDR_WIDTH 11

/* RAM_OBJ is obj input, RAM_NBR is neighbors output */
module neighbor #(parameter MAX_NEIGHBOR_COUNT=10)
(
    input clk, start,
    input [31:0] vertex_count, face_count,
    input [31:0] RAM_OBJ_Do, RAM_NBR_Do,
    output logic RAM_OBJ_EN, RAM_NBR_EN,
    output logic [(`ADDR_WIDTH - 1):0] RAM_OBJ_A, RAM_NBR_A,
    output logic [3:0] RAM_OBJ_WE, RAM_NBR_WE,
    output logic [31:0] RAM_OBJ_Di, RAM_NBR_Di,
    output logic busy
);

enum {IDLE, CLEAR, READ_FACE, CHECK_VERT, UPDATE_CHECK, INSERT_NEIGHBOR, DONE} state;
enum {SETUP_NCOUNT, SETUP_LOOP, LOOP, CV_DONE} cv_state;
enum {SETUP_NCOUNT_WRITE, SETUP_N_WRITE, IN_DONE} in_state;

/* debug state - simulation only */
`ifndef OPENLANE
logic [63:0] state_string, cv_state_string, in_state_string;
always_comb begin
    case (state)
        IDLE:            state_string = "IDLE    ";
        CLEAR:           state_string = "CLEAR   ";
        READ_FACE:       state_string = "READ_FCE";
        CHECK_VERT:      state_string = "CHK_VERT";
        UPDATE_CHECK:    state_string = "UPDT_CHK";
        INSERT_NEIGHBOR: state_string = "INS_NBR ";
        DONE:            state_string = "DONE    ";
        default:         state_string = "UNKNOWN ";
    endcase
    case (cv_state)
        SETUP_NCOUNT:    cv_state_string = "SET_NCNT";
        SETUP_LOOP:      cv_state_string = "SET_LOOP";
        LOOP:            cv_state_string = "LOOP    ";
        CV_DONE:         cv_state_string = "DONE    ";
        default:         cv_state_string = "UNKNOWN ";
    endcase
    case (in_state)
        SETUP_NCOUNT_WRITE: in_state_string = "SET_NCNT";
        SETUP_N_WRITE:      in_state_string = "SET_N_WR";
        DONE:               in_state_string = "DONE    ";
        default:            in_state_string = "UNKNOWN ";
    endcase
end
`endif

/*
 * Wait for start to go high
 * Initialize all signals
 *
 * For each face, f, in obj
 *    Read in vertex_a, vertex_b, vertex_c
 *    For vertex_a:
 *       Read neighbor count from neighbor list
 *       Iterate over neighbors
 *       If vertex_b not in neighbor list:
 *          Write vertex_b to neighbor list
 *          Increment neighbor count
 *       If vertex_c not in neighbor list:
 *          Write vertex_b to neighbor list
 *          Increment neighbor count
 *    For vertex_b:
 *       ...
 *    For vertex_c:
 *       ...
 */

logic [31:0] curr_face, vertex_a, vertex_b, vertex_c;
logic [1:0] i;

/* for checking if neighbor is present */
logic [31:0] curr_vertex, test_vertex, neighbor;
logic vertex_present;
logic [3:0] neighbor_count, neighbor_idx; /* TODO: Match size to MAX_NEIGHBOR_COUNT */
logic [(`ADDR_WIDTH - 1):0] neighbor_list_addr;

/* state machine */
always_ff@(negedge clk) begin
    case (state)
        /* initialize memory for vertex count read */
        IDLE: begin
            busy <= 1'b0;
            /* update state */
            if (start == 1'b1) begin
                /* init obj ram signals */
                RAM_OBJ_Di <= 32'b0;
                RAM_OBJ_EN <= 1'b1;
                RAM_OBJ_WE <= 4'b0;
                /* init nbr ram signals */
                RAM_NBR_Di <= 32'b0;
                RAM_NBR_EN <= 1'b1;
                RAM_NBR_WE <= 4'b1111;
                RAM_NBR_A <= `ADDR_WIDTH'b0;
                /* init various signals */
                busy <= 1'b1;
                i <= 2'b0;
                curr_face <= 32'b0;
                curr_vertex <= 32'b0;
                vertex_a <= 32'b0;
                vertex_b <= 32'b0;
                vertex_c <= 32'b0;
                /* set address to first face */
                RAM_OBJ_A <= vertex_count[(`ADDR_WIDTH - 1):0] * 3 + 2;
                state <= CLEAR;
            end
        end
        /* clear the neighbor count for each vertex */
        CLEAR: begin
            /* curr_vertex is index here */
            if (curr_vertex < vertex_count) begin
                RAM_NBR_A <= RAM_NBR_A + MAX_NEIGHBOR_COUNT;
                curr_vertex <= curr_vertex + 1;
            end
            else begin
                RAM_NBR_WE <= 4'b0000;
                state <= READ_FACE;
            end
        end
        /* get face vertices a, b, c */
        READ_FACE: begin
            /* end loop */
            if (curr_face == face_count)
                state <= DONE;
            else begin
                if (i == 2'b00) begin
                    vertex_a <= RAM_OBJ_Do;
                    i <= i + 1;
                end
                else if (i == 2'b01) begin
                    vertex_b <= RAM_OBJ_Do;
                    i <= i + 1;
                end
                else if (i == 2'b10) begin
                    vertex_c <= RAM_OBJ_Do;
                    curr_vertex <= vertex_a;
                    test_vertex <= vertex_b;
                    vertex_present <= 1'b0;
                    i <= 2'b00;
                    curr_face <= curr_face + 1;
                    state <= CHECK_VERT;
                end
                RAM_OBJ_A <= RAM_OBJ_A + 1;
            end
        end
        /* set vertex_present if curr_vertex has neighbor test_vertex */
        CHECK_VERT: begin
            /* vertex indexed at 1 */
            case (cv_state)
                SETUP_NCOUNT: begin
                    neighbor_list_addr = (curr_vertex[(`ADDR_WIDTH - 1):0] - 1) * MAX_NEIGHBOR_COUNT; /* TODO: revisit bit widths */
                    RAM_NBR_A <= neighbor_list_addr;
                    cv_state <= SETUP_LOOP;
                end
                SETUP_LOOP: begin
                    /* read neighbor count */
                    neighbor_count = RAM_NBR_Do[3:0]; /* TODO revisit bit width */
                    if (neighbor_count == 4'b0) begin
                        cv_state <= CV_DONE;
                    end
                    else begin
                        neighbor_idx = 4'b0;
                        /* set address of first neighbor */
                        RAM_NBR_A <= neighbor_list_addr + `ADDR_WIDTH'(neighbor_idx) + 1;
                        cv_state <= LOOP;
                    end
                end
                LOOP: begin
                    /* read in neighbor */
                    neighbor = RAM_NBR_Do;
                    /* check idx */
                    if (neighbor_idx == neighbor_count)
                        cv_state <= CV_DONE;
                    /* check neighbor */
                    else if (neighbor == test_vertex) begin
                        vertex_present <= 1'b1;
                        cv_state <= CV_DONE;
                    end
                    /* move on to next neighbor */
                    else begin
                        neighbor_idx = neighbor_idx + 1;
                        RAM_NBR_A <= neighbor_list_addr + `ADDR_WIDTH'(neighbor_idx) + 1;
                    end
                end
                /* update state */
                CV_DONE: begin
                    cv_state <= SETUP_NCOUNT;
                    /* either insert or update check */
                    if (vertex_present == 1'b0)
                        state <= INSERT_NEIGHBOR;
                    else
                        state <= UPDATE_CHECK;
                end
                default begin
                end
            endcase
        end
        /* Move to next curr_vertex, test_vertex pair */
        UPDATE_CHECK: begin
            /* reset vertex present */
            vertex_present <= 1'b0;
            /* by default rerun check vertex on next combo */
            state <= CHECK_VERT;
            if (curr_vertex == vertex_a) begin
                if (test_vertex == vertex_b)
                    test_vertex <= vertex_c;
                else if (test_vertex == vertex_c) begin
                    curr_vertex <= vertex_b;
                    test_vertex <= vertex_a;
                end
            end
            else if (curr_vertex == vertex_b) begin
                if (test_vertex == vertex_a)
                    test_vertex <= vertex_c;
                else if (test_vertex == vertex_c) begin
                    curr_vertex <= vertex_c;
                    test_vertex <= vertex_a;
                end
            end
            else if (curr_vertex == vertex_c) begin
                if (test_vertex == vertex_a)
                    test_vertex <= vertex_b;
                else if (test_vertex == vertex_b)
                    state <= READ_FACE; /* read the next face in */
            end
        end
        /* insert test_vertex into curr_vertex list */
        INSERT_NEIGHBOR: begin
            case (in_state)
                SETUP_NCOUNT_WRITE: begin
                    /* increment neighbor count */
                    if (neighbor_count == MAX_NEIGHBOR_COUNT)
                        in_state <= IN_DONE;
                    else begin
                        neighbor_count = neighbor_count + 1;
                        /* set ram signals */
                        RAM_NBR_A <= neighbor_list_addr;
                        RAM_NBR_Di <= {28'b0, neighbor_count};
                        RAM_NBR_WE <= 4'b1111;
                        in_state <= SETUP_N_WRITE;
                    end
                end
                SETUP_N_WRITE: begin
                    /* go to address of new neighbor */
                    RAM_NBR_A <= neighbor_list_addr + `ADDR_WIDTH'(neighbor_count);
                    RAM_NBR_Di <= test_vertex;
                    in_state <= IN_DONE;
                end
                IN_DONE: begin
                    RAM_OBJ_EN <= 1'b1;
                    RAM_NBR_EN <= 1'b1;
                    RAM_NBR_WE <= 4'b0;
                    in_state <= SETUP_NCOUNT_WRITE;
                    state <= UPDATE_CHECK;
                end
                default: begin
                end
            endcase
        end
        DONE: begin
            busy <= 1'b0;
            state <= IDLE;
        end
        default begin
        end
    endcase
end

endmodule

