/**
  ******************************************************************************
  * @file           : systick.h
  * @brief          : SysTick 1 ms 时基，提供毫秒计数，用于按键消抖和长按判断。
  ******************************************************************************
  */
#ifndef EFES_BSP_SYSTICK_H
#define EFES_BSP_SYSTICK_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* 根据 SystemCoreClock 配置 SysTick 每 1 ms 中断一次。成功返回 1。 */
uint8_t BSP_SysTick_Init(void);

/* 上电以来经过的毫秒数，约 49 天回绕一次；做差时用无符号减法即可。 */
uint32_t BSP_Get_Tick(void);

#ifdef __cplusplus
}
#endif

#endif /* EFES_BSP_SYSTICK_H */
