#include <io/ports.h>

enum {
	VGA_CRTC_INDEX_PORT    = 0x3d4,
	VGA_CRTC_DATA_PORT     = 0x3d5,
	VGA_CURSOR_HIGH_REG    = 14,
	VGA_CURSOR_LOW_REG     = 15,
	VGA_TEXT_BUFFER        = 0xb8000,
	VGA_WHITE_ON_BLACK     = 0x0f,
	VGA_CELL_SIZE          = 2,
};

static unsigned short vga_cursor_position(void)
{
	unsigned short position;

	port_byte_out(VGA_CRTC_INDEX_PORT, VGA_CURSOR_HIGH_REG);
	position = (unsigned short)port_byte_in(VGA_CRTC_DATA_PORT) << 8;

	port_byte_out(VGA_CRTC_INDEX_PORT, VGA_CURSOR_LOW_REG);
	position |= port_byte_in(VGA_CRTC_DATA_PORT);

	return position;
}

void kernel_main(void)
{
	unsigned short offset;
	volatile unsigned char *vga;

	offset = vga_cursor_position() * VGA_CELL_SIZE;
	vga = (volatile unsigned char *)VGA_TEXT_BUFFER;

	vga[offset] = 'X';
	vga[offset + 1] = VGA_WHITE_ON_BLACK;
}
