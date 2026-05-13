# Diseño digital sincrónico en HDL
**Gerald Blanco Sáenz 2022058334** **Julián Murillo Wo Ching 2024096679**

## 1. Resumen de Introducción

Este proyecto documenta el diseño y la implementación de un sistema digital sincrónico sobre una FPGA Tang Nano 9K. El sistema funciona como una calculadora aritmética capaz de capturar dos operandos decimales de tres dígitos cada uno a través de un teclado hexadecimal 4x4. El diseño utiliza una arquitectura basada en un reloj principal de 27 MHz, empleando máquinas de estados finitos (FSM) para la gestión de datos, lógica de corrección BCD para la suma y multiplexación temporal para el control de los displays de siete segmentos.

## 2. Definición del Problema y Objetivos

### Definición del Problema

El diseño de sistemas digitales modernos exige la integración de periféricos asíncronos (como teclados mecánicos) en dominios de reloj controlados. El reto principal consiste en capturar entradas secuenciales del usuario, procesar operaciones aritméticas en formato BCD (evitando la representación hexadecimal pura en el display) y gestionar la salida multiplexada de forma que sea legible para el ojo humano.

### Objetivos y Especificaciones

* **Objetivo General:** Desarrollar un sistema sincrónico integrado en HDL que procese operaciones aritméticas.
* **Especificaciones Técnicas:**
* Reloj de operación: 27 MHz (sincrónico).
* Entrada: Teclado matricial 4x4 con debouncing.
* Capacidad: Dos operandos de 3 dígitos (0-999).
* Salida: 4 displays de 7 segmentos (multiplexados).
* Lógica: Suma aritmética con corrección BCD.



## 3. Descripción General del Funcionamiento

El sistema opera mediante el flujo de datos desde el teclado hacia una FSM central. El módulo `teclado.sv` escanea constantemente las filas; al detectar una pulsación, el `debouncer` valida la señal. El módulo `sumador.sv` recibe la tecla y, según el estado actual (captura de primer número o segundo), desplaza los dígitos en registros internos. Una vez completada la entrada, se realiza la suma BCD y el resultado se envía al módulo `display.sv`, que se encarga de activar secuencialmente cada display para mostrar el valor final.

## 4. Diagramas de Bloques de Subsistemas
![Diagrama de bloques]

## 5. Diagramas de Estado de las FSM

El controlador central de la calculadora (`top.sv`) utiliza una Máquina de Estados Finita (FSM) para gestionar el flujo de ingreso de datos y la visualización de resultados. A continuación, se detallan las transiciones y acciones:

| Estado Actual | Entrada/Evento Significativo | Acción / Actualización de Datos | Próximo Estado | Visualización (d3, d2, d1, d0) |
| :--- | :--- | :--- | :--- | :--- |
| **TODOS** | Reset (S1) = 0 | Reiniciar registros (`reg_A=0`, `reg_B=0`, `digit_count=0`) | `INPUT_A` | `Apagado` `0` `0` `0` |
| **`INPUT_A`** | `valid_pulse`=1 **Y** `key_val` [0-9] **Y** `digit_count` < 3 | Construir número A: `reg_A = (reg_A * 10) + key_val`, `digit_count++` | `INPUT_A` | `Apagado` y Número A en progreso |
| **`INPUT_A`** | `valid_pulse`=1 **Y** `key_val` == `KEY_ENTER` (4'hF) | Reiniciar `digit_count=0` para el próximo número | `INPUT_B` | `Apagado` y Último Número A |
| **`INPUT_B`** | `valid_pulse`=1 **Y** `key_val` [0-9] **Y** `digit_count` < 3 | Construir número B: `reg_B = (reg_B * 10) + key_val`, `digit_count++` | `INPUT_B` | `Apagado` y Número B en progreso |
| **`INPUT_B`** | `valid_pulse`=1 **Y** `key_val` == `KEY_ENTER` (4'hF) | Calcular suma y conversión BCD (millares, centenas, decenas, unidades) | `RESULT` | Resultado Decimal (d3 dinámico) |
| **`RESULT`** | Ninguna (Espera inactiva) | Mantener visualización del resultado total | `RESULT` | Suma total calculada |

### FSM de Control (en `sumador.sv`)
1. **IDLE/NUM_A:** Estado inicial donde se reciben los dígitos del primer operando (unidades, decenas, centenas).
2. **WAIT_OP:** Espera la pulsación de una tecla de función (suma).
3. **NUM_B:** Captura del segundo operando siguiendo la misma lógica de desplazamiento.
4. **SUM_RESULT:** Realiza la suma y mantiene el resultado en el display hasta el `reset`.

### FSM de Teclado (en `teclado.sv`)

* Gestiona los estados de `ESPERA`, `DEBOUNCE` y `CONFIRMACIÓN` para evitar registros múltiples de una sola pulsación.

## 6. Simulación Funcional y Análisis

Para validar el sistema, se analizó el trayecto de una operación ejemplo: **123 + 456**.

* **Estímulo de Entrada:** Se simularon pulsaciones secuenciales en las columnas del teclado. El analizador lógico muestra cómo la señal `valid` se activa únicamente tras el periodo de estabilidad de 10ms.
* **Procesamiento:** Los registros internos se desplazan (unidades -> decenas -> centenas). En el estado de suma, se observa cómo el dígito de las unidades ($3+6=9$) no genera acarreo, pero si la suma excediera 9, la lógica BCD añade 6 para corregir el valor.
* **Manejo de 7 Segmentos:** La simulación confirma que el bus de segmentos cambia su valor en sincronía con la activación del ánodo correspondiente (`lit_digit`), permitiendo la persistencia de visión.


## 7. Análisis de Consumo de Recursos y Potencia
| Componente | Cantidad | Descripción |
| :--- | :--- | :--- |
| **LUT (Look-Up Tables)** | **528** | **Lógica combinacional principal** |
| LUT1 | 317 | Tablas 1-entrada |
| LUT2 | 71 | Tablas 2-entrada |
| LUT3 | 70 | Tablas 3-entrada |
| LUT4 | 70 | Tablas 4-entrada |
| **MUX** | **268** | **Multiplexores** |
| MUX2_LUT5 | 150 | MUX 2-entrada en LUT5 |
| MUX2_LUT6 | 72 | MUX 2-entrada en LUT6 |
| MUX2_LUT7 | 32 | MUX 2-entrada en LUT7 |
| MUX2_LUT8 | 14 | MUX 2-entrada en LUT8 |
| **DFF (Flip-Flops)** | **117** | **Elementos de memoria secuencial** |
| DFFCE | 78 | D-FF con Clock Enable |
| DFFC | 34 | D-FF con Clear |
| DFFE | 4 | D-FF con Enable |
| DFFP | 1 | D-FF con Preset |
| **I/O** | **21** | |
| IBUF | 6 | Buffers de entrada |
| OBUF | 15 | Buffers de salida |
| **Otros** | **2** | **GND, VCC** |


## 8. Reporte de Velocidades de Reloj

* **Frecuencia de Reloj del Diseño:** 27 MHz (Reloj físico de la Tang Nano 9K).
* **Velocidad Máxima Posible (Fmax):** El análisis de tiempos indica que el camino crítico (lógica de acarreo BCD en el sumador) permite una frecuencia máxima estimada de **~48.5 MHz**.
* **Cumplimiento:** Dado que 48.5 MHz > 27 MHz, el diseño cumple con los márgenes de tiempo requeridos y garantiza un comportamiento estable sin violaciones de setup o hold.

---

## Resultados de Laboratorio (Ejercicio 2)
