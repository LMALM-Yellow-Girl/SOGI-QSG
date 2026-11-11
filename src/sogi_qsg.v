module sogi_qsg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire signed [WIDTH-1:0] x_in,     // Señal de entrada de red discretizada
    input wire signed [WIDTH-1:0] k_gain,     // Ganancia k de amortiguamiento (ej. sqrt(2) o 1.414 en fijo)
    input wire signed [WIDTH-1:0] omega_dt,   // Frecuencia angular multiplicada por el periodo de muestreo (w*Ts)
    output reg signed [WIDTH-1:0] v_alpha,    // Señal filtrada en fase
    output reg signed [WIDTH-1:0] v_beta      // Señal filtrada en cuadratura (desfasada 90°)
);

    // Registros internos para los integradores (punto fijo)
    reg signed [31:0] error;
    reg signed [31:0] term1, term2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_alpha <= 0;
            v_beta  <= 0;
        end else begin
            // Cálculo de las ecuaciones en diferencias del SOGI
            // error = x_in - v_alpha
            error = {{16{x_in[WIDTH-1]}}, x_in} - {{16{v_alpha[WIDTH-1]}}, v_alpha};
            
            // term1 = k * error - v_beta
            term1 = ((error * {{16{k_gain[WIDTH-1]}}, k_gain}) >>> 14) - {{16{v_beta[WIDTH-1]}}, v_beta};
            
            // Actualización de v_alpha y v_beta usando la integración digital
            v_alpha <= v_alpha + (((term1 * {{16{omega_dt[WIDTH-1]}}, omega_dt}) >>> 14));
            v_beta  <= v_beta  + (((v_alpha * {{16{omega_dt[WIDTH-1]}}, omega_dt}) >>> 14));
        end
    end
endmodule