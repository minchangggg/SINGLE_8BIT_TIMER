# `SINGLE 8 BIT TIMER`
<img width="100" alt="image" src="https://github.com/user-attachments/assets/6cdc11a2-f839-4609-b6ec-6817268e57f6">
A fully-synchronous 8-bit timer IP core with APB interface. Supports programmable clock sources, up/down counting modes, and interrupt generation. Designed and verified in Verilog with modular RTL and self-checking testbench.

## Block diagram
A Timer Module in its most basic form is a digital logic circuit that counts up or counts down every clock cycle.

<img width="1213" height="815" alt="image" src="https://github.com/user-attachments/assets/d181d54d-23d4-46a4-accb-d2dfd0a3d63b" />

## Register specification
| Offset | Register Name        | Description                 | Bit Width | Access | Reset Value |
|--------|----------------------|-----------------------------|-----------|--------|-------------|
| 0x00   | **TDR** (Timer Data) | Value to load into TCNT     | 8         | R/W    | 0           |
| 0x01   | **TCR** (Control)    | Control signals              | 8         | R/W    | 0           |
| 0x02   | **TSR** (Status)     | Status flags (e.g. overflow) | 8        | R/W    | 0           |
| 0x03   | **TCNT** (Counter)   | Current counter value        | 8         | R      | 0           |
