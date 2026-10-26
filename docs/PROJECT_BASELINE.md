# Project baseline

Reviewed: 2026-10-27. Mode: initialization from existing multidisciplinary project materials. Baseline status: **Provisional**.

## Project identity and scope

- Name: EFES Single-Channel Signal Acquisition and Playback System.
- Domain: an Electronics for Embedded Systems individual project covering STM32, FPGA, analog circuits, and power verification.
- Initial boundary: one analog input and output, separate recording and playback, internal RAM storage, and DAC output; the STM32 provides configuration and control.
- Version reference: the supplied starter package's `manifest.json` identifies v0.4; the hardware update is dated 2026-10-26. A later date does not establish course approval.
- GitHub: `https://github.com/zhaopengyi16-prog/efes-embedded-system`. The user explicitly selected a public repository. Creation and synchronization must be verified through actual Git checks.

## Three input baselines

| Input | Source | Version and applicability | Authority and approval | Evidence status |
|---|---|---|---|---|
| Software project | Local `EFES_Local_First_Setup.zip`, under `EFES_Project_Starter/project/`; working-tree paths `stm32/` and `fpga/` | Starter v0.4; no `.ioc`, `.qpf`, build entry, firmware, or HDL | Initialization material in the user-designated directory; not yet a configured software project | Found—authority unknown; software project Missing |
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
- Local installations, exact versions, target devices, clocks, pins, build configurations, and test commands: TODO.
- Git setup: `main` branch, initialization commit, and connection to the public repository above. Commit identity uses the account-associated noreply email address.
- The five original input files remain in their original locations and are not rearranged or rewritten. They are outside the public repository contents.
- All 12 archived project files passed the package manifest's SHA-256 checks. Initialization adjusted the root README and ignore rules and added project guidance; other starter files retained their original bytes.
- Builds, simulations, on-target tests, and analog / power measurements: not run.
- Maintained repository content is required to be in English.

## Open decisions

1. The project author must confirm the course-approved functional sources and the applicability of SPI-to-UART substitution, power reuse, and internal RAM.
2. Confirm FPGA / DAC loans, laboratory access, actual board revisions, and instruments.
3. Confirm voltage range, output load, supply boundaries, reference voltages, timing, and UART command format.
4. After creating real projects, record build targets, tool versions, and reproducible commands before completing the requirements baseline.

## Update triggers

Update this file when functional sources or approval status, hardware revisions, interfaces, components, tool configurations, target variants, or release baselines change. See the [system architecture](ARCHITECTURE.md) for system boundaries and the [software architecture](SOFTWARE_ARCHITECTURE.md) for software details.
