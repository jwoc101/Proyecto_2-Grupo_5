module sumador (
    input  logic clk,
    input  logic rst,

    input  logic [3:0] key_in,
    input  logic valid,

    output logic [15:0] num_out
);

    // ============================================================
    // Estados
    // ============================================================

    logic [1:0] state;

    localparam IDLE  = 2'b00;
    localparam NUM_A = 2'b01;
    localparam NUM_B = 2'b10;
    localparam SUM_C = 2'b11;

    // ============================================================
    // Registros
    // ============================================================

    logic [15:0] num_1;
    logic [15:0] num_2;
    logic [15:0] sum;

    assign sum = num_1 + num_2;

    // ============================================================
    // Lógica principal
    // ============================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state   <= IDLE;

            num_1   <= 16'h0000;
            num_2   <= 16'h0000;

            num_out <= 16'h0000;

        end
        else if (valid) begin

            case (key_in)

                // ========================================
                // Seleccionar número A
                // ========================================

                4'hA: begin
                    state   <= NUM_A;
                    num_out <= num_1;
                end

                // ========================================
                // Seleccionar número B
                // ========================================

                4'hB: begin
                    state   <= NUM_B;
                    num_out <= num_2;
                end

                // ========================================
                // Mostrar suma
                // ========================================

                4'hC: begin
                    state   <= SUM_C;
                    num_out <= sum;
                end

                // ========================================
                // Dígitos normales
                // ========================================

                default: begin

                    case (state)

                        NUM_A: begin

                            num_1[15:12] = num_1[11:8];
                            num_1[11:8]  = num_1[7:4];
                            num_1[7:4]   = num_1[3:0];
                            num_1[3:0]   = key_in;

                            num_out = num_1;
                            

                        end

                        NUM_B: begin

                            num_2[15:12] <= num_2[11:8];
                            num_2[11:8]  <= num_2[7:4];
                            num_2[7:4]   <= num_2[3:0];
                            num_2[3:0]   <= key_in;

                            num_out <= {num_2[11:0],key_in};

                        end

                        SUM_C: begin
                            num_out <= sum;
                        end

                        default: begin
                            state <= IDLE;
                        end

                    endcase
                end

            endcase
        end
    end

endmodule