module clock_ej2 (
    input logic clk_27mhz,
    input logic rst_n,
    output logic clk_1p8432mhz
);

    // 27,000,000 / 1,843,200 = 14.6484375 (not integer)
    // Use counter to toggle at half the desired ratio
    
    // Better approach: Use integer ratio 27MHz / 1.8432MHz = 14.648
    // Multiply by 100 to work with integers: 27,000,000 / 1,843,200 = 270/18.432
    
    // Simplified: 1.8432MHz = 27MHz / 14.648
    // Use counter that counts to 15, but duty cycle adjustment
    
    reg [3:0] count;  // 0-15
  
    always @(posedge clk_27mhz or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            clk_1p8432mhz <= 0;
        end else begin
            if (count == 6) begin
                count <= 0;
                clk_1p8432mhz <= ~clk_1p8432mhz;
            end else begin
                count <= count + 1;
            end
        end
    end

endmodule