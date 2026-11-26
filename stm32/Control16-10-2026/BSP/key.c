/**
  ******************************************************************************
  * @file           : key.c
  * @brief          : 按键引脚配置与读取。消抖和长按判断在 APP 层完成。
  ******************************************************************************
  */

#include "stm32g4xx.h"
#include "key.h"
#include "gpio.h"

/* 驱动板原理图：J5（原标注 IICA）2 号脚 = PA15，1 号脚 = PB9，
 * 两根线各有 2.2 kΩ 上拉到 3.3 V（R4、R2）。 */
#define KEY1_PORT   GPIOA
#define KEY1_PIN    15U
#define KEY2_PORT   GPIOB
#define KEY2_PIN    9U

uint8_t BSP_Key_Init(void)
{
    if ((BSP_GPIO_Clock_Enable(KEY1_PORT) == 0U) ||
        (BSP_GPIO_Clock_Enable(KEY2_PORT) == 0U) ||
        (BSP_GPIO_Input_Init(KEY1_PORT, KEY1_PIN) == 0U) ||
        (BSP_GPIO_Input_Init(KEY2_PORT, KEY2_PIN) == 0U))
    {
        return 0U;
    }
    return 1U;
}

uint8_t BSP_Key_Is_Down(uint8_t Key)
{
    /* IDR 是输入数据寄存器，每位对应一个引脚的电平；按下时为 0。 */
    if (Key == BSP_KEY_1)
    {
        return ((KEY1_PORT->IDR & (1UL << KEY1_PIN)) == 0U) ? 1U : 0U;
    }
    if (Key == BSP_KEY_2)
    {
        return ((KEY2_PORT->IDR & (1UL << KEY2_PIN)) == 0U) ? 1U : 0U;
    }
    return 0U;
}
