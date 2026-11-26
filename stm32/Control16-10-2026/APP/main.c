#include "stm32g4xx.h"
#include "uart.h"
#include "systick.h"
#include "key.h"

/* EFES 控制器：两个按键通过 USART1（PC4 → FPGA D10）向 FPGA 发送单字节命令。
 *   短按 KEY1（PA15）  → 'r'  开始录音
 *   短按 KEY2（PB9）   → 'p'  开始放音
 *   长按任意键 ≥ 1 s   → 's'  停止
 * 注意：不要再向串口打印启动文字，FPGA 会把其中的字母 r / p / s 当成命令。
 */

#define KEY_SCAN_MS        10U     /* 每 10 ms 扫描一次按键 */
#define KEY_DEBOUNCE_MS    30U     /* 电平稳定 30 ms 才认为状态改变 */
#define KEY_LONG_MS        1000U   /* 按住超过 1 s 算长按 */

/* 在 Keil Watch 中观察：初始化结果、最近发送的命令、各命令发送次数。 */
volatile uint8_t  g_init_ok    = 0U;
volatile uint8_t  g_last_cmd   = 0U;
volatile uint32_t g_cmd_count  = 0U;

typedef struct
{
    uint8_t  Stable;        /* 消抖后的状态：1 按下，0 松开 */
    uint8_t  LongSent;      /* 这次按下是否已经发过长按命令 */
    uint32_t ChangeTime;    /* 原始电平最近一次变化的时刻 */
    uint8_t  Raw;           /* 上次读到的原始电平 */
    uint32_t PressTime;     /* 消抖后确认按下的时刻 */
} KeyState_t;

static KeyState_t s_key[BSP_KEY_COUNT];

static void Send_Command(uint8_t Cmd)
{
    if (BSP_UART_Send_Byte(Cmd) != 0U)
    {
        g_last_cmd = Cmd;
        g_cmd_count++;
    }
}

/* 处理一个按键：消抖；松开时若按下时间 < 1 s 则发短按命令；按满 1 s 立即发 's'。 */
static void Key_Process(uint8_t Key, uint8_t ShortCmd, uint32_t Now)
{
    KeyState_t *k = &s_key[Key];
    uint8_t Raw = BSP_Key_Is_Down(Key);

    if (Raw != k->Raw)                       /* 原始电平变了，重新计时 */
    {
        k->Raw = Raw;
        k->ChangeTime = Now;
    }

    if ((Raw != k->Stable) && ((Now - k->ChangeTime) >= KEY_DEBOUNCE_MS))
    {
        k->Stable = Raw;                     /* 电平稳定够久，确认状态改变 */
        if (Raw != 0U)
        {
            k->PressTime = Now;              /* 确认按下 */
            k->LongSent = 0U;
        }
        else if (k->LongSent == 0U)
        {
            Send_Command(ShortCmd);          /* 确认松开且不是长按：短按 */
        }
    }

    if ((k->Stable != 0U) && (k->LongSent == 0U) &&
        ((Now - k->PressTime) >= KEY_LONG_MS))
    {
        Send_Command('s');                   /* 按满 1 s：停止 */
        k->LongSent = 1U;
    }
}

int main(void)
{
    uint32_t LastScan = 0U;
    uint32_t Now;

    g_init_ok = (uint8_t)(BSP_SysTick_Init() &
                          BSP_UART_Init(BSP_UART_DEFAULT_BAUDRATE) &
                          BSP_Key_Init());

    while (1)
    {
        Now = BSP_Get_Tick();
        if ((g_init_ok != 0U) && ((Now - LastScan) >= KEY_SCAN_MS))
        {
            LastScan = Now;
            Key_Process(BSP_KEY_1, 'r', Now);
            Key_Process(BSP_KEY_2, 'p', Now);
        }
    }
}
