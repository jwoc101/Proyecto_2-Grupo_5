module display (
    input  logic clk,           // Reloj interno 27MHz
    input  logic rst,         // Botón de reset

    input logic [15:0] num_in,

    output logic [3:0] lit_digit, // Ánodo comun
    output logic [6:0] lit_segs   // Segmentos gfedcba (lógica inversa)
);


    // Nuevas entradas: los 4 valores segsadecimales a mostrar
    logic [3:0] disp0_value;   // Dígito de la derecha (posición 0)
    logic [3:0] disp1_value;   // Posición 1
    logic [3:0] disp2_value;   // Posición 2
    logic [3:0] disp3_value;   // Dígito de la izquierda (posición 3)


    assign disp0_value = num_in[3:0];
    assign disp1_value = num_in[7:4];
    assign disp2_value = num_in[11:8];
    assign disp3_value = num_in[15:12];

    // 1. Divisor de reloj para el refresco (multiplexación)
    // Reducimos la frecuencia para que el ojo humano no note el parpadeo
    logic [13:0] scan_cnt;
    wire scan_tick = (scan_cnt == 0);

    always @(posedge clk or posedge rst) begin
        if (rst) scan_cnt <= 0;
        else     scan_cnt <= scan_cnt + 1;
    end

    // 4Enciende un dígito a la vez
    logic [1:0] cycled_digit;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycled_digit <= 2'd0;
            lit_digit <= 4'b0000;
        end else if (scan_tick) begin
            cycled_digit <= cycled_digit + 1;
            case (cycled_digit)
                2'd0: lit_digit <= 4'b0001; // Activa dígito 0
                2'd1: lit_digit <= 4'b0010; // Activa dígito 1
                2'd2: lit_digit <= 4'b0100; // Activa dígito 2
                2'd3: lit_digit <= 4'b1000; // Activa dígito 3
            endcase
        end
    end

    // 3. Mux de datos: Selecciona qué valor enviar al decodificador
    logic [3:0] segs_conf;
    always @(*) begin
        case (cycled_digit)
            2'd0: segs_conf = disp3_value;
            2'd1: segs_conf = disp0_value;
            2'd2: segs_conf = disp1_value;
            2'd3: segs_conf = disp2_value;
            default: segs_conf = 4'h0;
        endcase
    end


    // 4. Decodificador de 7 Segmentos (Tabla de verdad)
    //  gfedcba (0 enciende)
    always @(*) begin
        case (segs_conf)
            4'h0: lit_segs = 7'b1000000; 
            4'h1: lit_segs = 7'b1111001;
            4'h2: lit_segs = 7'b0100100;
            4'h3: lit_segs = 7'b0110000;
            4'h4: lit_segs = 7'b0011001;
            4'h5: lit_segs = 7'b0010010;
            4'h6: lit_segs = 7'b0000010;
            4'h7: lit_segs = 7'b1111000;
            4'h8: lit_segs = 7'b0000000;
            4'h9: lit_segs = 7'b0010000;
            4'hA: lit_segs = 7'b0001000;
            4'hB: lit_segs = 7'b0000011;
            4'hC: lit_segs = 7'b1000110;
            4'hD: lit_segs = 7'b0100001;
            4'hE: lit_segs = 7'b0000110;
            4'hF: lit_segs = 7'b0001110;
            default: lit_segs = 7'b1111111; // Todo apagado
        endcase
    end





endmodule