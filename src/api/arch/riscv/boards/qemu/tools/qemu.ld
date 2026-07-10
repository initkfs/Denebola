OUTPUT_ARCH("riscv")

ENTRY( _start )

MEMORY
{
    ram (wxa!ri) : ORIGIN = 0x80000000, LENGTH = 128M
}

PHDRS
{
    text PT_LOAD;
    rodata PT_LOAD;
    data PT_LOAD;
    bss PT_LOAD;
    kstack PT_LOAD;
}

SECTIONS
{
  .text : {
    _text_start = .;
    *(.text.init) *(.text .text.*)
    _text_end = .;
    } >ram AT>ram :text

  .rodata : {
    _rodata_start = .;
    *(.rodata .rodata.*)
    _rodata_end = .;
    } >ram AT>ram :rodata

  .data : {
    . = ALIGN(4096);
    _data_start = .;
    *(.sdata .sdata.*) *(.data .data.*)
    _data_end = .;
    } >ram AT>ram :data

  .bss : {
    _bss_start = .;
    *(.sbss .sbss.*) *(.bss .bss.*)
    _bss_end = .;
    } >ram AT>ram :bss

  .tdata : { *(.tdata .tdata.*) }
  .tbss  : { *(.tbss .tbss.*) }
  ASSERT(SIZEOF(.tdata) == 0, "Error: Thread-Local Storage (.tdata) variables are forbidden")
  ASSERT(SIZEOF(.tbss) == 0, "Error: Thread-Local Storage (.tbss) variables are forbidden")

  .kstack : {
    . = ALIGN(16);
    . += 4K;
    _stack_start = .;
    } >ram AT>ram :kstack
    
    _memory_start = ORIGIN(ram);
    _memory_end = ORIGIN(ram) + LENGTH(ram);

    _heap_start = _memory_start;
    _heap_end = _memory_end;
}