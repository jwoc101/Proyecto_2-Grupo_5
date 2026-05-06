module top (
    input  logic clk,
    input  logic reset,
    output logic [3:0] row,
    input  logic [3:0] col,
    output logic [3:0] lit_digit,
    output logic [6:0] lit_segs
);

    logic [3:0] key_val;
    logic       key_valid;
    logic [3:0] reg_A, reg_B;
    logic [4:0] suma;

    // --- DETECTOR DE FLANCO (EDGE DETECTOR) ---
    // Esto evita que una tecla mantenida presionada cuente como múltiples pulsaciones
    logic prev_valid;
    logic valid_pulse;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            prev_valid <= 1'b0;
        end else begin
            prev_valid <= key_valid;
        end
    end

    // Solo da '1' en el instante exacto en que key_valid pasa de 0 a 1
    assign valid_pulse = key_valid && !prev_valid;

    // --- Instancia del Teclado ---
    teclado inst_teclado (
        .clk(clk),
        .rst(~reset),
        .row(row),
        .col(col),
        .key(key_val),
        .valid(key_valid)
    );

    // --- Máquina de Estados ---
    // Reducido a 3 estados para mayor eficiencia
    typedef enum logic [1:0] {
        IDLE   = 2'b00, // Espera primer número (A)
        WAIT_B = 2'b01, // Espera segundo número (B)
        RESULT = 2'b10  // Muestra resultado
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= IDLE;
            reg_A <= 4'h0;
            reg_B <= 4'h0;
        end else begin
            state <= next_state;
            
            // OJO AQUÍ: Ahora usamos valid_pulse, no key_valid
            if (valid_pulse) begin
                if (state == IDLE) begin
                    reg_A <= key_val;
                end else if (state == WAIT_B) begin
                    reg_B <= key_val;
                end
            end
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (valid_pulse) next_state = WAIT_B;
            WAIT_B: if (valid_pulse) next_state = RESULT;
            RESULT: next_state = RESULT;
            default: next_state = IDLE;
        endcase
    end

    // --- Operación ---
    assign suma = reg_A + reg_B;

    // --- Lógica de Visualización ---
    logic [3:0] d3, d2, d1, d0;

    always @(*) begin
        case (state)
            IDLE: begin
                d3 = 4'h0; d2 = 4'h0; d1 = 4'h0; d0 = 4'h0;
            end
            WAIT_B: begin
                d3 = 4'hA; d2 = reg_A; d1 = 4'h0; d0 = 4'h0;
            end
            RESULT: begin
                d3 = {3'b000, suma[4]}; // Acarreo
                d2 = suma[3:0];         // Suma
                d1 = reg_A;             // Operando A
                d0 = reg_B;             // Operando B
            end
            default: {d3, d2, d1, d0} = 16'h0000;
        endcase
    end

    // --- Instancia del Display ---
    display inst_display (
        .clk(clk),
        .reset(reset),
        .disp3(d3),
        .disp2(d2),
        .disp1(d1),
        .disp0(d0),
        .lit_digit(lit_digit),
        .lit_segs(lit_segs)
    );

endmodule