#include "stm32g4xx.h"
#include "uart.h"

/* 在 Keil Watch 中观察这些变量，可区分初始化失败、收到数据及发送失败。 */
volatile uint32_t g_core_clock_hz = 0U;
volatile uint32_t g_counter = 0U;
volatile uint8_t g_uart_init_ok = 0U;
volatile uint8_t g_uart_startup_ok = 0U;
volatile uint8_t g_uart_last_rx = 0U;
volatile uint32_t g_uart_rx_count = 0U;
volatile uint32_t g_uart_echo_count = 0U;
volatile uint32_t g_uart_tx_fail_count = 0U;

int main(void)
{
    uint8_t Data = 0U;

    /* 更新 CPU 时钟的软件记录；此函数不会配置或切换系统时钟。 */
    SystemCoreClockUpdate();
    g_core_clock_hz = SystemCoreClock;

    /* BSP 内部完成 GPIO 和 USART2 配置，APP 无需重复初始化引脚。 */
    g_uart_init_ok = BSP_UART_Init(BSP_UART_DEFAULT_BAUDRATE);
    if (g_uart_init_ok != 0U)
    {
        /* 电脑串口参数也设为 115200 / 8N1；启动信息只发送一次。 */
        g_uart_startup_ok = BSP_UART_Send_String(
            "EFES UART ready: USART2 PA2/PA3 115200 8N1\r\n");
    }

    while (1)
    {
        g_counter++;

        /* 最小回显测试：收到一个有效字节，就原样发回，包括二进制 0x00。
         * 当前没有命令解析；串口验证后再在 APP 层增加协议和 FPGA 控制。
         */
        if ((g_uart_init_ok != 0U) && (BSP_UART_Try_Read_Byte(&Data) != 0U))
        {
            g_uart_last_rx = Data;
            g_uart_rx_count++;

            if (BSP_UART_Send_Byte(Data) != 0U)
            {
                g_uart_echo_count++;
            }
            else
            {
                g_uart_tx_fail_count++;
            }
        }

        __NOP();
    }
}
    
