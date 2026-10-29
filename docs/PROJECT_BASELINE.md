# Project baseline

Reviewed: 2026-10-29 (STM32 UART bring-up implementation and initial FPGA project updates). Mode: development from existing multidisciplinary project materials. Baseline status: **Provisional**.

## Project identity and scope

- Name: EFES Single-Channel Signal Acquisition and Playback System.
- Domain: an Electronics for Embedded Systems individual project covering STM32, FPGA, analog circuits, and power verification.
- Initial boundary: one analog input and output, separate recording and playback, internal RAM storage, and DAC output; the STM32 provides configuration and control.
- Version reference: the supplied starter package's `manifest.json` identifies v0.4; the hardware update is dated 2026-10-26. A later date does not establish course approval.
- GitHub: `https://github.com/zhaopengyi16-prog/efes-embedded-system`. The user explicitly selected a public repository. Creation and synchronization must be verified through actual Git checks.

## Three input baselines

| Input | Source | Version and applicability | Authority and approval | Evidence status |
|---|---|---|---|---|
| Software project | Starter v0.4, author-created STM32 project, and explicit requests for initial projects, VS Code integration, and complete register-level UART bring-up | STM32G431RBT6 CMSIS GPIO / USART2 polling drivers and APP echo, plus DE1-SoC LED/reset HDL, constraints, and testbench | Project setup and PC UART bring-up are user-authorized; broader functional and inter-board decisions remain provisional | Both configured builds, local UART register-mock checks, and FPGA starter simulation verified; on-target execution Missing |
| Hardware and interfaces | `docs/hardware-update.md`, `docs/EFES_Hardware_Update_v0.4.docx`, and `docs/EFES_Hardware_Update_v0.4.pdf` | 2026-10-26; STM32G431, DE1-SoC / LTC2308, candidate DAC, and analog circuits | Provisional proposal; loans, pins, voltage levels, schematics, and power reuse are unapproved or unverified | Found—authority unknown; final interface definition Missing |
| Functional requirements | Original proposal DOCX / PDF in the root directory, local only; supplemented by the public v0.4 hardware update | Single-channel recording and playback; no explicit original proposal version found; converter resolution and control-link proposals differ | No course confirmation or complete requirements baseline supplied | Found—authority unknown; precedence Needs confirmation |

Evidence labels are `Provided`, `Found—authority unknown`, `Missing`, `Not applicable`, and `Needs confirmation`. They distinguish availability, authority, and readiness for implementation.

## Source relationships and unresolved differences

| Topic | Original proposal / earlier diagram | v0.4 starter material | Current treatment |
|---|---|---|---|
| STM32 control link | The original proposal uses SPI; the diagram still lists SPI / UART / CAN options | Hardware UART using CMSIS register definitions, without ready-made HAL/LL USART drivers | Record as a provisional update; confirm whether the substitution is acceptable |
| Power | A new low-voltage DC-DC design, with parameters still undefined | Proposed reuse of the existing self-designed 12 V input section | Confirm reuse scope, course acceptance, and measurements |
| Converter resolution | The PDF states nominal 12/16-bit; the parameters DOCX specifies an initial 12-bit target | Nominal 12-bit target | Record v0.4 provisionally; do not present it as a measurement |
| Hardware and storage | Boards, components, and internal / external storage remain open | Loaned DE1-SoC, onboard LTC2308, internal RAM, and candidate DAC | Confirm loans, resource configuration, and whether internal RAM meets the course requirement |

Reasonable inference: v0.4 is a later working draft of the earlier proposal, based on its update date and content. This does not replace approval by the project author or course supervisor. Resolve relevant implementation conflicts before updating this baseline; do not automatically treat either source as approved requirements.

No external authoritative system or course approval record has been provided. No shared architecture profile has been designated; compatibility is `Not assessed`.

## Configuration and initialization boundaries

- Planned tools from the starter: Quartus Prime, preferably the course's 18.1 setup; Verilog; the existing G431 IDE or STM32CubeIDE; C/CMSIS; and LTspice.
- Confirmed target: STM32G431RBT6 (author-provided), selected as `STM32G431RBTx`. The firmware retains SYSCLK / PLL selection and explicitly selects nominal HSI16 / 16 MHz for USART2. PA2 TX / PA3 RX, AF7, default 115200 / 8N1 are configured for PC bring-up; physical board routing, debug probe, and COM bridge operation remain unverified.
- Verified local STM32 tools: Keil MDK 5.43a / Arm Compiler 6.24 at `D:\Keil_v5`, MDK Community activated for non-commercial use, and `Keil.STM32G4xx_DFP.1.6.0`. Copied core headers originate from Arm CMSIS 6.2.0. Build entry: `stm32/build.ps1`, also invoked by the VS Code build task; see `stm32/README.md`.
- Verified local FPGA tools: Quartus Prime Lite 18.1.0 Build 625 with Cyclone V support and ModelSim - Intel FPGA Starter Edition 10.5b at `D:\intelFPGA_lite\18.1`. Build entry: `fpga/build.ps1`; simulation uses `-Simulate`. The DE1-SoC software target, 50 MHz clock, KEY0 reset, and LEDR0 constraints follow the proposed board and the Terasic manual linked in `fpga/README.md`. The actual loaned board/revision remains unverified.
- Git setup: `main` branch, initialization commit, and connection to the public repository above. Commit identity uses the account-associated noreply email address.
- The five original input files remain in their original locations and are not rearranged or rewritten. They are outside the public repository contents.
- All 12 archived project files passed the package manifest's SHA-256 checks. Initialization adjusted the root README and ignore rules and added project guidance; other starter files retained their original bytes.
- On 2026-10-29, initial STM32 compilation/linking/AXF/HEX generation and FPGA synthesis/fitting/assembly/SOF generation/50 MHz timing analysis passed. FPGA starter behavioral simulation passed. The Quartus build retains Lite Edition notice 292013; on-target execution, full application verification, and analog/power measurements have not been run.
- UART implementation on 2026-10-29 passed a full Keil rebuild with zero errors / warnings and local register-mock checks for configuration, data values, timeout paths, and receive-error discard commands. APP calls initialization and implements startup output / echo; no on-target UART or FPGA command exchange has been tested.
- Maintained repository content remains in English except for Chinese explanatory comments explicitly requested by the author in the APP / BSP UART bring-up sources; see `AGENTS.md` for the bounded exception.

## Open decisions

1. The project author must confirm the course-approved functional sources and the applicability of SPI-to-UART substitution, power reuse, and internal RAM.
2. Confirm FPGA / DAC loans, laboratory access, actual board revisions, and instruments.
3. Confirm voltage range, output load, supply boundaries, reference voltages, timing, and UART command format.
4. Initial STM32 and FPGA targets, tool versions, and reproducible build/simulation commands are recorded. Functional requirements, actual loaned board revision, application interfaces, and physical integration remain pending.

## Update triggers

Update this file when functional sources or approval status, hardware revisions, interfaces, components, tool configurations, target variants, or release baselines change. See the [system architecture](ARCHITECTURE.md) for system boundaries and the [software architecture](SOFTWARE_ARCHITECTURE.md) for software details.
