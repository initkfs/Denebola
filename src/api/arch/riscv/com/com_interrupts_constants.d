/**
 * Authors: initkfs
 */
module api.arch.riscv.com.com_interrupts_constants;

extern(C):

//MPP (Machine Previous Privilege)
enum MSTATUS_MPP_MASK = (3 << 11);
enum MSTATUS_MPP_M = (3 << 11); //Machine mode
enum MSTATUS_MPP_S = (1 << 11); //Supervisor mode.
enum MSTATUS_MPP_U = (0 << 11); //User mode

enum MSTATUS_MPRV  = (1 << 17);  // Modify Privilege
enum MSTATUS_TW    = (1 << 21);  // Trap WFI: ban WFI в S/U-mode
enum MSTATUS_TVM   = (1 << 20);  // Trap Virtual Memory

//FPU
enum MSTATUS_FS    = (3 << 13);  // Floating-Point Status (0=off, 1=initial, 2=clean, 3=dirty)
enum MSTATUS_XS    = (3 << 15);  // Extension Status (custom extensions)

//Machine Interrupt Enable
enum MSTATUS_MIE_BIT = 3;
enum MSTATUS_MIE = (1 << MSTATUS_MIE_BIT);

// External Interrupt
enum MIE_MEIE_BIT = 11;
enum MIE_MEIE = (1 << MIE_MEIE_BIT);

// Timer Interrupt
enum MIE_MTIE_BIT = 7;
enum MIE_MTIE = (1 << MIE_MTIE_BIT);

// Software Interrupt
enum MIE_MSIE_BIT = 3;
enum MIE_MSIE = (1 << MIE_MSIE_BIT);

enum MIE_SSIE = (1 << 1);  // Software Interrupt (local)
enum MIE_STIE = (1 << 5);  // Timer Interrupt (local)
//MIE_FastInt0 = (1 << 16);  //Fast interrupts in SiFive