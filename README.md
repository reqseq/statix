# Statix

Statix is a small 32-bit x86 kernel and BIOS boot path built from scratch.
The current tree targets a simple freestanding environment: a 512-byte boot
sector loads a flat kernel image, switches to protected mode, and transfers
control to the kernel entry point.

## Project Structure

```
arch/x86/boot/     First-stage BIOS bootloader (16/32-bit GAS assembly)
arch/x86/kernel/   x86 kernel entry (assembly) and linker script
include/           Public headers (by area, e.g. include/io/)
kernel/            Portable kernel C code
drivers/           Device drivers (e.g. drivers/io/)
docs/              Notes and design sketches
scripts/           GDB helpers and other tooling
Makefile           Top-level build
```

## Building

### Build Dependencies

- `gcc` (with 32-bit support, e.g. `lib32-gcc-libs` or `gcc-multilib`)
- GNU `make`
- GNU `binutils` (`as`, `ld`, `objcopy`)

### Runtime Dependencies

- `qemu` (`qemu-system-i386`)

### Building an image

1. Clone this repository:

```console
$ git clone https://github.com/reqseq/statix
$ cd statix
```

2. Build the disk image (`images/statix.img`; objects in `build/`):

```console
$ make image
```

Useful variables:

- `V=1` shows full build commands
- `KCFLAGS=...` appends extra C compiler flags
- `KAFLAGS=...` appends extra assembler flags
- `LDFLAGS=...` appends extra linker flags
- `O=...` or `KBUILD_OUTPUT=...` writes output to another directory

### Running in a VM

```console
$ make run
```

This launches `images/statix.img` under `qemu-system-i386`.

### Debugging

In one terminal, start QEMU waiting for GDB:

```console
$ make run-debug
```

In another, attach. The debug target loads `build/kernel.elf` by default, or
the matching `build/kernel.elf` under the selected output directory when
`O=...` or `KBUILD_OUTPUT=...` is used:

```console
$ make connect-gdb
```

### Cleaning

```console
$ make clean
```

## Notes

- The boot sector currently loads two sectors starting at disk sector 2. The
  kernel must remain within that limit until the loader grows more capable.
- The kernel currently demonstrates protected-mode entry by reading the VGA
  cursor position and writing a character at that location.

## References

- [OSDev wiki](https://osdev.wiki/wiki/Expanded_Main_Page)
- [Unikraft](https://unikraft.org/)
- [os-tutorial](https://github.com/cfenollosa/os-tutorial)
- [Writing a Simple Operating System — from Scratch](https://angom.myweb.cs.uwindsor.ca/teaching/cs330/WritingOS.pdf) by Nick Blundell
