void main(void)
{
	volatile char *video_memory;

	video_memory = (volatile char *)0xb8000;

	video_memory[0] = 'X';
}
