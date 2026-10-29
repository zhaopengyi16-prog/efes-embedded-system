/**
  ******************************************************************************
  * @file           : gpio.h
  * @brief          : 串口使用的 GPIO 寄存器接口。
  ******************************************************************************
  */
#ifndef EFES_BSP_GPIO_H
#define EFES_BSP_GPIO_H

#ifdef __cplusplus
extern "C" {
#endif

/* 头文件 --------------------------------------------------------------------*/
#include "stm32g4xx.h"

/* 对外接口 ------------------------------------------------------------------*/
/* 当前仅支持 GPIOA；成功返回 1，参数错误返回 0。 */
uint8_t BSP_GPIO_Clock_Enable(GPIO_TypeDef *p_Port);

/* Pin 为引脚编号 0..15，不是位掩码；Alternate 为 AF 编号 0..15。
 * 调用前先开启 GPIOA 时钟。配置为复用、推挽、中速、上拉。
 * PA13 / PA14 留给 SWD 调试，此接口拒绝修改这两个引脚。
 * 成功返回 1；参数错误、时钟未开启或引脚受保护时返回 0。
 */
uint8_t BSP_GPIO_AF_Init(GPIO_TypeDef *p_Port, uint8_t Pin, uint8_t Alternate);

#ifdef __cplusplus
}
#endif

#endif /* EFES_BSP_GPIO_H */
