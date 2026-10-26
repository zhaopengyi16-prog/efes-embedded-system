# 软件架构

## 范围与证据

软件 / HDL 位置为 `stm32/` 与 `fpga/`。初始化材料仅给出目录说明，尚无 STM32 工程、Quartus 工程、C、Verilog、仿真测试台或运行日志。系统上下文见 [系统架构](ARCHITECTURE.md)，来源权威性见 [项目基线](PROJECT_BASELINE.md)。

```text
stm32/README.md
fpga/rtl/.gitkeep
fpga/sim/.gitkeep
fpga/quartus/.gitkeep
```

## 职责规划与集成状态

| 部分 | 启动材料中的规划职责 | 源码存在 | 构建纳入 | 运行连接 |
|---|---|---|---|---|
| STM32 固件 | C/CMSIS 寄存器配置硬件 UART；发命令、收状态 | Not evidenced in inspected scope；只有 `stm32/README.md` | Not evidenced in inspected scope；无工程或目标 | Not evidenced in inspected scope；无入口、初始化与调用路径 |
| FPGA 逻辑 | Verilog 实现采集、存储控制与回放 | Not evidenced in inspected scope；`fpga/rtl/` 仅占位 | Not evidenced in inspected scope；无 `.qpf` / `.qsf` | Not evidenced in inspected scope；无顶层、时钟或状态机 |
| FPGA 仿真 | 验证存储和主要运行状态 | Not evidenced in inspected scope；`fpga/sim/` 仅占位 | Not evidenced in inspected scope；无仿真配置 | Not evidenced in inspected scope；无测试台或结果 |

目录和占位文件的存在为 `Confirmed`；这不能证明相应源码、构建集成、运行连接或上板成功。当前无生产源码、供应商源码或生成源码可分类。

## 计划接口与所有权

以下来自 v0.4 材料，属于暂定设计职责，尚无公共头文件、端口定义或实现。

| 边界 | 计划所有者与使用方 | 后续需要固定的内容 |
|---|---|---|
| STM32 ↔ FPGA 控制 | STM32 命令发送 / 状态接收；FPGA 命令处理 / 状态返回 | UART 引脚、电平、波特率、帧格式、命令、响应与错误行为 |
| ADC ↔ FPGA | FPGA 采样时序和转换器接口 | 器件配置、转换时序、数据编码与有效条件 |
| RAM | FPGA 自编地址、写入、读取与长度控制 | 容量、复位、有效样本数与录制 / 回放边界 |
| FPGA ↔ DAC | FPGA 回放调度与 DAC 数字接口 | 器件型号、时序、参考缩放、结束与停止行为 |

STM32 固件按启动说明独立建立，不复制完整旧机器人应用。HAL/LL USART 驱动不属于 v0.4 的拟定实现方法；是否采用该方案仍按项目基线确认。

## 入口、调度和数据流

- 实际 MCU 入口、时钟初始化、主循环 / 中断及调用顺序：TODO；无源码证据。
- 实际 FPGA 顶层、复位、时钟域、使能和状态迁移：TODO；无 HDL 或约束证据。
- 100 kS/s 是目标采样率，不是已配置的中断周期或已达成的时序结果。
- 规划的数据通路为 ADC → FPGA → RAM，以及 RAM → FPGA → DAC；录制、回放分阶段。当前没有运行连通性或硬件测量证据。

## 工程与代码维护

- 实际工具版本、构建目标、链接 / 引脚 / 时序配置及执行命令均待工程建立后记录。
- 当前不存在可采样的维护源码，不能确定命名、缩进、括号、类型或错误处理风格。未来修改先阅读就近维护文件并延续其风格，不进行全局重排。
- 后续保护供应商库、生成代码、IDE 缓存和构建输出；`.ioc`、启动文件、链接脚本、`.qpf`、`.qsf` 和 `.sdc` 等工程来源按实际需要版本控制。
- 无已指定共享架构框架；名称、版本、适用性和权威性均未绑定，结构兼容性 `Not assessed`。不引入汽车 ACM 等无关框架约束。
- 本次不创建层级 `AGENTS.md`：尚无实际模块或局部编码规范，根规则已覆盖当前范围。

## 后续变更导航

| 变更 | 从哪里开始 | 关联检查 |
|---|---|---|
| 固定 UART 与板卡配置 | `stm32/README.md`、`hardware/README.md` | 实际引脚、时钟、电平、课程范围；再确定收发验证方式 |
| FPGA 采集与存储 | `fpga/rtl/`、`fpga/sim/` | 确认顶层、器件与时钟；再提供对应仿真证据 |
| 工程配置 | `fpga/quartus/`、`stm32/` | 记录实际工具、构建命令、受控配置与生成目录 |
| 接口、供电或板卡变化 | `hardware/`、`docs/PROJECT_BASELINE.md` | 同步系统边界，重新核对受影响测试 |

当前仅完成仓库与文档初始化。构建、仿真、时序分析和硬件执行均未运行。下一阶段先确认来源和范围，再整理完整功能需求与可实施任务。
