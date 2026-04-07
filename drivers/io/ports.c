#include <io/ports.h>

unsigned char port_byte_in(unsigned short port)
{
	unsigned char value;

	__asm__ volatile("in %%dx, %%al" : "=a"(value) : "d"(port));
	return value;
}

void port_byte_out(unsigned short port, unsigned char data)
{
	__asm__ volatile("out %%al, %%dx" : : "a"(data), "d"(port));
}

unsigned short port_word_in(unsigned short port)
{
	unsigned short value;

	__asm__ volatile("in %%dx, %%ax" : "=a"(value) : "d"(port));
	return value;
}

void port_word_out(unsigned short port, unsigned short data)
{
	__asm__ volatile("out %%ax, %%dx" : : "a"(data), "d"(port));
}
