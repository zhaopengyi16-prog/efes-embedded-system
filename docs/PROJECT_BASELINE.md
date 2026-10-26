# 项目基线

核对日期：2026-10-27。模式：已有多学科材料的项目初始化。基线状态：**Provisional（暂定）**。

## 项目标识与范围

- 名称：EFES 单通道信号采集与回放系统。
- 领域：Electronics for Embedded Systems 个人项目，涵盖 STM32、FPGA、模拟电路及电源验证。
- 初始边界：一路模拟输入和输出，分阶段录制、内部 RAM 存储和 DAC 回放；STM32 提供配置控制。
- 版本参考：提供的启动包 `manifest.json` 标为 v0.4；硬件更新日期为 2026-10-26。日期较新不代表课程审批通过。
- GitHub：`https://github.com/zhaopengyi16-prog/efes-embedded-system`；用户已明确选择公开仓库。创建与远程同步结果以实际 Git 检查为准。

## 三项输入基线

| 输入 | 来源 | 版本与适用范围 | 权威性及批准状态 | 证据状态 |
|---|---|---|---|---|
| 软件工程 | 本地 `EFES_Local_First_Setup.zip` 内 `EFES_Project_Starter/project/`；工作树 `stm32/`、`fpga/` | 启动包 v0.4；无 `.ioc`、`.qpf`、构建入口、固件或 HDL | 作为用户指定目录中的初始化材料；尚非已配置软件工程 | Found—authority unknown；软件工程 Missing |
| 硬件与接口 | `docs/hardware-update.md`、`docs/EFES_Hardware_Update_v0.4.docx`、`docs/EFES_Hardware_Update_v0.4.pdf` | 2026-10-26；STM32G431、DE1-SoC / LTC2308、候选 DAC 与模拟电路 | 暂定方案；借用、引脚、电平、原理图和电源复用未批准或未验证 | Found—authority unknown；最终接口定义 Missing |
| 功能需求 | 根目录原始提案 DOCX / PDF（仅本地），结合公开的 v0.4 硬件更新 | 单通道录制回放；原提案未见明确版本；转换位数和控制链路存在差异 | 尚无课程确认或完整需求基线 | Found—authority unknown；优先级 Needs confirmation |

状态说明：`Provided`、`Found—authority unknown`、`Missing`、`Not applicable`、`Needs confirmation` 用于区分资料是否存在、是否有权威性以及是否可直接实施。

## 来源关系与未决差异

| 主题 | 原提案 / 旧框图 | v0.4 启动材料 | 当前处理 |
|---|---|---|---|
| STM32 控制链路 | 原提案采用 SPI；框图仍列 SPI / UART / CAN 选项 | 硬件 UART；CMSIS 寄存器实现，不使用现成 HAL/LL USART 驱动 | 记录为暂定更新，需确认替代是否接受 |
| 电源 | 拟新设计低压 DC-DC，参数未定 | 提议复用既有自设计 12 V 输入电源部分 | 复用范围、课程接受程度和测量待确认 |
| 转换位数 | PDF 写标称 12/16 位，参数 DOCX 写初始 12 位 | 目标标称 12 位 | 暂按 v0.4 记录，不视为测量结论 |
| 硬件与存储 | 板卡、器件、内部 / 外部存储尚待选择 | 借用 DE1-SoC、板载 LTC2308、内部 RAM；候选 DAC | 借用、资源配置及内部 RAM 是否满足课程要求待确认 |

合理推断：v0.4 是对早期提案的后续工作草案。该推断依据更新时间和内容关系，不能代替用户或课程负责人的批准。遇到实际实施冲突时，先确认相关方案，再更新本文件；不自动把任一来源提升为已批准需求。

外部权威系统或课程批准记录：未提供。共享架构框架：未指定，兼容性 `Not assessed`。

## 配置与初始化边界

- 计划工具来自启动材料：Quartus Prime（优先课程 18.1 环境）、Verilog、现有 G431 IDE 或 STM32CubeIDE、C/CMSIS、LTspice。
- 本机安装情况、具体版本、目标器件、时钟、引脚、构建配置和测试命令：TODO。
- Git 目标：`main` 分支，初始化提交，连接上述公开仓库；提交身份使用账号关联的 noreply 邮箱。
- 原始五个输入文件保留原位置；不重排、不改写。它们不属于公开仓库内容。
- 归档中的 12 个项目文件均已按内置清单核对 SHA-256；初始化时调整根说明及忽略规则，新增协作文档，其余启动文件按原字节保留。
- 构建、仿真、上板测试和模拟 / 电源测量：未运行。

## 待确认

1. 由项目作者确认课程认可的功能来源及 SPI → UART、电源复用、内部 RAM 的适用性。
2. 确认 FPGA / DAC 借用、实验室条件、实际板卡版本与仪器。
3. 确认电压范围、输出负载、供电边界、参考电压、时序和 UART 命令格式。
4. 创建真实工程后记录构建目标、工具版本和可复现命令，再整理完整需求。

## 更新触发

功能来源或批准状态、硬件版本、接口、器件、工具配置、目标变体或发布基线变化时同步此文件。具体系统边界见 [系统架构](ARCHITECTURE.md)，软件细节见 [软件架构](SOFTWARE_ARCHITECTURE.md)。
