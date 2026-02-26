# Statix

Statix is a minimal x86 **unikernel** built from scratch, aiming to bundle the application and kernel into a single, bootable binary image.

## Building

### Build Dependencies:

- `gcc`
- `nasm`
- GNU make
- GNU binutils

### Runtime Dependencies:

- `qemu`

### Getting an image:

1. Clone this repository:

```console
$ git clone https://github.com/reqseq/statix
```

2. Then compile with:

```console
$ cd src/
$ make statix
```

### Running in a VM

Run the image in `qemu` with:

```console
$ make run
```

## Resources | Reference | Inspiration

- [OSDev wiki](https://osdev.wiki/wiki/Expanded_Main_Page)
- [The Linux Kernel](https://kernel.org/)
- [Unikraft](https://unikraft.org/)
- [os-tutorial](https://github.com/cfenollosa/os-tutorial)
- [Writing a Simple Operating System — from Scratch](https://angom.myweb.cs.uwindsor.ca/teaching/cs330/WritingOS.pdf) by Nick Blundell
