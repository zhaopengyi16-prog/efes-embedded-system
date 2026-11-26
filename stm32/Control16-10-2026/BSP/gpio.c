/**
  ******************************************************************************
  * @file           : gpio.c
  * @brief          : GPIOA / GPIOC 时钟及引脚复用配置，不依赖 HAL / LL 驱动。
  ******************************************************************************
  */

/* 头文件 --------------------------------------------------------------------*/
#include "gpio.h"

/* 对外接口 ------------------------------------------------------------------*/
/**
 * @brief 开启 GPIOA / GPIOB / GPIOC 的外设时钟。
 * @param p_Port 端口地址，当前接受 GPIOA / GPIOB / GPIOC。
 * @return 1：成功；0：不支持的端口。
 * @note 查 RM0440：RCC_AHB2ENR 中的 GPIOAEN / GPIOBEN / GPIOCEN 位。
 */
uint8_t BSP_GPIO_Clock_Enable(GPIO_TypeDef *p_Port)
{
    uint32_t ReadBack;

    if (p_Port == GPIOA)
    {
        RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;
    }
    else if (p_Port == GPIOB)
    {
        RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN;
    }
    else if (p_Port == GPIOC)
    {
        RCC->AHB2ENR |= RCC_AHB2ENR_GPIOCEN;
    }
    else
    {
        return 0U;
    }

    /* 开钟后读回一次，保证时钟已生效再访问 GPIO 寄存器。 */
    ReadBack = RCC->AHB2ENR;
    (void)ReadBack;

    return 1U;
}

/**
 * @brief 将一个引脚设为复用功能：推挽、中速、上拉。
 * @param p_Port 端口地址，对应端口时钟必须已开启。
 * @param Pin 引脚编号，例如 PC4 传 4，不要传 1 << 4。
 * @param Alternate 复用功能编号，例如 USART1 的 PC4 / PC5 传 7。
 * @return 1：成功；0：试图修改 SWD 调试引脚 PA13 / PA14。
 * @note 查 RM0440：GPIO 的 MODER / OTYPER / OSPEEDR / PUPDR / AFR。
 */
uint8_t BSP_GPIO_AF_Init(GPIO_TypeDef *p_Port, uint8_t Pin, uint8_t Alternate)
{
    uint32_t ModeShift = (uint32_t)Pin * 2U;
    uint32_t AFIndex   = (uint32_t)Pin / 8U;
    uint32_t AFShift   = ((uint32_t)Pin % 8U) * 4U;

    /* PA13 / PA14 是 SWD 下载口，改掉后调试器将无法连接。 */
    if ((p_Port == GPIOA) && ((Pin == 13U) || (Pin == 14U)))
    {
        return 0U;
    }

    /* OTYPER 每脚 1 位：0 为推挽。 */
    p_Port->OTYPER &= ~(1UL << Pin);

    /* OSPEEDR 每脚 2 位：01 为中速；这是边沿速度，不是波特率。 */
    p_Port->OSPEEDR = (p_Port->OSPEEDR & ~(3UL << ModeShift)) |
                     (1UL << ModeShift);

    /* PUPDR 每脚 2 位：01 为上拉，RX 悬空时保持空闲高电平。 */
    p_Port->PUPDR = (p_Port->PUPDR & ~(3UL << ModeShift)) |
                   (1UL << ModeShift);

    /* AFR[0] 管脚 0..7，AFR[1] 管脚 8..15，每脚 4 位。 */
    p_Port->AFR[AFIndex] = (p_Port->AFR[AFIndex] & ~(15UL << AFShift)) |
                          ((uint32_t)Alternate << AFShift);

    /* 最后切换模式：MODER 每脚 2 位，10 为复用功能。 */
    p_Port->MODER = (p_Port->MODER & ~(3UL << ModeShift)) |
                   (2UL << ModeShift);

    return 1U;
}

/**
 * @brief 将一个引脚设为普通输入，并打开内部上拉。
 * @param p_Port 端口地址，对应端口时钟必须已开启。
 * @param Pin 引脚编号，例如 PB9 传 9。
 * @return 1：成功；0：试图修改 SWD 调试引脚 PA13 / PA14。
 * @note PA15 复位后默认是 JTDI（复用功能），这里把 MODER 改成 00 即变为普通输入；
 *       SWD 只用 PA13 / PA14，所以不影响下载和调试。
 */
uint8_t BSP_GPIO_Input_Init(GPIO_TypeDef *p_Port, uint8_t Pin)
{
    uint32_t ModeShift = (uint32_t)Pin * 2U;

    if ((p_Port == GPIOA) && ((Pin == 13U) || (Pin == 14U)))
    {
        return 0U;
    }

    /* PUPDR 每脚 2 位：01 为上拉。板上 J5 两根线另有 2.2 kΩ 外部上拉。 */
    p_Port->PUPDR = (p_Port->PUPDR & ~(3UL << ModeShift)) |
                   (1UL << ModeShift);

    /* MODER 每脚 2 位：00 为输入。 */
    p_Port->MODER &= ~(3UL << ModeShift);

    return 1U;
}
