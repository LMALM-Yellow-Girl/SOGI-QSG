/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_lmalm_sogi_qsg (
    input  wire [7:0] ui_in,    // Entradas dedicadas (ej. para datos de red o configuración)
    output wire [7:0] uo_out,   // Salidas dedicadas (ej. para el ángulo theta o frecuencia)
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (0=input, 1=output)
    input  wire       ena,      // always 1 when powered
    input  wire       clk,      // Reloj del sistema
    input  wire       rst_n     // Reset activo en bajo
);

    // Señales internas para interconectar el SOGI y el PI en punto fijo
    wire signed [15:0] x_in_sig;
    wire signed [15:0] k_param;
    wire signed [15:0] omega_dt_param;
    wire signed [15:0] v_alpha_sig;
    wire signed [15:0] v_beta_sig;
    wire signed [15:0] omega_out_sig;

    // Asignaciones básicas de prueba con los pines de entrada (ui_in)
    // Expandimos los 8 bits de entrada a 16 bits con signo para el punto fijo
    assign x_in_sig       = { {8{ui_in[7]}}, ui_in }; 
    assign k_param        = 16'sd11585; // Ejemplo: valor fijo de k en Q2.14 (~sqrt(2))
    assign omega_dt_param = 16'sd100;   // Ejemplo: paso de frecuencia discretizado

    // Instanciación del Filtro SOGI-QSG
    sogi_qsg #(
        .WIDTH(16)
    ) inst_sogi (
        .clk(clk),
        .rst_n(rst_n),
        .x_in(x_in_sig),
        .k_gain(k_param),
        .omega_dt(omega_dt_param),
        .v_alpha(v_alpha_sig),
        .v_beta(v_beta_sig)
    );

    // Instanciación del Controlador PI
    pi_controller #(
        .WIDTH(16)
    ) inst_pi (
        .clk(clk),
        .rst_n(rst_n),
        .error_in(v_beta_sig), // Usamos la cuadratura como señal de error de fase simplificada
        .kp(16'sd16384),       // Ganancia proporcional en punto fijo
        .ki(16'sd100),         // Ganancia integral en punto fijo
        .omega_out(omega_out_sig)
    );

    // Mapeo de salidas: sacamos los bits más significativos de la frecuencia calculada hacia uo_out
    assign uo_out  = omega_out_sig[15:8]; 
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    // Control de señales no utilizadas para evitar advertencias del compilador
    wire _unused = &{ena, uio_in, 1'b0};

endmodule
