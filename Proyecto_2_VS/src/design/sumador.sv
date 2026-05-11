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

   
    localparam NUM_A = 2'b00;
    localparam NUM_B = 2'b01;
    localparam SUM_C = 2'b10;
    localparam OVERFLOW_D  = 2'b11;

    // ============================================================
    // Registros
    // ============================================================

    logic [15:0] num_1;
    logic [15:0] num_2;
    logic [15:0] sum;
    
    //Registros para logica de suma
    logic [4:0] d0, d1, d2, d3; 
    //se ocupan registros de 5 bits para cada digito de la suma por si la suma de dos digitos es mayor a 16 (e.g. 9+9 = 18)

 
    // ============================================================
    // Lógica principal
    // ============================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state   <= NUM_A;

            num_1   <= 16'h0000;
            num_2   <= 16'h0000;

        end
        else if (valid) begin

            case (key_in)

                // ========================================
                // Seleccionar número A
                // ========================================

                4'hA: begin
                    state   <= NUM_A;
                end

                // ========================================
                // Seleccionar número B
                // ========================================

                4'hB: begin
                    state   <= NUM_B;
                end

                // ========================================
                // Mostrar suma
                // ========================================

                4'hC: begin
                    state   <= SUM_C;
                end

                4'hD: begin
                    state <= OVERFLOW_D;
                end

                // ========================================
                // Dígitos normales
                // ========================================

                default: begin

                    case (state)

                        NUM_A: begin

                            num_1[15:12] <= num_1[11:8];
                            num_1[11:8]  <= num_1[7:4];
                            num_1[7:4]   <= num_1[3:0];
                            num_1[3:0]   <= key_in;
                            

                        end

                        NUM_B: begin

                            num_2[15:12] <= num_2[11:8];
                            num_2[11:8]  <= num_2[7:4];
                            num_2[7:4]   <= num_2[3:0];
                            num_2[3:0]   <= key_in;

                        end

                        default: begin
                            state <= NUM_A;
                        end

                    endcase
                end

            endcase
        end
    end

//Proceso aritmetico que computa suma BCD


always @(*) begin

    // ========================================================
    // UNIDADES
    // ========================================================

    d0 = num_1[3:0] + num_2[3:0];

    if (d0 > 9)
        d0 = d0 + 6;

    sum[3:0] = d0[3:0];

    // ========================================================
    // DECENAS
    // ========================================================

    d1 = num_1[7:4] + num_2[7:4] + d0[4]; //d0[4] como digito de acarreo

    if (d1 > 9)
        d1 = d1 + 6;

    sum[7:4] = d1[3:0];

    // ========================================================
    // CENTENAS
    // ========================================================

    d2 = num_1[11:8] + num_2[11:8] + d1[4];

    if (d2 > 9)
        d2 = d2 + 6;

    sum[11:8] = d2[3:0];

    // ========================================================
    // MILES
    // ========================================================

    d3 = num_1[15:12] + num_2[15:12] + d2[4];

    if (d3 > 9)
        d3 = d3 + 6;

    sum[15:12] = d3[3:0];

end

    //Display 
    always @(*) begin
        case (state)
            NUM_A: num_out = num_1;
            NUM_B: num_out = num_2;
            SUM_C: num_out = sum ;
            OVERFLOW_D: num_out = 16'd0 + d3[4];
            default: num_out = 16'd0;
        endcase
    end

endmodule