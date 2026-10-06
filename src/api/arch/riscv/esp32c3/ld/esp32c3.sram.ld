ENTRY(_start)

MEMORY
{
    iram (rx) : org = 0x40380000, len = 0x40000 
    dram (rw) : org = 0x3FC90000, len = 0x40000 
    rtc_ram (rx): org = 0x50000000, len = 0x2000
}

SECTIONS
{
  .text.init ORIGIN(iram) :
  {
    _iram_start = .;
    KEEP(*(.text.init))
  } > iram

  .text :
  {
    *(.text .stub .text.* .gnu.linkonce.t.*)
    *(.rela.text .rela.text.* .rela.gnu.linkonce.t.*)
    *(.gnu.warning)
    . = ALIGN(4);
    _iram_end = .;
  } > iram

  .rodata ORIGIN(dram) :
  {
    _dram_start = .;
    *(.rodata .rodata.* .srodata .srodata.* .sdata2 .sdata2.* .gnu.linkonce.r.*)
    *(.rela.data .rela.data.* .rela.gnu.linkonce.r.*)
    . = ALIGN(4);
  } > dram

  .data :
  {
    _data_start = .;
    __DATA_BEGIN__ = .;
    *(.data .data.* .gnu.linkonce.d.*)
    *(.data.rel.ro.local* .gnu.linkonce.d.rel.ro.local.*) 
    *(.data.rel.ro .data.rel.ro.* .gnu.linkonce.d.rel.ro.*)
    *(.data1)
    __SDATA_BEGIN__ = .;
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    . = ALIGN(4);
    _edata = .; 
    PROVIDE (edata = .);
  } > dram

  .tls_template : ALIGN(4) 
  {
    _tls_start = .;
    _tdata_start = .;
    *(.tdata .tdata.* .gnu.linkonce.td.*)
    _tdata_end = .;
    
    _tbss_start = .;
    *(.tbss .tbss.* .gnu.linkonce.tb.*)
    *(.tcommon)
    _tbss_end = .;
    . = ALIGN(4);
    _tls_end = .;
  } > dram

  _bss_start = .;
  .sbss :
  {
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  } > dram

  .bss :
  {
   *(.dynbss)
   *(.bss .bss.* .gnu.linkonce.b.*)
   *(COMMON)
  } > dram
  
  . = ALIGN(4);
  _bss_end = .;
  
  __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
                          MAX(__DATA_BEGIN__ + 0x800, _bss_end - 0x800));
  _end = .; 
  PROVIDE (end = .);

  .kstack (NOLOAD) : 
  {
    . = ALIGN(16);
    _stack_end = .;
    . += 2048;
    _stack_start = .;
  } > dram

  _heap_start = _stack_start; 
  _heap_end = ORIGIN(dram) + LENGTH(dram);
}

rom_gpio_matrix_in = 0x400005a0;
rom_gpio_matrix_out = 0x400005a4;

PROVIDE ( esp_rom_gpio_connect_in_signal  = rom_gpio_matrix_in );
PROVIDE ( esp_rom_gpio_connect_out_signal = rom_gpio_matrix_out );