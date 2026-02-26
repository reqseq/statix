CC = gcc
CFLAGS = -m32

all: statix

kernel_entry.o: kernel_entry.asm
	nasm $< -f elf -o $@

kernel.o: kernel.c
	# i686-unknown-linux-gnu-gcc -ffreestanding -c $< -o $@
	$(CC) $(CFLAGS) -ffreestanding -c $< -o $@

kernel.bin: kernel_entry.o kernel.o
	# i686-unknown-linux-gnu-ld -o $@ -Ttext 0x1000 $^ --oformat binary
	$(CC) $(CFLAGS) -o $@ -Ttext 0x1000 $^ --oformat binary

kernel.dis:
	ndisasm -b 32 $< > $@

bootsect.bin: bootsect.asm
	nasm $< -f bin -o $@

statix: bootsect.bin kernel.bin
	cat $^ > $@.bin

run: os-image.bin
	qemu-system-i386 $<

clean:
	rm -f *.bin *.o *.dis
