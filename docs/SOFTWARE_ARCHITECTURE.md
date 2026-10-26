# Software architecture

## Scope and evidence

Software / HDL locations are `stm32/` and `fpga/`. The starter provides directory notes only. No STM32 project, Quartus project, C source, Verilog source, simulation testbench, or runtime log exists yet. See the [system architecture](ARCHITECTURE.md) for context and the [project baseline](PROJECT_BASELINE.md) for source authority.

```text
stm32/README.md
fpga/rtl/.gitkeep
fpga/sim/.gitkeep
fpga/quartus/.gitkeep
```

## Planned responsibilities and integration status

| Component | Responsibility proposed by the starter | Source presence | Build inclusion | Runtime connection |
|---|---|---|---|---|
| STM32 firmware | Configure hardware UART through C/CMSIS registers; send commands and receive status | Not evidenced in inspected scope; only `stm32/README.md` exists | Not evidenced in inspected scope; no project or target | Not evidenced in inspected scope; no entry, initialization, or caller path |
| FPGA logic | Implement acquisition, storage control, and playback in Verilog | Not evidenced in inspected scope; `fpga/rtl/` contains a placeholder only | Not evidenced in inspected scope; no `.qpf` / `.qsf` | Not evidenced in inspected scope; no top level, clock configuration, or state machine |
| FPGA simulation | Verify storage and primary operating states | Not evidenced in inspected scope; `fpga/sim/` contains a placeholder only | Not evidenced in inspected scope; no simulation configuration | Not evidenced in inspected scope; no testbench or result |

Directory and placeholder existence is `Confirmed`. This does not prove source presence, build integration, runtime connection, or successful hardware execution. There is currently no production, vendor, or generated source to classify.

## Planned interfaces and ownership

The following are provisional responsibilities from v0.4, without public headers, port definitions, or implementations yet.

| Boundary | Planned owner and consumers | Details to define |
|---|---|---|
| STM32 <-> FPGA control | STM32 sends commands and receives status; FPGA handles commands and returns status | UART pins, levels, baud rate, frames, commands, responses, and error behavior |
| ADC <-> FPGA | FPGA owns sampling timing and the converter interface | Device configuration, conversion timing, data coding, and validity conditions |
| RAM | FPGA owns project-written address, write, read, and length control | Capacity, reset, valid sample count, and recording/playback boundaries |
| FPGA <-> DAC | FPGA owns playback scheduling and the DAC digital interface | Device model, timing, reference scaling, completion, and stop behavior |

Create independent EFES STM32 firmware as described in the starter; do not copy the complete earlier robot application. HAL/LL USART drivers are outside the proposed v0.4 implementation method. Confirm adoption of that proposal through the project baseline.

## Entry, scheduling, and data flow

- Actual MCU entry, clock initialization, main loop / interrupts, and call order: TODO; no source evidence.
- Actual FPGA top level, reset, clock domains, enables, and state transitions: TODO; no HDL or constraint evidence.
- 100 kS/s is a sampling-rate target, not a configured interrupt period or an achieved timing result.
- Planned data paths are ADC -> FPGA -> RAM and RAM -> FPGA -> DAC, with separate recording and playback phases. No runtime connectivity or hardware measurement evidence exists yet.

## Project and code maintenance

- Record actual tool versions, build targets, linker / pin / timing configurations, and commands after creating real projects.
- No maintained source exists from which to establish naming, indentation, braces, types, or error-handling conventions. Future changes must inspect and follow nearby maintained files without global reformatting.
- Protect future vendor libraries, generated code, IDE caches, and build outputs. Version-control project sources such as `.ioc`, startup files, linker scripts, `.qpf`, `.qsf`, and `.sdc` as required by the actual project.
- No shared architecture profile has been designated. Name, version, applicability, and authority are unbound; structural compatibility is `Not assessed`. Do not introduce unrelated automotive ACM framework constraints.
- No layer-local `AGENTS.md` files were created: actual modules and local code conventions do not exist yet, and root guidance covers the current scope.

## Change navigation

| Change | Start here | Related checks |
|---|---|---|
| Define UART and board configuration | `stm32/README.md`, `hardware/README.md` | Actual pins, clocks, levels, and course scope; then define transmit/receive checks |
| FPGA acquisition and storage | `fpga/rtl/`, `fpga/sim/` | Confirm top level, device, and clock; then provide appropriate simulation evidence |
| Project configuration | `fpga/quartus/`, `stm32/` | Record actual tools, build commands, controlled configuration, and generated directories |
| Interface, power, or board changes | `hardware/`, `docs/PROJECT_BASELINE.md` | Update system boundaries and reassess affected tests |

Only repository and documentation initialization is complete. Builds, simulations, timing analysis, and hardware execution have not been run. Next, confirm source authority and scope before preparing complete functional requirements and implementation tasks.
