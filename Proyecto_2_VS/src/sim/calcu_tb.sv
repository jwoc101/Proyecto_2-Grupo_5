`timescale 1ns / 10ps

module calcu_tb;
    // Señales
    logic clk;
    logic reset;
    logic [3:0] row;
    logic [3:0] col;
    logic [3:0] lit_digit;
    logic [6:0] lit_segs;

    // Instancia del Módulo
    top uut (
        .clk(clk),
        .reset(reset),
        .row(row),
        .col(col),
        .lit_digit(lit_digit),
        .lit_segs(lit_segs)
    );

    // --- CORRECCIÓN DE TIEMPO ---
    defparam uut.inst_teclado.SCAN_DIV = 15;
    defparam uut.inst_teclado.DEBOUNCE_TIME = 2;

    always #18.5 clk = ~clk;

    int sim_press = 0;
    int target_row = 0;
    int target_col = 0;
    
    int errores = 0; 
    int pruebas_totales = 0;
    logic [4:0] expected_sum;

    // --- TECLADO VIRTUAL EN MODO PULL-DOWN ---
    always_comb begin
        col = 4'b0000; // Por defecto está en 0 (Pull-Down)
        if (sim_press) begin
            // Si la FPGA manda un 1 a la fila, retornamos 1 a la columna
            if (row[target_row] == 1'b1) begin 
                col[target_col] = 1'b1;
            end
        end
    end

    task press_key(input int r, input int c);
        begin
            target_row = r;
            target_col = c;
            sim_press = 1;
            #50000; // Como arreglamos el SCAN_DIV, ya no necesitamos esperar 3ms
            sim_press = 0;
            #50000;
        end
    endtask

    function logic [3:0] get_hex(input int r, input int c);
        case ({r[1:0], c[1:0]})
            4'b00_00: return 4'h1;
            4'b00_01: return 4'h2;
            4'b00_10: return 4'h3;
            4'b00_11: return 4'hA;
            
            4'b01_00: return 4'h4;
            4'b01_01: return 4'h5;
            4'b01_10: return 4'h6;
            4'b01_11: return 4'hB;
            
            4'b10_00: return 4'h7;
            4'b10_01: return 4'h8;
            4'b10_10: return 4'h9;
            4'b10_11: return 4'hC;
            
            4'b11_00: return 4'hE;
            4'b11_01: return 4'h0;
            4'b11_10: return 4'hF;
            4'b11_11: return 4'hD;
            default:  return 4'h0;
        endcase
    endfunction

    initial begin
        clk = 0;
        reset = 0;
        #100;
        reset = 1;
        #1000;

        $display("========================================");
        $display(" INICIANDO TESTBENCH EXHAUSTIVO");
        $display(" (Esto tomara un par de segundos...)");
        $display("========================================");

        for (int r1 = 0; r1 < 4; r1++) begin
            for (int c1 = 0; c1 < 4; c1++) begin
                for (int r2 = 0; r2 < 4; r2++) begin
                    for (int c2 = 0; c2 < 4; c2++) begin
                        
                        reset = 0; #100; reset = 1; #1000;
                        
                        press_key(r1, c1);
                        press_key(r2, c2);
                        
                        #100000; 
                        
                        expected_sum = get_hex(r1, c1) + get_hex(r2, c2);
                        
                        if (uut.suma !== expected_sum) begin
                            // Solo imprimimos el primer error para analizarlo facilmente
                            if (errores == 0) begin
                                $display(" [FALLO] Presionando teclas (%0d,%0d) y (%0d,%0d)", r1, c1, r2, c2);
                                $display(" Esperado: %0h, Obtenido de la FPGA: %0h", expected_sum, uut.suma);
                            end
                            errores++;
                        end
                        
                        pruebas_totales++;
                    end
                end
            end
        end

        $display("========================================");
        $display("      REPORTE FINAL DE SIMULACION       ");
        $display("========================================");
        $display(" Pruebas realizadas: %0d / 256", pruebas_totales);
        $display(" Total de errores:   %0d", errores);
        

        $finish;
    end
endmodule