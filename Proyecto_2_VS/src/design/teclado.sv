module teclado (
    input logic clk,        // 27 MHz
    input logic rst,

    output logic [3:0] row, //pins izquierdos visto desde arriba
    input logic [3:0] col, //pins derechos

    output logic [3:0] key,
    output logic valid
);



    // ============================================================
    // Parameters
    // ============================================================
    parameter SCAN_DIV = 15000;     // ~1.8 kHz scan rate (27e6 / 15000)
    parameter DEBOUNCE_TIME = 270000; // ~10 ms (27e6 * 0.01)

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
    // Row scanner: hace update cada scan_tick o reset
    // ============================================================
    logic [1:0] scanned_row;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scanned_row <= 0;
            row <= 4'b0001;
        end else if (scan_tick) begin
            scanned_row <= scanned_row + 1;
            case (scanned_row)
                2'd0: row <= 4'b0001;
                2'd1: row <= 4'b0010;
                2'd2: row <= 4'b0100;
                2'd3: row <= 4'b1000;
            endcase
        end
    end

    // ============================================================
    // Raw key detection
    // ============================================================
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
    // Debounce FSM
    // ============================================================
    localparam IDLE      = 2'd0;
    localparam DEBOUNCE  = 2'd1;
    localparam PRESSED   = 2'd2;

    logic [1:0] state;
    logic [31:0] debounce_cnt;
    logic [3:0] stable_key;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            debounce_cnt <= 0;
            valid <= 0;
            key <= 0;
        end else begin
            valid <= 0;

            case (state)

                // ----------------------------
                // Wait for key press
                // ----------------------------
                IDLE: begin
                    if (raw_pressed) begin
                        stable_key <= raw_key;
                        debounce_cnt <= 0;
                        state <= DEBOUNCE;
                    end
                end

                // ----------------------------
                // Debounce press
                // ----------------------------
                DEBOUNCE: begin
                    if (raw_pressed && raw_key == stable_key) begin
                        if (debounce_cnt >= DEBOUNCE_TIME) begin
                            key <= stable_key;
                            valid <= 1;   // one pulse
                            state <= PRESSED;
                        end else begin
                            debounce_cnt <= debounce_cnt + 1;
                        end
                    end else begin
                        state <= IDLE; // bounce or change → reset
                    end
                end

                // ----------------------------
                // Wait for release
                // ----------------------------
                PRESSED: begin
                    if (!raw_pressed) begin
                        debounce_cnt <= 0;
                        state <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule