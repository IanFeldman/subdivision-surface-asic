`timescale 1ns/1ps

module subdiv (
    input clk, start,
    input [31:0] RAM1_Do, RAM2_Do, RAM3_Do,
    output logic RAM1_EN, RAM2_EN, RAM3_EN,
    output logic [8:0] RAM1_A, RAM2_A, RAM3_A,
    output logic [3:0] RAM1_WE, RAM2_WE, RAM3_WE,
    output logic [31:0] RAM1_Di, RAM2_Di, RAM3_Di,
    output logic [31:0] new_vertex_count, new_face_count,
    output logic busy
);

enum {INIT, V_COUNT, F_COUNT, WR_CNT, SETUP_MAP, READ_FACE, MAP_EDGE, FIN_EDGE,
      FIN_FACE, LOOP_BACK, WR_ORIG, DONE} state;
enum {FIND1, FIND2, FIND3, WRITE} edge_map_state;

/* rip variable names */
logic [31:0] vertex_count, face_count, edge_count;
logic [8:0] curr_face;
logic [31:0] new_vertex;
logic [31:0] va, vb, vc;
logic [31:0] ma, mb, mc;
logic [1:0] e;
logic [31:0] e1, e2, em;
logic [31:0] f1, f2, f3;
logic signed [31:0] x1, x2, xm;
logic signed [31:0] y1, y2, ym;
logic signed [31:0] z1, z2, zm;
logic [2:0] i;
logic found;

assign new_vertex_count = new_vertex - 1;
assign new_face_count = face_count * 4;

`ifndef SYNTHESIS
logic [63:0] state_string;
always_comb begin
    case (state)
        INIT:                   state_string = "INIT    ";
        V_COUNT:                state_string = "V_COUNT ";
        F_COUNT:                state_string = "F_COUNT ";
        WR_CNT:                 state_string = "WR_CNT  ";
        SETUP_MAP:              state_string = "SETP_MAP";
        READ_FACE:              state_string = "RD_FACE ";
        MAP_EDGE:               state_string = "MAP_EDGE";
        FIN_EDGE:               state_string = "FIN_EDGE";
        FIN_FACE:               state_string = "FIN_FACE";
        LOOP_BACK:              state_string = "LOOP_BCK";
        WR_ORIG:                state_string = "WR_ORIG ";
        DONE:                   state_string = "DONE    ";
        default:                state_string = "UNKNOWN ";
    endcase
end

logic [63:0] map_state_string;
always_comb begin
    case (edge_map_state)
        FIND1:                   map_state_string = "FIND1   ";
        FIND2:                   map_state_string = "FIND2   ";
        FIND3:                   map_state_string = "FIND3   ";
        WRITE:                   map_state_string = "WRITE   ";
        default:                 map_state_string = "UNKNOWN ";
    endcase
end
`endif

assign xm = (x1 + x2) >>> 1;
assign ym = (y1 + y2) >>> 1;
assign zm = (z1 + z2) >>> 1;

/* Edge combinations */
always_comb begin
    if (e == 0) begin
        e1 = va;
        e2 = vb;
    end else if (e == 1) begin
        e1 = vb;
        e2 = vc;
    end else if (e == 2) begin
        e1 = vc;
        e2 = va;
    end else begin
        /* Shouldn't happen */
        e1 = 32'hdeadbeef;
        e2 = 32'h8badf00d;
    end
end

/* Face combinations */
always_comb begin
    if (e == 0) begin
        f1 = va;
        f2 = ma;
        f3 = mc;
    end else if (e == 1) begin
        f1 = ma;
        f2 = vb;
        f3 = mb;
    end else if (e == 2) begin
        f1 = mc;
        f2 = mb;
        f3 = vc;
    end else begin
        f1 = ma;
        f2 = mb;
        f3 = mc;
    end
end

always_ff @(negedge clk) begin
    case (state)
        INIT: begin
            busy <= 0;

            RAM1_Di <= 32'b0;
            RAM1_EN <= 1'b1;
            RAM1_WE <= 4'b0;
            RAM1_A <= 9'b0;

            RAM2_Di <= 32'b0;
            RAM2_EN <= 1'b1;
            RAM2_WE <= 4'b0;
            RAM2_A <= 9'b0;

            RAM3_Di <= 32'b0;
            RAM3_EN <= 1'b1;
            RAM3_WE <= 4'b0;
            RAM3_A <= 9'b0;

            if (start == 1'b1) begin
                busy <= 1;
                state <= V_COUNT;
            end
        end
        V_COUNT: begin
            vertex_count <= RAM1_Do;
            /* new vertex starts after old vertices */
            new_vertex <= RAM1_Do + 1;
            RAM1_A <= 1 + RAM1_Do[8:0] * 3;

            /* Initialize map with null ptr */
            RAM3_WE <= 4'b1111;

            state <= F_COUNT;
        end
        F_COUNT: begin
            face_count <= RAM1_Do;
            edge_count <= RAM1_Do + vertex_count - 2;

            RAM1_A <= RAM1_A + 1;
            i <= 0;

            RAM3_WE <= 0;
            
            /* Write out new vertex count */
            RAM2_WE <= 4'b1111;
            RAM2_Di <= RAM1_Do + (vertex_count << 1) - 2;

            curr_face <= 0;
            state <= WR_CNT;
        end
        WR_CNT: begin
            /* Write out new face count */
            RAM2_A <= (1 + (vertex_count[8:0] + edge_count[8:0]) * 3);
            RAM2_Di <= face_count << 2;
            state <= READ_FACE;
        end
        READ_FACE: begin
            RAM2_WE <= 4'b0;
            if (curr_face == face_count[8:0]) begin
                RAM1_A <= 1;
                RAM2_A <= 0;
                state <= WR_ORIG;
            end else begin
                if (i == 0) begin
                    va <= RAM1_Do;
                    RAM1_A <= RAM1_A + 1;
                    i <= i + 1;
                end else if (i == 1) begin
                    vb <= RAM1_Do;
                    RAM1_A <= RAM1_A + 1;
                    i <= i + 1;
                end else if (i == 2) begin
                    vc <= RAM1_Do;
                    e <= 0;
                    edge_map_state <= FIND1;
                    state <= MAP_EDGE;
                end
            end
        end
        MAP_EDGE: begin
            case (edge_map_state)
                /* bad linear search */
                FIND1: begin
                    if (RAM3_Do == 32'b0) begin
                        i <= 0;
                        em <= new_vertex;
                        new_vertex <= new_vertex + 1;
                        RAM1_A <= 1 + (e1[8:0] - 1) * 3;
                        found <= 0;
                        edge_map_state <= WRITE;
                    end else if (RAM3_Do == e1 || RAM3_Do == e2) begin
                        edge_map_state <= FIND2;
                        RAM3_A <= RAM3_A + 1;
                    end else
                        RAM3_A <= RAM3_A + 3;
                end
                FIND2: begin
                    if (RAM3_Do == e1 || RAM3_Do == e2) begin
                        RAM3_A <= RAM3_A + 1;
                        edge_map_state <= FIND3;
                    end else begin
                        RAM3_A <= RAM3_A + 2;
                        edge_map_state <= FIND1;
                    end
                end
                FIND3: begin
                    em <= RAM3_Do;
                    RAM3_A <= RAM3_A - 2;
                    i <= 0;
                    RAM1_A <= 1 + (e1[8:0] - 1) * 3;
                    found <= 1;
                    edge_map_state <= WRITE;
                end
                WRITE: begin
                    /*
                     * Write edge indiecs to ram3 at the same time we read in
                     * vertex data from ram1 and write midpt. vert to ram2.
                     */
                    i <= i + 1;
                    if (i == 0) begin
                        RAM3_WE <= 4'b1111;
                        RAM3_Di <= e1;

                        x1 <= RAM1_Do;
                        RAM1_A <= RAM1_A + 1;
                    end else if (i == 1) begin
                        RAM3_Di <= e2;
                        RAM3_A <= RAM3_A + 1;

                        y1 <= RAM1_Do;
                        RAM1_A <= RAM1_A + 1;
                    end else if (i == 2) begin
                        RAM3_Di <= em;
                        RAM3_A <= RAM3_A + 1;

                        z1 <= RAM1_Do;
                        RAM1_A <= 1 + (e2[8:0] - 1) * 3;
                    end else if (i == 3) begin
                        if (found)
                            RAM3_WE <= 0;
                        RAM3_Di <= 32'h0;
                        RAM3_A <= RAM3_A + 1;

                        x2 <= RAM1_Do;
                        RAM1_A <= RAM1_A + 1;
                    end else if (i == 4) begin
                        RAM3_WE <= 0;

                        y2 <= RAM1_Do;
                        RAM1_A <= RAM1_A + 1;

                        RAM2_A <= 1 + (em[8:0] - 1) * 3;
                        RAM2_WE <= 4'b1111;
                        RAM2_Di <= xm;
                    end else if (i == 5) begin
                        z2 <= RAM1_Do;

                        RAM2_A <= RAM2_A + 1;
                        RAM2_Di <= ym;
                    end else if (i == 6) begin
                        RAM2_A <= RAM2_A + 1;
                        RAM2_Di <= zm;
                    end else if (i == 7) begin
                        RAM2_WE <= 0;
                        state <= FIN_EDGE;
                    end
                end
            endcase
        end
        FIN_EDGE: begin
            if (e == 0)
                ma <= em;
            else if (e == 1)
                mb <= em;
            else if (e == 2)
                mc <= em;

            if (e < 2) begin
                state <= MAP_EDGE;
                edge_map_state <= FIND1;
                RAM3_A <= 0;
                e <= e + 1;
            end else begin
                i <= 0;
                e <= 0;
                RAM2_A <= 1 + (vertex_count[8:0] + edge_count[8:0] + (curr_face << 2)) * 3;
                state <= FIN_FACE;
            end
        end
        FIN_FACE: begin
            i <= i + 1;
            if (i == 0) begin
                RAM2_WE <= 4'b1111;
                RAM2_A <= RAM2_A + 1;
                RAM2_Di <= f1;
            end else if (i == 1) begin
                RAM2_A <= RAM2_A + 1;
                RAM2_Di <= f2;
            end else if (i == 2) begin
                RAM2_A <= RAM2_A + 1;
                RAM2_Di <= f3;
                if (e < 3) begin
                    e <= e + 1;
                    i <= 0;
                end else begin
                    state <= LOOP_BACK;
                end
            end 
        end
        LOOP_BACK: begin
            RAM2_WE <= 0;
            RAM1_A <= 2 + vertex_count[8:0] * 3 + (curr_face + 1) * 3;
            RAM3_A <= 0;
            i <= 0;
            e <= 0;
            curr_face <= curr_face + 1;
            edge_map_state <= FIND1;
            state <= READ_FACE;
        end
        WR_ORIG: begin
            if (RAM2_A > vertex_count[8:0] * 3 - 1) begin
                state <= DONE;
                RAM2_WE <= 0;
            end else begin
                RAM1_A <= RAM1_A + 1;
                RAM2_A <= RAM2_A + 1;
                RAM2_WE <= 4'b1111;
                RAM2_Di <= RAM1_Do;
            end
        end
        DONE: begin
            busy <= 0;
            state <= INIT;
        end
    endcase
end

endmodule
