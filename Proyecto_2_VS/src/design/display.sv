module display (
    input logic clk,           // internal clock
    input logic reset,

    input logic [3:0] key,
    input logic valid,

    output logic [3:0] lit_digit, //Un 1 para encender el digito [izquierda:derecha]
    output logic [6:0] lit_segs, //gfedcba, tiene logica invertida, 0 para encender el segmento

);

logic rst;
assign rst = ~reset;
 
    // ============================================================
    // Clock divider for scanning, nueva frecuencia es de ~=3kHz
    // ============================================================

    logic [13:0] scan_cnt; //la frecuencia con la que cambia scan_tick dependerá de este tamaño de scan_cnt
    wire scan_tick = (scan_cnt == 0); //scan_tick es 1 cada vez que scan_cnt llega a 0

    always @(posedge clk or posedge rst) begin //mecanismo de reset
        if (rst)
            scan_cnt <= 0;
        else
            scan_cnt <= scan_cnt + 1;
    end

    // ============================================================
    // Digit sequence: enciende los digitos uno por uno
    // ============================================================
    logic [1:0] cycled_digit;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycled_digit <= 2'd0;
            lit_digit <= 4'b1111;
           // lit_segs <= 7'b0111111; //modificar para encender segmento G
        end else if (scan_tick) begin
            cycled_digit = cycled_digit + 1;
            case (cycled_digit)
                2'd0: lit_digit <= 4'b0001;
                2'd1: lit_digit <= 4'b0010;
                2'd2: lit_digit <= 4'b0100;
                2'd3: lit_digit <= 4'b1000;
            endcase
        end
    end

    // ============================================================
    // Estado del display
    // ============================================================
    localparam IDLE = 2'd0;
    localparam NUM_A = 2'd1;
    localparam NUM_B = 2'd2;
    localparam SUM_C = 2'd3;
    logic [3:0] current_digit;

    logic [1:0] state;

        always @(*) begin

        case (cycled_digit)
            2'd0: current_digit = 4'd3;
            2'd1: current_digit = 4'd2;
            2'd2: current_digit = 4'd7;
            2'd3: current_digit = 4'd5;

        endcase
    end

    // ============================================================
    // Tabla de verdad para display
    // ============================================================


    always @(*) begin
        case (current_digit) //gfedcba
            4'd0: lit_segs = 7'b1000000;  // 0
            4'd1: lit_segs = 7'b1111001;  // 1
            4'd2: lit_segs = 7'b0100100;  // 2
            4'd3: lit_segs = 7'b0110000;  // 3
            4'd4: lit_segs = 7'b0011001;  // 4
            4'd5: lit_segs = 7'b0010010;  // 5
            4'd6: lit_segs = 7'b0000010;  // 6
            4'd7: lit_segs = 7'b1111000;  // 7
            4'd8: lit_segs = 7'b0000000;  // 8
            4'd9: lit_segs = 7'b0010000;  // 9
            default: lit_segs = 7'b1111111;
        endcase
    end

endmodule