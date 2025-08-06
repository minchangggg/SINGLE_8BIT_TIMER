# `SINGLE 8 BIT TIMER`
A fully-synchronous 8-bit timer IP core with APB interface. Supports programmable clock sources, up/down counting modes, and interrupt generation. Designed and verified in Verilog with modular RTL and self-checking testbench.
## Block diagram
A Timer Module in its most basic form is a digital logic circuit that counts up or counts down every clock cycle.
<img width="1379" height="924" alt="image" src="https://github.com/user-attachments/assets/0be5c881-fae3-41f1-ae79-f9e89cc17d27" />
## Register specification
| Offset | Register Name        | Description                 | Bit Width | Access | Reset Value |
|--------|----------------------|-----------------------------|-----------|--------|-------------|
| 0x00   | **TDR** (Timer Data) | Value to load into TCNT     | 8         | R/W    | 0           |
| 0x01   | **TCR** (Control)    | Control signals              | 8         | R/W    | 0           |
| 0x02   | **TSR** (Status)     | Status flags (e.g. overflow) | 8        | R/W    | 0           |
| 0x03   | **TCNT** (Counter)   | Current counter value        | 8         | R      | 0           |
