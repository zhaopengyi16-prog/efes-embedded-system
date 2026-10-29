# STM32 firmware

## Initial project

Open `EEFS.uvprojx` in Keil, or open `../EFES.code-workspace` in VS Code.
The existing project name `EEFS`, current target `App`, and user-created
`Control16-10-2026` directory have been retained.

- Device: STM32G431RBT6, selected as `STM32G431RBTx` in Keil.
- Toolchain: Keil MDK 5.43a with Arm Compiler 6.24.
- Device pack: `Keil.STM32G4xx_DFP.1.6.0`.
- Core headers: copied from the installed Arm CMSIS 6.2.0 pack.
- Flash: `0x08000000`, size `0x20000` (128 KiB).
- RAM: `0x20000000`, size `0x8000` (32 KiB, including the CCM alias).
- Preprocessor definition: `STM32G431xx`; no HAL or LL driver is enabled.
- Startup: the official `startup_stm32g431xx.s` and `system_stm32g4xx.c`.
- Outputs: `build/EEFS.axf`, `build/EEFS.hex`, and build logs.

The program observes `g_core_clock_hz`, initializes USART2, sends one startup
message, and echoes valid received bytes. It preserves the current system-clock
and PLL selection, explicitly enabling HSI16 and selecting it for USART2.
`SystemCoreClockUpdate()` computes a software value; it is not a frequency
measurement and does not switch clocks. No timer is used for UART operation.

The existing `CMSIS/Dvice` folder spelling and STM32 headers in
`CMSIS/Core/Include` are preserved. The configured include and source paths
match those files; no vendor implementation has been edited. See
`Control16-10-2026/CMSIS/THIRD_PARTY.md` for provenance and licenses.

## Register-level UART configuration

| Item | Configured value |
|---|---|
| Peripheral | USART2 |
| TX / RX | PA2 / PA3, AF7; verify actual board routing before connecting |
| GPIO | Push-pull, medium output speed, pull-up; only the selected pin fields change |
| UART clock | HSI16, nominal 16 MHz, selected through `RCC->CCIPR` |
| Prescaler / oversampling | Divide by 1 (`PRESC = 0`) / 16 (`OVER8 = 0`) |
| Baud / format | 115200, 8 data bits, no parity, 1 stop bit, no RTS/CTS |
| Baud divisor | Rounded `16000000 / 115200`, so `BRR = 139` |
| Transfer method | Polling; FIFO, interrupts, DMA, and hardware flow control disabled |

`BSP/gpio.c` owns GPIOA clock and pin configuration. This first implementation
supports GPIOA only and rejects PA13 / PA14 to preserve SWD access.
`BSP/uart.c` owns the USART2 clock, reset, format, and byte transfers, calling
the GPIO helpers during initialization. `APP/main.c` owns startup output and
the echo test. Frame parsing, command IDs, and FPGA control remain future APP
work; this PC bring-up does not establish the final inter-board protocol.

The files follow the earlier robot project's `BSP_Module_Action` naming,
four-space indentation, separate-line braces, and function documentation style.
The author requested Chinese explanatory comments in these five source files.
Identifiers, startup text, and documentation remain in English. No HAL / LL
driver or earlier robot application has been imported.

### API behavior

- Initialization returns `1` only after HSI16 and both TX / RX ready flags are
  observed. It resets USART2 and discards previous pending data. Invalid baud
  divisors, divider rounding error above 2%, or readiness timeout return `0`;
  the driver then rejects send / receive calls until a successful initialization.
- `BSP_UART_Send_Byte()` waits for a writable TDR and returns `1` when the byte
  is accepted. This does not guarantee that the last stop bit has left the pin.
- `BSP_UART_Send_String()` sends a null-terminated string without its terminator.
  Failure can occur after a partial transmission.
- `BSP_UART_Try_Read_Byte()` never waits. It returns `1` and updates the output
  only for a valid byte, including `0x00`. No data, null pointers, initialization
  failure, or receive errors return `0` without changing the output.
- ORE / FE / NE / PE errors are cleared through ICR and pending receive data is
  flushed through RQR. This simple polling driver has no receive queue or
  lossless continuous-stream guarantee.
- Hardware waits are bounded by 1,000,000 polling iterations. This is an
  iteration limit, not a calibrated timeout in milliseconds. The 2% divisor
  check excludes HSI16 oscillator error and the peer's clock error.

## Wiring and first test

Check the actual development board exposes PA2 / PA3 and that these pins are
available. Use a bridge with 3.3 V UART logic and power the board through its
normal input, with a shared ground:

| USB serial bridge | STM32 |
|---|---|
| TX | PA3 (USART2_RX) |
| RX | PA2 (USART2_TX) |
| GND | GND |

DAPLink TX / RX pins can provide this bridge only if its firmware exposes a USB
serial COM port on the computer. SWD programming / debugging and UART signal
wiring are separate. A CAN adapter is not a replacement for this UART bridge.

1. Download the firmware using the actual configured probe after verifying
   board identity and wiring. Probe configuration and download are not yet tested.
2. Open the bridge's COM port at **115200, 8N1, no flow control**, with local
   echo disabled. Reset the board after opening the port: the startup line is
   sent only once and is not replayed when the terminal connects later.
3. Expected startup line: `EFES UART ready: USART2 PA2/PA3 115200 8N1`.
4. Send `Hello`; expect the same bytes back. A binary-mode check can send
   `55 AA 00 FF` and compare the returned four bytes exactly.
5. In Keil Watch, inspect `g_uart_init_ok`, `g_uart_startup_ok`,
   `g_uart_last_rx`, `g_uart_rx_count`, `g_uart_echo_count`, and
   `g_uart_tx_fail_count`. The echo counter excludes the startup message.

## Where to look up each setting

- [STM32G431 datasheet DS12589](https://www.st.com/resource/en/datasheet/stm32g431c8.pdf):
  find **Table 13, Alternate function mapping**, PA2 / PA3, AF7, USART2_TX / RX.
  The document covers STM32G431Rx devices as well as the other listed packages.
- [STM32G4 reference manual RM0440](https://www.st.com/resource/en/reference_manual/dm00355726.pdf):
  search `RCC_AHB2ENR`, `RCC_APB1ENR1`, `RCC_CCIPR`, `GPIOx_MODER`,
  `GPIOx_AFRL`, `GPIOx_AFRH`, `USART initialization`, `USART_CR1`,
  `USART_CR2`, `USART_CR3`, `USART_PRESC`, `USART_BRR`, `USART_ISR`,
  `USART_ICR`, `USART_RQR`, `USART_RDR`, and `USART_TDR`.
- [Local device header](Control16-10-2026/CMSIS/Core/Include/stm32g431xx.h):
  use VS Code **F12 / Go to Definition** on register-bit macros, for example
  `RCC_AHB2ENR_GPIOAEN`, `RCC_CCIPR_USART2SEL_1`, or `USART_ISR_TXE_TXFNF`.
  The header supplies names and masks; use the manual for behavior and write rules.

## Build

From the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\stm32\build.ps1 -Rebuild
```

For an incremental build, omit `-Rebuild`. The default Keil install directory is
`D:\Keil_v5`; set `KEIL_ROOT` or pass `-KeilRoot` to use another installation.
An appropriate Arm license is required; this machine uses MDK Community for
non-commercial development.

In VS Code, save source changes, press **Ctrl+Shift+B**, and select
**EFES: Build STM32**. This task invokes the same Keil project. IntelliSense paths and the device definition are
configured in `.vscode/c_cpp_properties.json`. New C or assembly files must also
be added to the Keil project before they participate in its build.

In Keil, select **Project > Rebuild all target files**. The official Arm-syntax
startup file may produce assembler deprecation warning `A1950W`; a warnings-only
build is accepted by the build wrapper. Errors are propagated to VS Code.

## Verification boundary

On 2026-10-29, the implemented UART firmware passed a full Keil rebuild with
zero errors / warnings and fresh AXF / HEX generation. Local host register-mock
checks, using the official device structures and bit masks, passed GPIO field
preservation, invalid inputs, baud calculation, readiness and transmit timeouts,
all 256 byte values, string handling, and receive-error discard commands.
These checks do not emulate oscillator startup, UART timing, W1C side effects,
or electrical hardware.

On-target download, banner output, echo behavior, DAPLink COM availability, and
inter-board communication have not been verified. Back up existing board
firmware as needed and confirm the actual probe / wiring before downloading.
