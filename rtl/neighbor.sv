`timescale 1ns/1ps

/* RAM1 is obj input, RAM2 is neighbors output */
module neighbor #(parameter MAX_NEIGHBOR_COUNT=10)
(
    input clk,
    input [31:0] RAM1_Do, RAM2_Do,
    output logic RAM1_EN, RAM2_EN,
    output logic [8:0] RAM1_A, RAM2_A,
    output logic [3:0] RAM1_WE, RAM2_WE,
    output logic [31:0] RAM1_Di, RAM2_Di
);

enum {SETUP_VCOUNT, SETUP_FCOUNT, SETUP_LOOP, READ_FACE, CHECK_VERT,
    UPDATE_CHECK, INSERT_NEIGHBOR, DONE} state = SETUP_VCOUNT;

/* RAM address width 9 bits */
logic [8:0] obj_address = 9'b0;
logic [31:0] vertex_count, face_count, curr_face;
logic [31:0] vertex_a, vertex_b, vertex_c;
logic [1:0] i;

/* for checking if neighbor is present */
logic [31:0] curr_vertex, test_vertex, neighbor;
logic vertex_present;
logic [3:0] neighbor_count, neighbor_idx; /* TODO: Match size to MAX_NEIGHBOR_COUNT */
logic [8:0] neighbor_list_addr;

/* state machine */
always_ff@(posedge clk) begin
    case (state)
        /* initialize memory for vertex count read */
        SETUP_VCOUNT: begin
            /* init ram 1 signals */
            RAM1_Di <= 32'b0;
            RAM1_EN <= 1'b1;
            RAM1_WE <= 4'b0;
            RAM1_A <= obj_address;
            /* init ram 2 signals */
            RAM2_Di <= 32'b0;
            RAM2_EN <= 1'b1;
            RAM2_WE <= 4'b0;
            RAM2_A <= 9'b0;
            /* update state */
            state <= SETUP_FCOUNT;
        end
        /* read vertex count and set up face count read */
        SETUP_FCOUNT: begin
            vertex_count <= RAM1_Do;
            obj_address <= vertex_count[8:0] * 3 + 1;
            RAM1_A <= obj_address;
            state <= SETUP_LOOP;
        end
        /* read face count and begin iteration */
        SETUP_LOOP: begin
            face_count <= RAM1_Do;
            obj_address <= obj_address + 1;
            i <= 0;
            curr_face <= 32'b0;
            state <= READ_FACE;
        end
        /* get face vertices a, b, c */
        READ_FACE: begin
            /* end loop */
            if (curr_face == face_count)
                state <= DONE;
            else begin
                if (i == 2'b00)
                    vertex_a <= RAM1_Do;
                else if (i == 2'b01)
                    vertex_b <= RAM1_Do;
                else if (i == 2'b10)
                    vertex_c <= RAM1_Do;
                else begin
                    curr_vertex <= vertex_a;
                    test_vertex <= vertex_b;
                    vertex_present <= 1'b0;
                    i <= 2'b00;
                    curr_face <= curr_face + 1;
                    state <= CHECK_VERT;
                end
                obj_address <= obj_address + 1;
            end
        end
        /* set vertex_present if curr_vertex has neighbor test_vertex */
        CHECK_VERT: begin
            enum {SETUP_NCOUNT, SETUP_LOOP, LOOP, DONE} cv_state;
            cv_state <= SETUP_NCOUNT;

            /* vertex indexed at 1 */
            case (cv_state)
                SETUP_NCOUNT: begin
                    neighbor_list_addr <= (curr_vertex[8:0] - 1) * MAX_NEIGHBOR_COUNT; /* TODO: revisit bit widths */
                    RAM2_A <= neighbor_list_addr;
                    cv_state <= SETUP_LOOP;
                end
                SETUP_LOOP: begin
                    /* read neighbor count */
                    neighbor_count <= RAM2_Do[3:0]; /* TODO revisit bit width */
                    if (neighbor_count == 4'b0) begin
                        cv_state <= DONE;
                    end
                    else begin
                        neighbor_idx <= 4'b0;
                        /* set address of first neighbor */
                        RAM2_A <= neighbor_list_addr + {5'b0, neighbor_idx} + 1;
                        cv_state <= LOOP;
                    end
                end
                LOOP: begin
                    /* read in neighbor */
                    neighbor <= RAM2_Do;
                    /* check idx */
                    if (neighbor_idx == neighbor_count)
                        cv_state <= DONE;
                    /* check neighbor */
                    else if (neighbor == test_vertex) begin
                        vertex_present <= 1'b1;
                        cv_state <= DONE;
                    end
                    /* move on to next neighbor */
                    else begin
                        neighbor_idx <= neighbor_idx + 1;
                        RAM2_A <= neighbor_list_addr + {5'b0, neighbor_idx} + 1;
                    end
                end
                /* update state */
                DONE: begin
                    cv_state <= SETUP_NCOUNT;
                    state <= UPDATE_CHECK;
                end
                default begin
                end
            endcase
        end
        /* Move to next curr_vertex, test_vertex pair */
        UPDATE_CHECK: begin
            /* add curr_vertex to neighbor list */
            if (vertex_present == 1'b0) begin
                state <= INSERT_NEIGHBOR;
            end
            else begin
                /* reset vertex present */
                vertex_present <= 1'b0;
                /* rerun check vertex on next combo */
                state <= CHECK_VERT;
                /* perform vertex check for all combos */
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
        end
        /* insert test_vertex into curr_vertex list */
        INSERT_NEIGHBOR: begin
            enum {SETUP_NCOUNT_WRITE, SETUP_N_WRITE, DONE} in_state;
            in_state <= SETUP_NCOUNT_WRITE;
            case (in_state)
                SETUP_NCOUNT_WRITE: begin
                    /* increment neighbor count */
                    if (neighbor_count == MAX_NEIGHBOR_COUNT)
                        in_state <= DONE;
                    else begin
                        neighbor_count <= neighbor_count + 1;
                        /* set ram signals */
                        RAM2_A <= neighbor_list_addr;
                        RAM2_Di <= {28'b0, neighbor_count};
                        RAM2_WE <= 4'b1111;
                        in_state <= SETUP_N_WRITE;
                    end
                end
                SETUP_N_WRITE: begin
                    /* go to address of new neighbor */
                    RAM2_A <= neighbor_list_addr + {5'b0, neighbor_count};
                    RAM2_Di <= test_vertex;
                    in_state <= DONE;
                end
                DONE: begin
                    RAM1_EN <= 1'b1;
                    RAM2_EN <= 1'b1;
                    RAM2_WE <= 4'b0;
                end
                default: begin
                end
            endcase
        end
        default begin
        end
    endcase
end

endmodule

