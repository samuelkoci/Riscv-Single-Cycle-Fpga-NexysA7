#include "coremark.h"
#include "core_portme.h"

// --- DEFINIME ---
#ifndef CPU_HZ
#define CPU_HZ 50000000UL // 50 MHz ora e FPGA
#endif

#define UART_DATA_ADDR   0x80000000
#define HW_TIMER_ADDR    0x80000004
#define UART_STATUS_ADDR 0x80000008 

// --- VARIABLAT E KERKUARA NGA COREMARK ---
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
volatile ee_s32 seed4_volatile = 0; // iterations=0 -> auto-kalibrim zyrtar CoreMark (~10-100s)
volatile ee_s32 seed5_volatile = 0x0;

// Zgjidhja per Errorin e Linker-it: "undefined reference to default_num_contexts"
ee_u32 default_num_contexts = 1;

/* =========================================================================
 * 1. UART DRIVERS
 * ======================================================================= */
void uart_putchar(char c) {
    volatile int *status_reg = (int *)UART_STATUS_ADDR;
    volatile int *data_reg   = (int *)UART_DATA_ADDR;
    
    // Prit derisa UART te jete gati
    while (*status_reg != 0); 
    
    // Dergo karakterin
    *data_reg = c;

    // Vonesa jetike per 9600 Baud
    int d = 50000;
    while(d != 0) {
        __asm__ volatile ("nop");
        d--;
    }
}

void uart_puts(const char *s) {
    while (*s != '\0') {
        uart_putchar(*s);
        s++;
    }
}

/* =========================================================================
 * 2. TIMER DRIVERS
 * ======================================================================= */
CORE_TICKS start_time_val, stop_time_val;

void start_time(void) {
    volatile unsigned int *hw_timer = (volatile unsigned int *)HW_TIMER_ADDR;
    start_time_val = *hw_timer;
}

void stop_time(void) {
    volatile unsigned int *hw_timer = (volatile unsigned int *)HW_TIMER_ADDR;
    stop_time_val = *hw_timer;
}

CORE_TICKS get_time(void) {
    return (stop_time_val - start_time_val);
}

secs_ret time_in_secs(CORE_TICKS ticks) {
    return (secs_ret)ticks / (secs_ret)CPU_HZ;
}

/* =========================================================================
 * 3. PORTABLE INIT / FINI & EXTRAS
 * ======================================================================= */
void portable_init(core_portable *p, int *argc, char *argv[]) {
    p->portable_id = 1;
}

void portable_fini(core_portable *p) {
    p->portable_id = 0;
    uart_puts("\r\n--- CoreMark Perfundoi! CPU e Ngrire. ---\r\n");
    while (1) {
        __asm__ volatile ("nop");
    }
}

// Zgjidhja per Errorin e Linker-it: "undefined reference to print_coremarks"
void print_coremarks(CORE_TICKS total_time) {
    // CoreMark printon rezultatin vete me ee_printf, s'kemi nevoje te bejme gje.
}