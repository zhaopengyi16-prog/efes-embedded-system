/**
  ******************************************************************************
  * @file           : uart.c
  * @brief          : STM32G431 USART2 寄存器驱动，提供轮询收发。
  ******************************************************************************
  */

/* 头文件 --------------------------------------------------------------------*/
#include "uart.h"
#include "gpio.h"
#include <stddef.h>

/* 内部参数 ------------------------------------------------------------------*/
/* 查 DS12589 的 Alternate function mapping 表：PA2 / PA3 的 AF7 是 USART2。
 * 这是芯片支持的映射，接线前仍需确认开发板实际引出及占用情况。
 */
#define BSP_UART_INSTANCE             USART2
#define BSP_UART_TX_PORT              GPIOA
#define BSP_UART_TX_PIN               2U
#define BSP_UART_RX_PORT              GPIOA
#define BSP_UART_RX_PIN               3U
#define BSP_UART_GPIO_AF              7U

/* 下方初始化会显式选择 HSI16；UART 时钟不依赖 CPU 的 PLL 配置。 */
#define BSP_UART_KERNEL_CLOCK_HZ      16000000U
#define BSP_UART_WAIT_LIMIT           1000000U
#define BSP_UART_BRR_MIN              16U
#define BSP_UART_BRR_MAX              65535U
#define BSP_UART_MAX_BAUD_ERROR       2U

#define BSP_UART_RX_ERROR_FLAGS       (USART_ISR_ORE | USART_ISR_FE | \
                                      USART_ISR_NE | USART_ISR_PE)
#define BSP_UART_RX_ERROR_CLEAR       (USART_ICR_ORECF | USART_ICR_FECF | \
                                      USART_ICR_NECF | USART_ICR_PECF)

/* 内部状态 ------------------------------------------------------------------*/
static uint8_t s_uart_ready = 0U;

/* 内部函数 ------------------------------------------------------------------*/
/**
 * @brief 等待指定状态位全部置 1，防止硬件异常时程序无限等待。
 * @note WAIT_LIMIT 是轮询次数，不是毫秒；实际时间随 CPU 频率和优化变化。
 */
static uint8_t BSP_UART_Wait_Flag(volatile uint32_t *p_Register, uint32_t Flags)
{
    uint32_t Count;

    for (Count = BSP_UART_WAIT_LIMIT; Count > 0U; Count--)
    {
        if ((*p_Register & Flags) == Flags)
        {
            return 1U;
        }
    }

    return 0U;
}

/* 对外接口 ------------------------------------------------------------------*/
/**
 * @brief 配置 USART2 及 PA2 / PA3，使用 8N1、16 倍过采样、轮询收发。
 * @param BaudRate 波特率，首次测试使用 BSP_UART_DEFAULT_BAUDRATE。
 * @return 1：初始化成功；0：参数错误、GPIO 配置失败或硬件等待超时。
 * @note 查 RM0440：RCC 时钟选择及 USART 的初始化、BRR、CR1/2/3、ISR。
 */
uint8_t BSP_UART_Init(uint32_t BaudRate)
{
    uint32_t BaudDiv;
    uint32_t ActualBaudRate;
    uint32_t BaudError;
    uint32_t ReadBack;

    s_uart_ready = 0U;

    /* 先检查参数，防止除零；16 倍过采样要求分频值至少为 16。 */
    if ((BaudRate == 0U) || (BaudRate > (BSP_UART_KERNEL_CLOCK_HZ / 16U)))
    {
        return 0U;
    }

    /* PRESC 编码为 0（除以 1）、OVER8 = 0 时，BRR 约等于 UART 时钟 / 波特率。
     * 加上半个除数进行四舍五入：16 MHz / 115200 得到 BRR = 139。
     */
    BaudDiv = (BSP_UART_KERNEL_CLOCK_HZ + (BaudRate / 2U)) / BaudRate;
    if ((BaudDiv < BSP_UART_BRR_MIN) || (BaudDiv > BSP_UART_BRR_MAX))
    {
        return 0U;
    }

    ActualBaudRate = BSP_UART_KERNEL_CLOCK_HZ / BaudDiv;
    BaudError = (ActualBaudRate > BaudRate) ?
                (ActualBaudRate - BaudRate) : (BaudRate - ActualBaudRate);

    /* 限制分频舍入误差为 2%；此数值不包含 HSI16 自身的频率误差。 */
    if ((BaudError * 100U) > (BaudRate * BSP_UART_MAX_BAUD_ERROR))
    {
        return 0U;
    }

    /* 1. 开启 USART2 的 APB1 总线时钟，再读回确认访问顺序。 */
    RCC->APB1ENR1 |= RCC_APB1ENR1_USART2EN;
    ReadBack = RCC->APB1ENR1;
    (void)ReadBack;

    /* 2. 关闭串口后开启 HSI16，等待振荡器就绪。
     *    这里只选择 UART 的时钟，不修改系统时钟、PLL 或定时器。
     */
    BSP_UART_INSTANCE->CR1 &= ~USART_CR1_UE;
    RCC->CR |= RCC_CR_HSION;
    if (BSP_UART_Wait_Flag(&RCC->CR, RCC_CR_HSIRDY) == 0U)
    {
        return 0U;
    }

    /* 3. 只复位 USART2，清除旧模式；不影响其他外设。
     *    CCIPR.USART2SEL = 10，表示选择 HSI16。
     */
    RCC->APB1RSTR1 |= RCC_APB1RSTR1_USART2RST;
    RCC->APB1RSTR1 &= ~RCC_APB1RSTR1_USART2RST;
    RCC->CCIPR = (RCC->CCIPR & ~RCC_CCIPR_USART2SEL) |
                 RCC_CCIPR_USART2SEL_1;

    /* 4. GPIO 层负责端口开钟、模式、电气配置和 AF；UART 层选择引脚。 */
    if ((BSP_GPIO_Clock_Enable(BSP_UART_TX_PORT) == 0U) ||
        (BSP_GPIO_Clock_Enable(BSP_UART_RX_PORT) == 0U) ||
        (BSP_GPIO_AF_Init(BSP_UART_TX_PORT, BSP_UART_TX_PIN, BSP_UART_GPIO_AF) == 0U) ||
        (BSP_GPIO_AF_Init(BSP_UART_RX_PORT, BSP_UART_RX_PIN, BSP_UART_GPIO_AF) == 0U))
    {
        return 0U;
    }

    /* 5. USART2 已由本驱动复位并独占，因此可以写入完整的已知配置。
     *    CR1：M1/M0=00 为 8 位，PCE=0 无校验，OVER8=0 为 16 倍，FIFOEN=0。
     *    CR2：STOP=00 为 1 个停止位，CLKEN=0 为异步通信。
     *    CR3：关闭 RTS/CTS、半双工、DMA 和错误中断，采用轮询。
     */
    BSP_UART_INSTANCE->CR1 = 0U;
    BSP_UART_INSTANCE->CR2 = 0U;
    BSP_UART_INSTANCE->CR3 = 0U;

    /* PRESC 的编码 0 表示除以 1；这里应写 0，而不是写数字 1。 */
    BSP_UART_INSTANCE->PRESC = 0U;
    BSP_UART_INSTANCE->BRR = BaudDiv;

    /* RQR 是请求寄存器，ICR 是写 1 清标志寄存器，直接写入命令掩码。 */
    BSP_UART_INSTANCE->RQR = USART_RQR_RXFRQ;
    BSP_UART_INSTANCE->ICR = BSP_UART_RX_ERROR_CLEAR;

    /* 6. 使能发送、接收和串口，等待硬件确认已启用 TX / RX。 */
    BSP_UART_INSTANCE->CR1 = USART_CR1_TE | USART_CR1_RE | USART_CR1_UE;
    if (BSP_UART_Wait_Flag(&BSP_UART_INSTANCE->ISR,
                           USART_ISR_TEACK | USART_ISR_REACK) == 0U)
    {
        BSP_UART_INSTANCE->CR1 = 0U;
        return 0U;
    }

    s_uart_ready = 1U;
    return 1U;
}

/**
 * @brief 轮询发送一个字节，支持 0x00。
 * @param Data 待发送的数据。
 * @return 1：已写入 TDR；0：未初始化或等待超时。
 */
uint8_t BSP_UART_Send_Byte(uint8_t Data)
{
    if (s_uart_ready == 0U)
    {
        return 0U;
    }

    /* TXE_TXFNF=1 表示 TDR 可以接受新字节，不代表整个字节已发送完。 */
    if (BSP_UART_Wait_Flag(&BSP_UART_INSTANCE->ISR, USART_ISR_TXE_TXFNF) == 0U)
    {
        return 0U;
    }

    BSP_UART_INSTANCE->TDR = Data;
    return 1U;
}

/**
 * @brief 发送以零字符结尾的字符串，方便打印启动提示。
 * @param p_String 字符串指针。
 * @return 1：全部字节已交给串口；0：参数错误、未初始化或部分发送失败。
 */
uint8_t BSP_UART_Send_String(const char *p_String)
{
    if ((p_String == NULL) || (s_uart_ready == 0U))
    {
        return 0U;
    }

    while (*p_String != '\0')
    {
        if (BSP_UART_Send_Byte((uint8_t)*p_String) == 0U)
        {
            return 0U;
        }
        p_String++;
    }

    return 1U;
}

/**
 * @brief 非阻塞尝试接收一个字节；没有有效数据时立即返回。
 * @param p_Data 接收输出地址，仅返回 1 时才会修改其内容。
 * @return 1：收到有效字节；0：无数据、参数错误、接收错误或未初始化。
 */
uint8_t BSP_UART_Try_Read_Byte(uint8_t *p_Data)
{
    uint32_t Status;

    if ((p_Data == NULL) || (s_uart_ready == 0U))
    {
        return 0U;
    }

    Status = BSP_UART_INSTANCE->ISR;

    /* ORE：来不及取走上个字节；FE：帧错误；NE：噪声；PE：校验错误。
     * 这个入门版本清除错误并丢弃当前接收数据，避免回显错误字节。
     * ICR 写 1 清标志；RQR.RXFRQ 丢弃接收寄存器中的数据。
     */
    if ((Status & BSP_UART_RX_ERROR_FLAGS) != 0U)
    {
        BSP_UART_INSTANCE->ICR = BSP_UART_RX_ERROR_CLEAR;
        BSP_UART_INSTANCE->RQR = USART_RQR_RXFRQ;
        return 0U;
    }

    if ((Status & USART_ISR_RXNE_RXFNE) == 0U)
    {
        return 0U;
    }

    /* 读 RDR 会取走这个字节，硬件据此清 RXNE；只读取一次。 */
    *p_Data = (uint8_t)BSP_UART_INSTANCE->RDR;
    return 1U;
}
