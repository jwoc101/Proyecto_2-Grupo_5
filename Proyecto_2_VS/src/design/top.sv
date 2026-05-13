module top (
    input  logic clk,          // 27 MHz
    input  logic reset,        // botón reset

    // Teclado hexadecimal
    output logic [3:0] row,
    input  logic [3:0] col,

    // Display 7 segmentos
    output logic [3:0] lit_digit,
    output logic [6:0] lit_segs
);

    // ============================================================
    // Señales internas
    // ============================================================

    logic rst;

    logic [3:0] key_value;
    logic key_valid;

    logic [15:0] num_value;

    assign rst = ~reset;

    // ============================================================
    // Instancia del teclado
    // ============================================================

    teclado teclado_inst (
        .clk(clk),
        .rst(rst),

        .row(row),
        .col(col),

        .key_out(key_value),
        .valid(key_valid)
    );


    sumador sumador_inst (
        .clk(clk),
        .rst(rst),

        .key_in(key_value),
        .valid(key_valid),

        .num_out(num_value)

    );
    // ============================================================
    // Instancia del display
    // ============================================================

    display display_inst (
        .clk(clk),
        .rst(rst),

        .num_in(num_value),

        .lit_digit(lit_digit),
        .lit_segs(lit_segs)
    );

endmodule