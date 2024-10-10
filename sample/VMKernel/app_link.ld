ENTRY (IMAGE_START)

SECTIONS{
    . = 0x00000000;

    .text  ALIGN (0x100) :{
        IMAGE_START = .;

        *(.text)
    }

    .rodata ALIGN (0x100) : {
        *(.rodata)
        _CTORS = .;
        *(.ctors)
        _CTORS_END = .;       
    }

    .data ALIGN (0x100) : {
        *(.data)
    }

    .bss ALIGN (0x100) : {
        SBSS = .;
        *(COMMON)
        *(.bss)
        EBSS = .;
		IMAGE_END = .;
    }
}
