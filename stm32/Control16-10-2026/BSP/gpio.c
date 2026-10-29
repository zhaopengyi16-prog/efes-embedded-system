/**
  ******************************************************************************
  * @file           : gpio.c
  * @brief          : GPIOA 时钟及串口引脚复用配置，不依赖 HAL / LL 驱动。
  ******************************************************************************
  */

/* 头文件 --------------------------------------------------------------------*/
#include "gpio.h"

/* 对外接口 ------------------------------------------------------------------*/
/**
 * @brief 开启 GPIOA 的外设时钟。
 * @param p_Port 端口地址，当前只接受 GPIOA。
 * @return 1：成功；0：不支持的端口。
 * @note 查 RM0440：RCC_AHB2ENR 中的 GPIOAEN 位。
 */
uint8_t BSP_GPIO_Clock_Enable(GPIO_TypeDef *p_Port)
{
    uint32_t ReadBack;

    if (p_Port != GPIOA)
    {
        return 0U;
    }

    /* |= 只把 GPIOAEN 置 1，保留其他外设的时钟开关。 */
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;

    /* 开钟后读回寄存器，给总线时钟使能留出必要的生效时间。 */
    ReadBack = RCC->AHB2ENR;
    (void)ReadBack;

    return 1U;
}

/**
 * @brief 将 GPIOA 的一个引脚交给外设，使用串口所需的电气配置。
 * @param p_Port 当前只接受 GPIOA，且其时钟必须已开启。
 * @param Pin 引脚编号，例如 PA2 传 2，不要传 1 << 2。
 * @param Alternate 复用功能编号，例如 USART2 的 PA2 / PA3 传 7。
 * @return 1：成功；0：参数、时钟或调试引脚保护检查失败。
 * @note 查 RM0440：GPIO 的 MODER / OTYPER / OSPEEDR / PUPDR / AFR。
 */
uint8_t BSP_GPIO_AF_Init(GPIO_TypeDef *p_Port, uint8_t Pin, uint8_t Alternate)
{
    uint32_t ModeShift;
    uint32_t AFIndex;
    uint32_t AFShift;

    if ((p_Port != GPIOA) || (Pin > 15U) || (Alternate > 15U))
    {
        return 0U;
    }

    if (((RCC->AHB2ENR & RCC_AHB2ENR_GPIOAEN) == 0U) ||
        (Pin == 13U) || (Pin == 14U))
    {
        return 0U;
    }

    ModeShift = (uint32_t)Pin * 2U;
    AFIndex = (uint32_t)Pin / 8U;
    AFShift = ((uint32_t)Pin % 8U) * 4U;

    /* OTYPER 每脚 1 位：0 为推挽，TX 可以主动输出高、低电平。 */
    p_Port->OTYPER &= ~(1UL << Pin);

    /* OSPEEDR 每脚 2 位：01 为中速；这是边沿速度，不是波特率。 */
    p_Port->OSPEEDR = (p_Port->OSPEEDR & ~(3UL << ModeShift)) |
                     (1UL << ModeShift);

    /* PUPDR 每脚 2 位：01 为上拉，让未被外部驱动的 RX 保持空闲高电平。 */
    p_Port->PUPDR = (p_Port->PUPDR & ~(3UL << ModeShift)) |
                   (1UL << ModeShift);

    /* AFR[0] 管脚 0..7，AFR[1] 管脚 8..15，每脚占 4 位。 */
    p_Port->AFR[AFIndex] = (p_Port->AFR[AFIndex] & ~(15UL << AFShift)) |
                          ((uint32_t)Alternate << AFShift);

    /* 最后切换模式：MODER 每脚 2 位，10 表示复用功能。
     * 所有配置都只修改目标引脚，保留其他引脚及 SWD 的配置。
     */
    p_Port->MODER = (p_Port->MODER & ~(3UL << ModeShift)) |
                   (2UL << ModeShift);

    return 1U;
}
