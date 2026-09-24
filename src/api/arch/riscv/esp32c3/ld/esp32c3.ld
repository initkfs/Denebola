ENTRY(_start)

MEMORY
{
    irom (x): org = 0x42000000, len = 0x400000
    drom (r): org = 0x3C000000, len = 0x400000
    ram (rw): org = 0x3FC80000, len = 0x50000 /* 320K, 80K for BootROM*/
    rtc_ram (rx): org = 0x50000000, len = 0x2000
}

SECTIONS
{
  .header : AT(0)
  {
    _irom_start = .;
    LONG(0xaedb041d)
    LONG(0xaedb041d)
  } > irom

  .text.init ORIGIN(irom) + 8 :
  {
    KEEP(*(.text.init))
  } > irom

  .text :
  {
    *(.text .stub .text.* .gnu.linkonce.t.*)
    *(.rela.text .rela.text.* .rela.gnu.linkonce.t.*)
    *(.gnu.warning)
  }
  . = ALIGN(4);
  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);
  _irom_size = . - _irom_start;
  
  _drom_start = ORIGIN(drom) + _irom_size;
  .rodata  _drom_start : AT(_irom_size)
  {
    *(.rodata .rodata.* .srodata .srodata.* .sdata2 .sdata2.* .gnu.linkonce.r.*)
    *(.rela.data .rela.data.* .rela.gnu.linkonce.r.*)
  } > drom

  _drom_size = . - _drom_start;

  .data ORIGIN(ram) : AT(_irom_size + _drom_size) 
  {
    _data_start = .;
    __DATA_BEGIN__ = .;
    *(.data .data.* .gnu.linkonce.d.*)
    *(.data.rel.ro.local* .gnu.linkonce.d.rel.ro.local.*) *(.data.rel.ro .data.rel.ro.* .gnu.linkonce.d.rel.ro.*)
    *(.data1)
    __SDATA_BEGIN__ = .;
    *(.sdata .sdata.* .gnu.linkonce.s.*)

     . = ALIGN(4);
     _edata = .; PROVIDE (edata = .);
  } > ram

  _data_lma = ORIGIN(drom) + LOADADDR(.data);
  _data_size = _edata - _data_start;

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
  } > ram AT> ram

  _bss_start = .;
  .sbss           :
  {
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }
  .bss            :
  {
   *(.dynbss)
   *(.bss .bss.* .gnu.linkonce.b.*)
   *(COMMON)
  }
  . = ALIGN(4);
  _bss_end = .;
  __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
                          MAX(__DATA_BEGIN__ + 0x800, _bss_end - 0x800));
  _end = .; PROVIDE (end = .);

  .kstack (NOLOAD) : {
    . = ALIGN(16);
    _stack_end = .;
    . += 2048;
    _stack_start = .;
  } > ram

  _heap_start = _stack_start; 
  _heap_end = ORIGIN(ram) + LENGTH(ram);
  
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
   /* dwarf 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line .debug_line.* .debug_line_end) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
   /* dwarf 3 */
  .debug_pubtypes 0 : { *(.debug_pubtypes) }
  .debug_ranges   0 : { *(.debug_ranges) }
  .debug_macro    0 : { *(.debug_macro) }
  .debug_addr     0 : { *(.debug_addr) }
}