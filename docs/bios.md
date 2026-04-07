# BIOS Boot Services

The boot sector in `arch/x86/boot/boot.S` uses BIOS services only while the CPU
is still in 16-bit real mode. This document summarizes the BIOS interfaces and
fixed addresses used by the current loader.

## BIOS Interrupts

In real mode, Statix relies on BIOS firmware for screen output and disk reads.

### Teletype Output (`int 0x10`)

The `print`, `print_nl`, and `print_hex` routines use BIOS teletype output to
display boot messages.

| Register | Target Value | Description |
| :--- | :--- | :--- |
| `AH` | `0x0E` | Teletype output function |
| `AL` | `ASCII` | Character to print |
| `BH` | `0x00` | Display page |
| `BL` | `Color` | Foreground color in graphics modes |

### Disk Read (`int 0x13`)

The `disk_load` routine uses BIOS sector reads to load the kernel image from
the boot device into memory.

| Register | Target Value | Description |
| :--- | :--- | :--- |
| `AH` | `0x02` | Read sectors function |
| `AL` | `Count` | Number of sectors to read |
| `CH` | `0x00` | Cylinder |
| `CL` | `0x02` | Starting sector (`1` is the boot sector) |
| `DH` | `0x00` | Head |
| `DL` | `Drive Num` | Boot drive supplied by BIOS |
| `ES:BX` | `0x1000` | Destination buffer |

If the call fails, the carry flag is set and `AH` contains a BIOS status code.

## Boot Constants

These constants define the loader's current memory layout:

| Hexadecimal | Category | Execution Purpose |
| :--- | :--- | :--- |
| `0xAA55` | **Boot Signature** | Required word at offsets `510` and `511` of the boot sector |
| `0x7C00` | **Sector Origin** | Address where BIOS loads the boot sector |
| `0x9000` | **Stack Base** | Initial 16-bit stack top |
| `0x1000` | **Kernel Offset** | Address where the kernel image is loaded |

## Notes

- The loader currently reads two sectors starting at sector 2.
- After the kernel is in memory, the loader stops using BIOS services and
  switches to protected mode.

## References

- [OSDev Wiki: Boot Sequence](https://wiki.osdev.org/Boot_Sequence)
- [Ralf Brown's Interrupt List](http://www.ctyme.com/intr/int.htm)
