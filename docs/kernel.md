# Kernel

The Statix kernel runs in 32-bit protected mode after the bootloader completes
the BIOS-side setup.

## Entry Point

`arch/x86/kernel/entry.S` is linked first so it occupies the beginning of the
flat kernel image at `0x1000`. It calls `kernel_main()` and then halts in a
loop if control ever returns.

## Current Behavior

`kernel/main.c` reads the current VGA cursor position from the CRT controller
ports (`0x3D4` and `0x3D5`) and writes the character `X` to that screen cell.

## VGA Text Mode

The VGA text framebuffer is mapped at physical address `0xB8000`. Each
character cell is two bytes:

| Byte   | Contents                                     |
|--------|----------------------------------------------|
| Even   | ASCII character code                         |
| Odd    | Attribute (bits 7-4: background, 3-0: foreground) |

## Build Model

The kernel is built as 32-bit freestanding code (`-m32 -ffreestanding`). No C
runtime or standard library is linked in. Hardware access is performed through
port I/O helpers and direct memory-mapped writes.

## Source Files

| File | Description |
| :--- | :--- |
| `arch/x86/kernel/entry.S` | Assembly entry point that calls `kernel_main()` |
| `kernel/main.c` | Current kernel logic |
| `arch/x86/kernel/kernel.ld` | Linker script placing the kernel at `0x1000` |

## Future Development

Possible next steps:

- **VGA driver** — scrolling, cursor positioning, formatted output
- **Interrupt handling** — IDT setup, hardware IRQs, keyboard input
- **Memory management** — physical page allocator, paging
- **Serial console** — COM1 output for debugging
- **Shell** — minimal command-line interface

## References

- [Memory Map](memory_map.md)
- [Global Descriptor Table (GDT)](gdt.md)
