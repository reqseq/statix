# Protected Mode (32-bit Transition)

`switch_to_pm` in `arch/x86/boot/boot.S` performs the transition from 16-bit
real mode to 32-bit protected mode.

## Transition Sequence

After loading the kernel image, the bootloader performs these steps:

| Sequence | Focus | Instruction Code | Purpose |
| :--- | :--- | :--- | :--- |
| **1** | Disable Interrupts | `cli` | Prevents real-mode interrupt handlers from running during the transition |
| **2** | Load GDT | `lgdt` | Points GDTR at the protected-mode descriptor table |
| **3** | Enable Protection | `mov %cr0` / `or $0x1` | Sets the `PE` bit in `CR0` |
| **4** | Flush Pipeline | `ljmp` | Reloads `CS` with the protected-mode code selector |
| **5** | Initialize State | `mov %ds`, `mov %ss`, etc. | Loads the flat data selector into all data segment registers and sets a 32-bit stack |

## Post-Transition Environment

After step 5, execution continues in 32-bit protected mode with flat code and
data segments.

| Protected Target | Value | Effect |
| :--- | :--- | :--- |
| **VGA Text Buffer** | `0xB8000` | Memory-mapped text framebuffer |
| **Protected-mode stack top** | `0x90000` | Stack top loaded into `ESP` |

At this point BIOS services are no longer used by the running code.

## References

- [Intel 64 and IA-32 Architectures Software Developer's Manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [OSDev Wiki: Protected Mode](https://wiki.osdev.org/Protected_Mode)
