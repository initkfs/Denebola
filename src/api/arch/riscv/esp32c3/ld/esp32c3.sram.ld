ENTRY(_start)

MEMORY
{
   iram (rwx) : org = 0x40380000, len = 320K
   dram (rw)  : org = 0x3FC80000, len = 320K
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
    . = ALIGN(16);
    _iram_end = .;
  } > iram

  _iram_size = _iram_end - 0x40380000;
  
  _dram_start = ORIGIN(dram) + _iram_size;

  .rodata _dram_start : AT(_iram_size)
  {
    _dram_start_data = .;
    *(.rodata .rodata.* .srodata .srodata.*)
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


PROVIDE( esp_rom_spiflash_read = 0x40000130 );
PROVIDE( esp_rom_spiflash_attach = 0x40000164 );
PROVIDE( spi_flash_get_chip_size = 0x40000168 );
PROVIDE( esp_rom_spiflash_config_param = 0x40000134 );