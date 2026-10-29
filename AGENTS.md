# Project guidance

## Scope

These instructions apply to the entire repository. More specific nested `AGENTS.md` files, if added later, apply within their subtrees.

## Repository language

- Write all maintained repository content in English, including documentation, diagrams, code comments, and commit messages.
- Keep future repository updates in English. Do not introduce Chinese text into tracked files.
- Author-requested exception on 2026-10-29: Chinese explanatory comments are allowed in `stm32/Control16-10-2026/APP/main.c` and `BSP/{gpio.c,gpio.h,uart.c,uart.h}`. Keep identifiers, transmitted messages, other source files, and documentation in English.

## Read before changing

- `README.md`
- `docs/PROJECT_BASELINE.md`
- `docs/ARCHITECTURE.md`
- `docs/SOFTWARE_ARCHITECTURE.md`
- Task-relevant sections of `docs/hardware-update.md` and directory notes

## Working boundaries

- Complete only the user-authorized task. Initialization does not authorize implementation of every feature.
- The STM32G431RBT6 CMSIS project includes USART2 polling transmit/receive and an APP startup-message / byte-echo test. Keil compilation and local register-mock checks pass; physical GPIO/UART operation remains unverified. The DE1-SoC FPGA LED/reset starter passes Quartus compilation, behavioral simulation, and 50 MHz timing analysis. Acquisition/storage/playback logic and physical system operation remain unverified. Do not claim the complete system is operational.
- UART substitution for SPI, internal RAM, power-section reuse, and board/component selections remain provisional. Check the confirmations needed for the task before implementation.
- Do not infer runtime connection from directory names, function definitions, or build inclusion. Record source presence, build inclusion, runtime connection, and on-target verification separately.
- Do not move, delete, or overwrite original project materials, or automatically import the complete earlier robot project.
- Protect future third-party files, generated files, build outputs, and IDE caches. Retain required project, startup, linker, pin, and timing-constraint files.
- Avoid unrelated cleanup or build-system replacement. Read nearby maintained source files before editing and follow their local style. Do not impose a global restyle.
- Distinguish confirmed facts, inferences, design targets, and unresolved decisions.

## Git and public releases

- Inspect status and actual differences before and after a change. Preserve existing user changes.
- Subsequent commits, pushes, tags, and remote changes require authorization from the user's task. Do not discard changes or force-push without authorization.
- Keep original proposals, the starter ZIP, earlier diagrams, and local materials on the local machine according to `.gitignore`. Do not bypass exclusions with forced staging.
- Do not publish student identifiers, private contact information, credentials, emails, course slides, or unreviewed material from earlier projects.
- No open-source license has been selected. Do not grant a license on the user's behalf.

## Build and verification

- STM32 build: from the repository root, run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\stm32\build.ps1 -Rebuild`, or rebuild `stm32/EEFS.uvprojx` target `App`. Compile/link/HEX generation passed on 2026-10-29; hardware execution has not been tested.
- FPGA build: run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\fpga\build.ps1` from the repository root. The proposed DE1-SoC target is `5CSEMA5F31C6`; verify the actual board before programming. Full compilation, SOF generation, and 50 MHz static timing passed on 2026-10-29, with Lite Edition LogicLock notice 292013. See `fpga/README.md`.
- FPGA starter simulation: run the same script with `-Simulate`. ModelSim Starter 10.5b passed reset, blink intervals, and recovery checks with zero errors/warnings. This is not acquisition/storage/playback verification.
- Hardware verification: TODO; first confirm loans, pins, voltage levels, clocks, and supplies.
- Record/playback verification must observe the actual DAC analog output. Offline sample plots do not replace that check.
- Run only existing checks relevant to the change. Accurately distinguish "not run", "simulation passed", and "hardware passed".

## Completion criteria

Complete the requested scope, run relevant checks or explain why they were not run, and report actual changed files and unresolved items. Update the baseline or architecture documents only when the facts they record change.
