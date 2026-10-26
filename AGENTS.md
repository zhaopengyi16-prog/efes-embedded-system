# Project guidance

## Scope

These instructions apply to the entire repository. More specific nested `AGENTS.md` files, if added later, apply within their subtrees.

## Repository language

- Write all maintained repository content in English, including documentation, diagrams, code comments, and commit messages.
- Keep future repository updates in English. Do not introduce Chinese text into tracked files.

## Read before changing

- `README.md`
- `docs/PROJECT_BASELINE.md`
- `docs/ARCHITECTURE.md`
- `docs/SOFTWARE_ARCHITECTURE.md`
- Task-relevant sections of `docs/hardware-update.md` and directory notes

## Working boundaries

- Complete only the user-authorized task. Initialization does not authorize implementation of every feature.
- The repository currently contains planning material and a directory scaffold, with no firmware, HDL, configured build, or testbench. Do not claim it is operational.
- UART substitution for SPI, internal RAM, power-section reuse, and board/component selections remain provisional. Check the confirmations needed for the task before implementation.
- Do not infer runtime connection from directory names, function definitions, or build inclusion. Record source presence, build inclusion, runtime connection, and on-target verification separately.
- Do not move, delete, or overwrite original project materials, or automatically import the complete earlier robot project.
- Protect future third-party files, generated files, build outputs, and IDE caches. Retain required project, startup, linker, pin, and timing-constraint files.
- Avoid unrelated cleanup or build-system replacement. Read nearby maintained source files before editing and follow their local style. There is currently no source from which to infer a global coding style.
- Distinguish confirmed facts, inferences, design targets, and unresolved decisions.

## Git and public releases

- Inspect status and actual differences before and after a change. Preserve existing user changes.
- Subsequent commits, pushes, tags, and remote changes require authorization from the user's task. Do not discard changes or force-push without authorization.
- Keep original proposals, the starter ZIP, earlier diagrams, and local materials on the local machine according to `.gitignore`. Do not bypass exclusions with forced staging.
- Do not publish student identifiers, private contact information, credentials, emails, course slides, or unreviewed material from earlier projects.
- No open-source license has been selected. Do not grant a license on the user's behalf.

## Build and verification

- STM32 build: TODO; no project has been created; not run.
- FPGA build and simulation: TODO; no Quartus project, HDL, or testbench exists; not run.
- Hardware verification: TODO; first confirm loans, pins, voltage levels, clocks, and supplies.
- Record/playback verification must observe the actual DAC analog output. Offline sample plots do not replace that check.
- Run only existing checks relevant to the change. Accurately distinguish "not run", "simulation passed", and "hardware passed".

## Completion criteria

Complete the requested scope, run relevant checks or explain why they were not run, and report actual changed files and unresolved items. Update the baseline or architecture documents only when the facts they record change.
