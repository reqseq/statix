# Physical Memory Layout

This document summarizes the physical memory layout relevant to early x86 boot
and the addresses used by Statix during startup.

## First Megabyte (Real Mode)

When an x86 machine starts in real mode, the first 1 MiB is shared with BIOS
data structures, video memory, and ROM mappings. Boot code must avoid
overwriting those regions.

| Start Address | End Address | Purpose / Description |
| :--- | :--- | :--- |
| `0x00000000` | `0x000003FF` | **Real-mode IVT (Interrupt Vector Table)**: Used by BIOS interrupt calls. |
| `0x00000400` | `0x000004FF` | **BIOS Data Area (BDA)**: Stores variables and states used by the BIOS. |
| `0x00000500` | `0x00007BFF` | **Conventional Memory**: Usually available for early boot code and data. |
| `0x00007C00` | `0x00007DFF` | **Boot Sector**: The BIOS loads the first sector (512 bytes) of the bootable media here. This is where `arch/x86/boot/boot.S` executes. |
| `0x00007E00` | `0x0007FFFF` | **Conventional Memory**: Usually available for loader and kernel data. |
| `0x00080000` | `0x0009FFFF` | **EBDA (Extended BIOS Data Area)**: Often used for ACPI/SMM; do not overwrite. |
| `0x000A0000` | `0x000BFFFF` | **Video Memory (VRAM)**: Memory-mapped I/O for video displays (e.g., VGA Text Mode is at `0xB8000`). |
| `0x000C0000` | `0x000FFFFF` | **BIOS ROM Space**: Contains video BIOS, option ROMs, and main system BIOS. |

## Statix Memory Layout

Statix currently uses the following layout:

| Start Address | End Address | Component | Details |
| :--- | :--- | :--- | :--- |
| `0x00001000` | *(size-dependent)* | **Kernel Image** | Loaded here by the boot sector (`KERNEL_OFFSET`). |
| `0x00009000` | `0x00009FFF` | **Bootloader Stack** | Real-mode stack growing downward from `0x9000`. |
| `0x000B8000` | `0x000B8FA0` | **VGA Text Buffer** | 80x25 character grid (2 bytes per cell: ASCII + attribute). |

The current loader does not probe the full memory map. A more complete kernel
would typically query firmware memory ranges with BIOS `INT 0x15, EAX=0xE820`
or the UEFI memory map on newer systems.

## References

- [OSDev Wiki: Memory Map (x86)](https://wiki.osdev.org/Memory_Map_(x86))
- [Ralf Brown's Interrupt List](http://www.ctyme.com/intr/int.htm)
