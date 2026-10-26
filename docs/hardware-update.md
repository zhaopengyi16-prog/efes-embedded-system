# Hardware and implementation update

Electronics for Embedded Systems | 26 October 2026

## Implementation

The system will record one analog input, store the samples in FPGA internal RAM, and replay them through a DAC. Recording and playback are separate. The existing STM32G431 board will send commands over hardware UART; the FPGA will handle sampling, memory access and playback in Verilog. The USART routines will be written using official CMSIS register definitions, without a ready-made UART driver. Input/output filtering and verification of the existing self-designed power section are included.

Development: Quartus Prime (preferably the course 18.1 setup) and Verilog; C/CMSIS in the existing G431 IDE; LTspice for analog circuits. Work and test records will be kept in Git.

## Hardware selection

| Function | Hardware | Status |
|---|---|---|
| Controller | Existing STM32G431 board; hardware UART. | Owned |
| FPGA / ADC | Terasic DE1-SoC with onboard LTC2308; one channel. | Loan pending |
| DAC | Pmod DA2 (DAC121S101), channel A at 3.3 V; or a suitable loan module. | Loan first |
| Analog stage | MCP6004-I/P and passive parts for conditioning and filters. | To be built |
| Power | Existing self-designed 12 V input section; nominal 3.3 / 5 / 7 V rails. | Reuse proposed |

## Expected result

Targets are nominal 12-bit conversion, 100 kS/s (initial tests at 50 kS/s), a signal bandwidth up to 2 kHz, and a 32 KiB buffer holding 16,384 samples. This gives a 163.84 ms record at 100 kS/s. The demonstration will record a signal, stop acquisition, change the current input, and replay the stored waveform through the DAC. The actual analog output will be checked using laboratory instruments or another agreed method.

These are targets, not measured results. Converter timing and reference scaling will be verified; power efficiency has not been measured. There is no continuous streaming or dedicated PC graphical interface in the baseline.

To confirm: DE1-SoC and DAC loan availability, laboratory access, the UART substitution, and reuse of the earlier power design.
