/**
  ******************************************************************************
  * @file           : key.h
  * @brief          : 两个按键（J5 接口）：KEY1 = PA15（J5-2），KEY2 = PB9（J5-1）。
  *                   按键一端接引脚，另一端接 GND（J5-4），按下读到 0。
  ******************************************************************************
  */
#ifndef EFES_BSP_KEY_H
#define EFES_BSP_KEY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#define BSP_KEY_1       0U      /* PA15，J5-2 */
#define BSP_KEY_2       1U      /* PB9， J5-1 */
#define BSP_KEY_COUNT   2U

/* 开启 GPIOA / GPIOB 时钟，把 PA15、PB9 配置为上拉输入。成功返回 1。 */
uint8_t BSP_Key_Init(void);

/* 读按键当前电平（未消抖）：按下返回 1，松开返回 0。 */
uint8_t BSP_Key_Is_Down(uint8_t Key);

#ifdef __cplusplus
}
#endif

#endif /* EFES_BSP_KEY_H */
