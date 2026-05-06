module display (
    input  logic clk,           // Reloj interno 27MHz
    input  logic reset,         // Botón de reset

    // Nuevas entradas: los 4 valores hexadecimales a mostrar
    input  logic [3:0] disp0,   // Dígito de la derecha (posición 0)
    input  logic [3:0] disp1,   // Posición 1
    input  logic [3:0] disp2,   // Posición 2
    input  logic [3:0] disp3,   // Dígito de la izquierda (posición 3)

    output logic [3:0] lit_digit, // Ánodos/Cátodos comunes
    output logic [6:0] lit_segs   // Segmentos gfedcba (lógica inversa)
);

    logic rst;
    assign rst = ~reset;

    // 1. Divisor de reloj para el refresco (multiplexación)
    // Reducimos la frecuencia para que el ojo humano no note el parpadeo
    logic [13:0] scan_cnt;
    wire scan_tick = (scan_cnt == 0);

    always @(posedge clk or posedge rst) begin
        if (rst) scan_cnt <= 0;
        else     scan_cnt <= scan_cnt + 1;
    end

    // 2. Secuencia de escaneo: Enciende un dígito a la vez
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
    logic [3:0] current_hex_val;
    always @(*) begin
        case (cycled_digit)
            2'd0: current_hex_val = disp0;
            2'd1: current_hex_val = disp1;
            2'd2: current_hex_val = disp2;
            2'd3: current_hex_val = disp3;
            default: current_hex_val = 4'h0;
        endcase
    end

    // 4. Decodificador de 7 Segmentos (Tabla de verdad)
    // Usamos la lógica de tu compañero: gfedcba (0 enciende)
    always @(*) begin
        case (current_hex_val)
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