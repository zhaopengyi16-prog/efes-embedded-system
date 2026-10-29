# Software architecture

## Scope and evidence

Software / HDL locations are `stm32/` and `fpga/`. The STM32 project links CMSIS GPIO / USART2 polling drivers, a startup-message / byte-echo application, and official startup/system sources. Keil compilation and local register-mock checks passed. The FPGA project compiles a DE1-SoC LED/reset starter with board pins, a 20 ns clock constraint, and a passing behavioral testbench. No on-target runtime log exists yet. See the [system architecture](ARCHITECTURE.md) for context and the [project baseline](PROJECT_BASELINE.md) for source authority.

```text
stm32/EEFS.uvprojx
stm32/build.ps1
stm32/Control16-10-2026/APP/main.c
stm32/Control16-10-2026/BSP/{gpio.c,gpio.h,uart.c,uart.h}
stm32/Control16-10-2026/CMSIS/
fpga/build.ps1
fpga/rtl/efes_top.v
fpga/sim/efes_top_tb.v
fpga/sim/run.do
fpga/quartus/efes_fpga.qpf
fpga/quartus/efes_fpga.qsf
fpga/quartus/efes_fpga.sdc
```

## Planned responsibilities and integration status

| Component | Responsibility proposed by the starter | Source presence | Build inclusion | Runtime connection |
|---|---|---|---|---|
| STM32 firmware | Observe core clock, initialize UART, print startup text, and echo received bytes | `main.c`, official startup/system sources, and copied CMSIS headers are present | Keil `EEFS.uvprojx`, target `App`, includes APP, BSP, and official startup/system sources; compile/link/HEX generation passed | Reset handler -> `SystemInit` -> C runtime -> `main`; APP calls BSP initialization / polling; physical execution not tested |
| STM32 GPIO / UART drivers | GPIOA clock / AF setup; USART2 initialization, byte / string TX, and nonblocking RX with error discard | Four BSP files implement PA2 / PA3 AF7, HSI16, default 115200 / 8N1, and bounded polling | `gpio.c` and `uart.c` are compiled; Keil and local register-mock checks passed | `main` calls initialization, startup-string TX, and byte RX / echo TX; physical pin operation and inter-board use not verified |
| FPGA logic | Initial LED/reset starter; acquisition, storage, and playback remain planned | `efes_top.v` implements a two-stage reset release and clock-enabled blink counter | `efes_fpga.qpf` / `.qsf` select `5CSEMA5F31C6` and include the RTL and `.sdc`; full compilation/SOF/50 MHz timing passed | Top-level clock/reset drive the counter and LEDR0 in the fitted design; physical execution not tested |
| FPGA simulation | Verify starter reset, blink intervals, and recovery; storage/application checks remain planned | `efes_top_tb.v` and `run.do` are present | `build.ps1 -Simulate` invokes ModelSim 10.5b; simulation passed with zero errors/warnings | Testbench instantiates `efes_top`, drives clock/reset, and checks LED output; VCD generated |

The STM32 build contains project-authored `main.c`, implemented GPIO / UART drivers, and unmodified vendor CMSIS core/device and startup/system files. Compilation and host register checks do not establish successful physical UART operation. The FPGA starter is project-authored RTL and testbench code. No converter, sample memory, inter-board command protocol, or recording/playback implementation is included.

## Planned interfaces and ownership

The following application responsibilities remain provisional from v0.4, without implemented application interfaces. The starter clock/reset/LED ports do not define converter or inter-board contracts.

| Boundary | Planned owner and consumers | Details to define |
|---|---|---|
| STM32 <-> FPGA control | STM32 sends commands and receives status; FPGA handles commands and returns status | UART pins, levels, baud rate, frames, commands, responses, and error behavior |
| ADC <-> FPGA | FPGA owns sampling timing and the converter interface | Device configuration, conversion timing, data coding, and validity conditions |
| RAM | FPGA owns project-written address, write, read, and length control | Capacity, reset, valid sample count, and recording/playback boundaries |
| FPGA <-> DAC | FPGA owns playback scheduling and the DAC digital interface | Device model, timing, reference scaling, completion, and stop behavior |

Create independent EFES STM32 firmware as described in the starter; do not copy the complete earlier robot application. HAL/LL USART drivers are outside the proposed v0.4 implementation method. Confirm adoption of that proposal through the project baseline.

The author requested implementation of the GPIO / UART split for PC bring-up.
GPIO owns port clocks and pin register configuration. UART calls GPIO helpers
and owns its peripheral clock, format, baud rate, and byte transfers. APP owns
startup text and byte echo; future frame parsing, command / status semantics,
and FPGA control remain above the byte driver. The configured PA2 / PA3 mapping
requires actual board routing verification and defines no final inter-board
hardware contract. See `stm32/README.md` for API behavior, wiring, and references.

## Entry, scheduling, and data flow

- Linked MCU entry: official reset handler -> `SystemInit()` -> C runtime `__main` -> `main()`. APP observes the core clock, initializes USART2, sends one startup line, and polls / echoes valid bytes while incrementing a counter. UART explicitly selects HSI16 without changing SYSCLK / PLL selection. No application interrupt, DMA, or timer is used; physical execution is not yet verified.
- FPGA starter entry: `efes_top`, with one nominal 50 MHz clock, asynchronous reset assertion / synchronized release, and a 25,000,000-cycle LED toggle enable. QSF maps CLOCK_50/KEY0_N/LEDR0 to AF14/AA14/V16; SDC defines a 20 ns clock, asynchronous reset exception, and LED-only output exception. Setup/hold timing passed; application state machines and physical board execution remain pending.
- 100 kS/s is a sampling-rate target, not a configured interrupt period or an achieved timing result.
- Planned data paths are ADC -> FPGA -> RAM and RAM -> FPGA -> DAC, with separate recording and playback phases. No runtime connectivity or hardware measurement evidence exists yet.

## Project and code maintenance

- Record actual tool versions, build targets, linker / pin / timing configurations, and commands after creating real projects.
- Initial maintained sources include `main.c`, `efes_top.v`, and its testbench; follow nearby code when extending it. Preserve vendor files and their licenses without global reformatting.
- Protect future vendor libraries, generated code, IDE caches, and build outputs. Version-control project sources such as `.ioc`, startup files, linker scripts, `.qpf`, `.qsf`, and `.sdc` as required by the actual project.
- No shared architecture profile has been designated. Name, version, applicability, and authority are unbound; structural compatibility is `Not assessed`. Do not introduce unrelated automotive ACM framework constraints.
- No layer-local `AGENTS.md` files were added; root guidance and local build/readme instructions cover these small initial projects.

## Change navigation

| Change | Start here | Related checks |
|---|---|---|
| Define UART and board configuration | `stm32/README.md`, `hardware/README.md` | Actual pins, clocks, levels, and course scope; then define transmit/receive checks |
| FPGA acquisition and storage | `fpga/rtl/`, `fpga/sim/` | Confirm top level, device, and clock; then provide appropriate simulation evidence |
| Project configuration | `fpga/quartus/`, `stm32/` | Record actual tools, build commands, controlled configuration, and generated directories |
| Interface, power, or board changes | `hardware/`, `docs/PROJECT_BASELINE.md` | Update system boundaries and reassess affected tests |

The implemented STM32 UART project compiles, links, and generates AXF/HEX files, and local register-mock checks pass. The FPGA starter also passes full Quartus compilation, SOF generation, 50 MHz timing analysis, and behavioral simulation. Physical UART behavior, hardware execution, and the planned acquisition/storage/playback application have not been verified. Confirm the physical debug connection and UART routing before testing the startup line and echo; retain the pending functional/interface decisions before implementing the full application.
