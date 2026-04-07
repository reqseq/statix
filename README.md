# Statix

Statix is a small 32-bit x86 kernel and BIOS boot path built from scratch.

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

Useful variables: `V=1`, `KCFLAGS=...`, `KAFLAGS=...`, `LDFLAGS=...`,
`O=...`, and `KBUILD_OUTPUT=...`.

### Running in a VM

```console
$ make run
```

### Debugging

Start QEMU waiting for GDB:

```console
$ make run-debug
```

Attach from another terminal:

```console
$ make connect-gdb
```

### Cleaning

```console
$ make clean
```

## References

- [OSDev wiki](https://osdev.wiki/wiki/Expanded_Main_Page)
- [Unikraft](https://unikraft.org/)
- [os-tutorial](https://github.com/cfenollosa/os-tutorial)
- [Writing a Simple Operating System — from Scratch](https://angom.myweb.cs.uwindsor.ca/teaching/cs330/WritingOS.pdf) by Nick Blundell
