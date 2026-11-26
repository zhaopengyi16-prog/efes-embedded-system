/**
  ******************************************************************************
  * @file           : systick.c
  * @brief          : SysTick 寄存器配置，1 ms 中断一次，不依赖 HAL。
  ******************************************************************************
  */

#include "stm32g4xx.h"
#include "systick.h"

/* 毫秒计数，在中断里加 1，主循环里读。volatile 防止编译器把读取优化掉。 */
static volatile uint32_t s_tick_ms = 0U;

/**
 * @brief 配置 SysTick：时钟源为 CPU 时钟，重装值 = SystemCoreClock / 1000 - 1。
 * @return 1：成功；0：重装值超出 24 位范围。
 * @note 没有配置 PLL 时，复位后 CPU 用 HSI16，SystemCoreClock = 16 MHz，
 *       重装值为 15999。查 PM0214：SysTick 的 LOAD / VAL / CTRL。
 */
uint8_t BSP_SysTick_Init(void)
{
    uint32_t Reload;

    SystemCoreClockUpdate();
    Reload = (SystemCoreClock / 1000U) - 1U;
    if (Reload > 0x00FFFFFFU)
    {
        return 0U;
    }

    SysTick->CTRL = 0U;                 /* 先关闭 */
    SysTick->LOAD = Reload;
    SysTick->VAL  = 0U;                 /* 写任意值清零当前计数 */
    SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk |   /* 时钟源：CPU 时钟 */
                    SysTick_CTRL_TICKINT_Msk   |   /* 计到 0 时产生中断 */
                    SysTick_CTRL_ENABLE_Msk;       /* 启动 */
    return 1U;
}

uint32_t BSP_Get_Tick(void)
{
    return s_tick_ms;
}

/* 覆盖启动文件中的弱定义（startup_stm32g431xx.s 里的 [WEAK] SysTick_Handler）。 */
void SysTick_Handler(void)
{
    s_tick_ms++;
}
