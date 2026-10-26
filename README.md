# EFES Single-Channel Signal Acquisition and Playback System

An Electronics for Embedded Systems individual project: acquire one analog signal, store the samples in FPGA internal RAM, and reproduce the stored waveform through a DAC. The STM32 provides configuration and control; the FPGA handles acquisition, storage, and playback timing.

**Status: project initialization and planning. This repository does not yet contain buildable STM32 firmware, a Verilog implementation, or measured results.**

## Scope and targets

- One analog input and one analog output, with separate recording and playback phases.
- Initial targets: nominal 12-bit conversion, 100 kS/s, and a signal bandwidth up to 2 kHz. Initial interface tests may use 50 kS/s.
- Target buffer: 32 KiB, holding 16,384 samples as 16-bit words. At 100 kS/s, this gives a recording length of 163.84 ms.
- The scope includes input conditioning, anti-alias filtering, output reconstruction filtering, and performance verification of the existing self-designed power section.
- The provisional analog range is 0.3-2.7 V, with an output load of at least 10 kohm. Actual components and measurements must confirm these limits.
- Continuous streaming, multiple channels, and a dedicated PC graphical interface are outside the initial scope.

These values are design targets, not measurements. They do not establish 12-bit effective accuracy, achieved timing closure, or verified power efficiency.

## Current planning sources

The supplied v0.4 starter package and [hardware update](docs/hardware-update.md) form the provisional working proposal. The earlier proposal used SPI and a new DC-DC design; v0.4 proposes UART and reuse of the existing power section. These changes still require confirmation. Source identities and approval status are recorded in the [project baseline](docs/PROJECT_BASELINE.md).

| Subsystem | Provisional v0.4 selection | Status |
|---|---|---|
| Controller | Existing STM32G431 development board; hardware UART | Listed as owned in the supplied material; actual board revision, pins, and clocks need verification |
| FPGA / ADC | Loaned Terasic DE1-SoC and onboard LTC2308; one ADC channel | Loan pending; the ADC is on the development board |
| Sample memory | FPGA internal RAM with project-written control logic | Not implemented; course acceptance needs confirmation |
| DAC | Prefer a suitable loan module; backup: Pmod DA2 / DAC121S101, channel A at 3.3 V | Model, interface, and availability need confirmation |
| Analog circuits | MCP6004-I/P and passive components | Design and simulation pending |
| Power | Existing self-designed 12 V input section with nominal 3.3 / 5 / 7 V rails | Reuse and output performance need confirmation |

Power each development board through its specified input. Before making connections, verify actual revisions, pins, voltage levels, and supplies. Do not parallel regulator outputs.

## Getting started

1. Read the [project baseline](docs/PROJECT_BASELINE.md), [system architecture](docs/ARCHITECTURE.md), and [software architecture](docs/SOFTWARE_ARCHITECTURE.md).
2. Confirm FPGA / DAC loans, laboratory access, UART substitution for SPI, the internal RAM approach, and the permitted scope of power-section reuse.
3. Confirm the actual boards and tool versions, then create the STM32 and Quartus projects and record their real build procedures.

The supplied material proposes Quartus Prime, preferably the course's 18.1 setup; Verilog; C/CMSIS in the existing G431 IDE or STM32CubeIDE; and LTspice. Installed tools, device support packages, project configurations, and build commands have not been verified.

**Builds, simulations, and hardware tests: not run. There is no executable project or testbench yet.**

## Repository structure

```text
docs/           Baseline, architecture, and v0.4 hardware update
stm32/          Firmware location and preparation notes
fpga/rtl/       Reserved location for Verilog modules
fpga/sim/       Reserved location for simulation testbenches
fpga/quartus/   Reserved location for Quartus projects and pin/timing constraints
hardware/       Wiring, analog circuits, and component records
tests/          Verification records
AGENTS.md       Guidance for future development
```

## Verification approach

Verify RAM read/write behavior with known data, UART command responses, and the ADC / DAC interfaces independently before integrating recording and playback. The demonstration must stop acquisition, change the present input, and observe the actual DAC analog output replaying the stored waveform. Record instruments, hardware revisions, source commits, conditions, and raw results. Power ripple, regulation, and efficiency remain unmeasured.

## Public repository boundary

The original starter archive, earlier proposals, and earlier block diagrams remain local and are excluded by `.gitignore`. Original files containing student identifiers are not published. Public contents comprise the reviewed starter structure, v0.4 hardware update, and initialization documents. Do not upload course slides, professor emails, account credentials, or the complete earlier robot project. No open-source license has been selected; retain third-party notices when adding third-party material.

All maintained repository content must be written in English.

Next step: confirm source authority and the proposed scope, then prepare the complete functional requirements.
