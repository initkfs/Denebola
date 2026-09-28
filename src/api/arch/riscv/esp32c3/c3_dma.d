module api.arch.riscv.esp32c3.c3_dma;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rbase.rb_volatile;

/**
 * Authors: initkfs
 */
enum DMA = 0x6003_F000;

size_t* calcGDMA_IN_PERI_SEL_CHn_REG(ubyte n) => cast(size_t*)(DMA + 0x00A0 + 192 * n); // (n: 0-2)
