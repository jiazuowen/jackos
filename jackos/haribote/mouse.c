#include "bootpack.h"

struct FIFO32 *mousefifo;
int mousedata0;

void inthandler2c(int* esp)
/*来自PS/2鼠标的中断*/
{
	unsigned char data;
	io_out8(PIC1_OCW2, 0x64); 	// 通知PIC1 IRQ-12受理完成
	io_out8(PIC0_OCW2, 0x62);	// 通知PIC0 IRQ-02受理完成
	data = io_in8(PORT_KEYDAT);
	fifo32_put(mousefifo, data + mousedata0);
	return;
}

#define KEYCMD_SENDTO_MOUSE			0xd4
#define MOUSECMD_ENABLE				0xf4

void enable_mouse(struct FIFO32 *fifo, int data0, struct MOUSE_DEC* mdec)
/*激活鼠标*/
{
	/*将FIFO缓冲区的信息保存到全局变量里*/
	mousefifo = fifo;
	mousedata0 = data0;
	/*鼠标有效*/
	wait_KBC_sendready();
	io_out8(PORT_KEYCMD, KEYCMD_SENDTO_MOUSE);
	wait_KBC_sendready();
	io_out8(PORT_KEYDAT, MOUSECMD_ENABLE);
	mdec->phase = 0; // 等待0xfa的阶段
	return; /*顺利的话，键盘控制电路返回ACK(0xfa)*/
}

int mouse_decode(struct MOUSE_DEC* mdec, unsigned char data)
{
	if (mdec->phase == 0) {
		// 等待鼠标的0xfa的阶段
		if (data == 0xfa) {
			mdec->phase = 1;
		}
		return 0;
	}
	if (mdec->phase == 1) {
		// 等待鼠标第一字节
		if ((data & 0xc8) == 0x08) {
			mdec->buf[0] = data;
			mdec->phase = 2;
		}
		return 0;
	}
	if (mdec->phase == 2) {
		/* 等待鼠标第二字节 */
		mdec->buf[1] = data;
		mdec->phase = 3;
		return 0;
	}
	if (mdec->phase == 3) {
		/* 等待鼠标第三字节 */
		mdec->buf[2] = data;
		mdec->phase = 1;
		mdec->btn = mdec->buf[0] & 0x07;
		mdec->x = mdec->buf[1];
		mdec->y = mdec->buf[2];
		if ((mdec->buf[0] & 0x10) != 0) {
			mdec->x |= 0xffffff00;
		}
		if ((mdec->buf[0] & 0x20) != 0) {
			mdec->y |= 0xffffff00;
		}
		mdec->y = - mdec->y;	// 鼠标的y方向和画面符号相反
		return 1;
	}
	return -1;
}

