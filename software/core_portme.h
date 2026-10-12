/*
 * core_portme.h — Bare-metal RV32I port for CoreMark
 */

 #ifndef CORE_PORTME_H
 #define CORE_PORTME_H
 
 #include <stdint.h>
 #include <stddef.h>
 
 /* =========================================================================
  * Konfigurimet e Kompilatorit dhe Raportit
  * ======================================================================= */
 #ifndef ITERATIONS
 #  define ITERATIONS   1  // Fillon me 1, CoreMark e kalibron vete shpejtesine
 #endif
 #define BUILD          "bare-metal"
 #define ARCH           "rv32i"
 #define COMPILER_FLAGS "-O2 -march=rv32im -mabi=ilp32 -ffreestanding"
 #define COMPILER_VERSION "GCC 15.2.0"
 #define MEM_LOCATION   "RAM"
 
 /* =========================================================================
  * Fikim Librarite Standarde (Jemi Bare-Metal)
  * ======================================================================= */
 #define HAS_FLOAT 0
 #define HAS_TIME_H 0
 #define USE_CLOCK 0
 #define HAS_STDIO 0
 #define HAS_PRINTF 0 // Detiron CoreMark te perdore ee_printf.c e vet
 
 /* =========================================================================
  * Tipet e te Dhenave (32-bit RISC-V)
  * ======================================================================= */
 typedef signed   short   ee_s16;
 typedef unsigned short   ee_u16;
 typedef signed   int     ee_s32;
 typedef double           ee_f32;
 typedef unsigned char    ee_u8;
 typedef unsigned int     ee_u32;
 typedef ee_u32           ee_ptr_int;
 typedef size_t           ee_size_t;
 
 #undef  NULL
 #define NULL ((void *)0)
 
 #define align_mem(x) (void *)(4 + (((ee_ptr_int)(x) - 1) & ~(ee_ptr_int)3))
 
 /* =========================================================================
  * Timer-i Harduerik (32-bit)
  * ======================================================================= */
 #define CORETIMETYPE uint32_t
 typedef uint32_t CORE_TICKS;
 typedef ee_u32   secs_ret;
 
 /* =========================================================================
  * Konfigurimet e Memories
  * ======================================================================= */
 #define SEED_METHOD 2
 #define MEM_METHOD 2        // 2 = MEM_STACK (Nuk kemi malloc)
 #define MULTITHREAD 1
 #define MAIN_HAS_NOARGC 1
 
 #ifndef TOTAL_DATA_SIZE
 #define TOTAL_DATA_SIZE 2000
 #endif
 
 /* =========================================================================
  * Deklarimi i Variablave Globale te CoreMark
  * ======================================================================= */
 extern volatile ee_s32 seed1_volatile;
 extern volatile ee_s32 seed2_volatile;
 extern volatile ee_s32 seed3_volatile;
 extern volatile ee_s32 seed4_volatile;
 extern volatile ee_s32 seed5_volatile;
 extern ee_u32          default_num_contexts;
 
 typedef struct CORE_PORTABLE_S {
     ee_u8 portable_id;
 } core_portable;
 
 /* =========================================================================
  * Funksionet e Kerkuara
  * ======================================================================= */
 void portable_init(core_portable *p, int *argc, char *argv[]);
 void portable_fini(core_portable *p);
 void       start_time(void);
 void       stop_time(void);
 CORE_TICKS get_time(void);
 secs_ret   time_in_secs(CORE_TICKS ticks);
 
 /* --- LIDHJA ME UART --- */
 void uart_putchar(char c);
 void uart_puts(const char *s);
 
 // KJO ESHTE THELBESORE: ee_printf i dergon germat ketu!
 #define ee_putchar(c) uart_putchar(c)
 int ee_printf(const char *fmt, ...);
 
 void print_coremarks(CORE_TICKS total_time);
 
 #endif /* CORE_PORTME_H */