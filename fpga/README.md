# FPGA starter

## Target and behavior

This initial project targets the **Terasic DE1-SoC** proposed in the hardware
baseline. The loaned board and its physical revision have not been inspected.
The software build target is Cyclone V `5CSEMA5F31C6` (board device marking
`5CSEMA5F31C6N`); do not select this target for a different board.

`rtl/efes_top.v` uses the nominal 50 MHz board clock to toggle LEDR0 every
25,000,000 cycles: 0.5 seconds per state, or a nominal 1 Hz blink. Hold KEY0
and release it to reset and restart the counter. Reset assertion is asynchronous
at the two-stage synchronizer; its release is synchronized. The LED and counter
are cleared on a clock edge. No divided signal is used as a new clock.

| Top-level port | Board signal | FPGA pin | I/O standard |
|---|---|---|---|
| `CLOCK_50` | CLOCK_50, 50 MHz input | AF14 | 3.3-V LVTTL |
| `KEY0_N` | KEY[0], pressed = low | AA14 | 3.3-V LVTTL |
| `LEDR0` | LEDR[0], active high | V16 | 3.3-V LVTTL |

These assignments come from the clock, button, and LED tables in the
[Terasic DE1-SoC user manual, January 28, 2019](https://community.altera.com/t5/s/jgyke29768/attachments/jgyke29768/fpga-device/73098/1/DE1-SoC_User_manual_revf.pdf).
The LED has explicit 4 mA drive strength and slow slew. Unused user pins are
reserved as tri-stated inputs. ADC, RAM, DAC, UART, HPS, and recording/playback
logic are outside this starter.

## Edit and build

Open the repository's `EFES.code-workspace` in VS Code. Verilog editing uses
the `mshr-h.VerilogHDL` extension; version 1.29.0 is installed on this computer.
Save changes, press **Ctrl+Shift+B**, and select **EFES: Build FPGA**. Select
**EFES: Build STM32** to build the existing firmware instead.

The equivalent command from the repository root is:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\fpga\build.ps1
```

The script invokes `quartus_sh --flow compile efes_fpga` from `fpga/quartus`.
It checks the process result and the SOF output, and propagates compilation
failures to VS Code. The verified local tool is Quartus Prime Lite 18.1.0
Build 625 at `D:\intelFPGA_lite\18.1\quartus`, with Cyclone V support.
Set `QUARTUS_ROOTDIR` or pass `-QuartusRoot` to use another installation.

The same project can be opened in Quartus as `quartus/efes_fpga.qpf`.
Add new RTL files to `quartus/efes_fpga.qsf` using `VERILOG_FILE` assignments
before expecting them to participate in compilation. Testbenches belong in
`sim/` and must not be added as synthesis sources.

## Constraints and generated files

- `quartus/efes_fpga.sdc` defines one 20 ns clock and derives clock uncertainty.
- The asynchronous button reset is excluded from synchronous input timing.
- The LED output has no external synchronous receiver, so it has a false-path
  exception. Do not extend that exception to future UART/ADC/DAC interfaces;
  define their real timing requirements separately.
- `quartus/output_files/efes_fpga.sof` is the generated programming file.
- Fitter, pin, and timing reports are in `quartus/output_files/`.
- Tool logs are in `build/`; Quartus databases and simulator outputs are ignored
  by Git. Project `.qpf` / `.qsf`, `.sdc`, RTL, and simulation sources are retained.

## Simulation

Run **Terminal > Run Task > EFES: Simulate FPGA**, or:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\fpga\build.ps1 -Simulate
```

The verified simulator is ModelSim - Intel FPGA Starter Edition 10.5b,
bundled with Quartus 18.1 at `D:\intelFPGA_lite\18.1\modelsim_ase\win32aloem`.
Set `MODELSIM_ROOT` or pass `-ModelSimRoot` to change that executable directory.
`sim/run.do` runs the behavioral testbench with a four-cycle blink half-period
and checks reset, 80 ns high/low intervals, and recovery after reset. The test
must print `PASS: FPGA starter simulation` and exit successfully.
The waveform is `build/sim/efes_top_tb.vcd`.

## Verification boundary

On 2026-10-29, complete Quartus synthesis, fitting, assembly, SOF generation,
and 50 MHz static timing analysis passed. The final build has zero errors and
one warning: `292013`, the Lite Edition notice about the subscription-only
LogicLock feature. This starter does not assign a LogicLock region; no paid
feature is needed for its successful build. The missing LED drive/slew warning
from the first build was resolved with explicit output assignments.

Behavioral simulation passed with zero errors and zero warnings. This checks
the starter behavior, not the planned acquisition/storage/playback application.
No JTAG download, configuration-flash write, physical LED test, or analog test
has been performed. Confirm the actual board and its existing configuration
before programming it.
