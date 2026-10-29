# Third-party CMSIS files

Vendor files are retained without implementation changes.

| Files | Source | License record |
|---|---|---|
| Arm core headers, including architecture subdirectories | Installed `ARM.CMSIS.6.2.0`, `CMSIS/Core/Include` | `Core/LICENSE` |
| `Core/Include/stm32g4xx.h`, `stm32g431xx.h`, and `system_stm32g4xx.h` | Installed `Keil.STM32G4xx_DFP.1.6.0`, `Drivers/CMSIS/Device/ST/STM32G4xx/Include` | `Dvice/LICENSE` and `Dvice/Package_license.md` |
| `Dvice/Source/system_stm32g4xx.c` and `startup_stm32g431xx.s` | The same device pack, `Drivers/CMSIS/Device/ST/STM32G4xx/Source/Templates` and its `arm` subdirectory | `Dvice/LICENSE` and `Dvice/Package_license.md` |

The original copyright and license notices remain in each file. Device CMSIS
files are identified as Apache-2.0 in the ST package's license inventory.
The pack contains additional components, such as HAL/LL drivers, which have not
been added to this firmware. These third-party notices do not select a license
for project-authored EFES code.
