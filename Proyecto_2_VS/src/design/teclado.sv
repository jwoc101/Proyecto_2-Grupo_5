module teclado (
    input logic clk,        // 27 MHz
    input logic rst,

    output logic [3:0] row, // pines izquierdos visto desde arriba
    input logic [3:0] col,  // pines derechos

    output logic [3:0] key,
    output logic valid
);

    // ============================================================
    // Parameters
    // ============================================================
    parameter SCAN_DIV = 15000;
    parameter DEBOUNCE_TIME = 270000;

    // ============================================================
    // Clock divider for scanning
    // ============================================================
    logic [15:0] scan_cnt; 
    wire scan_tick = (scan_cnt >= SCAN_DIV); 

    always @(posedge clk or posedge rst) begin 
        if (rst)
            scan_cnt <= 0;
        else if (scan_tick)
            scan_cnt <= 0;
        else
            scan_cnt <= scan_cnt + 1;
    end

    // ============================================================
    // Declaración de la Máquina de Estados
    // ============================================================
    localparam IDLE      = 2'd0;
    localparam DEBOUNCE  = 2'd1;
    localparam PRESSED   = 2'd2;

    logic [1:0] state;
    logic [31:0] debounce_cnt;
    logic [3:0] stable_key;

    // ============================================================
    // Detección de tecla cruda (Lógica Combinacional)
    // ============================================================
    logic [1:0] scanned_row;
    logic [3:0] raw_key;
    logic raw_pressed;

    always @(*) begin
        raw_pressed = 0;
        raw_key = 4'h0;
        case (scanned_row)
            2'd0: if (col != 4'b0000) begin
                raw_pressed = 1;
                case (col)
                    4'b0001: raw_key = 4'h1;
                    4'b0010: raw_key = 4'h2;
                    4'b0100: raw_key = 4'h3;
                    4'b1000: raw_key = 4'hA;
                endcase
            end

            2'd1: if (col != 4'b0000) begin
                raw_pressed = 1;
                case (col)
                    4'b0001: raw_key = 4'h4;
                    4'b0010: raw_key = 4'h5;
                    4'b0100: raw_key = 4'h6;
                    4'b1000: raw_key = 4'hB;
                endcase
            end

            2'd2: if (col != 4'b0000) begin
                raw_pressed = 1;
                case (col)
                    4'b0001: raw_key = 4'h7;
                    4'b0010: raw_key = 4'h8;
                    4'b0100: raw_key = 4'h9;
                    4'b1000: raw_key = 4'hC;
                endcase
            end

            2'd3: if (col != 4'b0000) begin
                raw_pressed = 1;
                case (col)
                    4'b0001: raw_key = 4'hE;
                    4'b0010: raw_key = 4'h0;
                    4'b0100: raw_key = 4'hF;
                    4'b1000: raw_key = 4'hD;
                endcase
            end
        endcase
    end

    // ============================================================
    // Row scanner (Escáner de Filas)
    // ============================================================
    // 1. Lógica Secuencial: Congela el escáner si hay algo presionado
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scanned_row <= 0;
        end else if (scan_tick) begin
            // Solo avanza a la siguiente fila si está libre y no se presiona nada
            if (state == IDLE && raw_pressed == 1'b0) begin
                scanned_row <= scanned_row + 1;
            end
        end
    end

    // 2. Lógica Combinacional: Salida física inmediata a los pines
    always @(*) begin
        case (scanned_row)
            2'd0: row = 4'b0001;
            2'd1: row = 4'b0010;
            2'd2: row = 4'b0100;
            2'd3: row = 4'b1000;
            default: row = 4'b0000;
        endcase
    end

    // ============================================================
    // Máquina de Estados para Anti-rebote
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            debounce_cnt <= 0;
            valid <= 0;
            key <= 0;
        end else begin
            valid <= 0;
            case (state)
                IDLE: begin
                    if (raw_pressed) begin
                        stable_key <= raw_key;
                        debounce_cnt <= 0;
                        state <= DEBOUNCE;
                    end
                end

                DEBOUNCE: begin
                    if (raw_pressed && raw_key == stable_key) begin
                        if (debounce_cnt >= DEBOUNCE_TIME) begin
                            key <= stable_key;
                            valid <= 1;   // Envía un único pulso válido
                            state <= PRESSED;
                        end else begin
                            debounce_cnt <= debounce_cnt + 1;
                        end
                    end else begin
                        state <= IDLE; // Fue un ruido/rebote falso
                    end
                end

                PRESSED: begin
                    // Espera aquí eternamente (con el escáner congelado) 
                    // hasta que se suelte la tecla.
                    if (!raw_pressed) begin
                        debounce_cnt <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule