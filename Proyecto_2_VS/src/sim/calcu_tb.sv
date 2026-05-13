`timescale 1ns/1ps

module calcu_tb;

    //Registros para el DUT 
    logic clk;
    logic rst;

    logic [3:0] col;
    logic  [3:0] row;

    logic [3:0] lit_digit;
    logic [6:0] lit_segs;

    //Instanciar DUT
    top dut (
        .clk(clk),
        .reset(rst),
        .col(col),
        .row(row),
        .lit_digit(lit_digit),
        .lit_segs(lit_segs)
    );


    //Generacion del reloj
    initial begin
        clk = 0;
        forever #18.5 clk = ~clk;
    end

    //Helper task
    task press_key(
        input [3:0] target_row,
        input [3:0] target_col
    );
    begin

        // Esperar row deseado
        wait(row == target_row);

        // Simular columna apretada
        col = target_col;

        // Esperar debounce
        #15000000;

        //Mostrar entradas y salidas deseadas
        $display("time=%b | row=%b | col=%b | digit=%b | segs=%b",
                    $time, row, col, lit_digit, lit_segs);


        // Soltar tecla
        col = 4'b0000;

        // Esperar entre teclas
        #5000000;

    end
    endtask

    initial begin
        $dumpfile("calcu_tb.vcd");
        $dumpvars(0, calcu_tb);


        // Initialize
        rst = 0;
        col = 4'b0000;

        #1000;
        rst = 1;

        // ========================================================
        // Estado NUM_A
        // ========================================================

        press_key(4'b0001, 4'b1000);

        // Enter 1
        press_key(4'b0001, 4'b0001);

        // Enter 2
        press_key(4'b0001, 4'b0010);

        // Enter 3
        press_key(4'b0001, 4'b0100);

        // ========================================================
        // Estado NUM_B
        // ========================================================

        press_key(4'b0010, 4'b1000);

        // Enter 4
        press_key(4'b0010, 4'b0001);

        // Enter 5
        press_key(4'b0010, 4'b0010);

        // Enter 6
        press_key(4'b0010, 4'b0100);

        // ========================================================
        // Estado SUM_C
        // ========================================================

        press_key(4'b0100, 4'b1000);

        #20000000;

        $finish;

    end

endmodule