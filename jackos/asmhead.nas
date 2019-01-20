; jack-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		;
DSKCAC	EQU		0x00100000		;
DSKCAC0	EQU		0x00008000		;

; 有关BOOT_INFO
CYLS	EQU		0x0ff0			; 启动区读硬盘读到何处为止
LEDS	EQU		0x0ff1			; 启动时键盘LED的状态
VMODE	EQU		0x0ff2			; 显卡模式为多少位彩色变量地址
SCRNX	EQU		0x0ff4			; 画面分辨率X变量地址
SCRNY	EQU		0x0ff6			; 画面分辨率Y变量地址
VRAM	EQU		0x0ff8			; 图像缓冲区的地址

		ORG		0xc200			; 程序在内存中的加载地址

; 

		MOV		AL,0x13			; VGA显卡，320*200*8位色彩, 这种模式下的VRAM在0xa0000~0xaffff中共64KB
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8				; [VMODE] = 8
		MOV		WORD [SCRNX],320			; [SCRNX] = 320
		MOV		WORD [SCRNY],200			; [SCRNY] = 200
		MOV		DWORD [VRAM],0x000a0000		; [VRAM] = 0x000a0000	必须这样，这是规定

; 使用BOIS取得键盘上各种LED指示灯的状态

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; PIC关闭一切中断
;	根据AT兼容机的规格，如果要初始化PIC
;	必需在CLI之前进行，否则有时会挂起
;	随后进行PIC初始化

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; 如果连续执行OUT指令，有些机种无法正常运行, NOP让CPU休息一个时钟长度
		OUT		0xa1,AL

		CLI						; 禁止CPU级别的中断

; 为了让CPU能访问1MB以上的内存，设定A20GATE

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL			; OUT 向0x64号外设写一个字节
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; 切换到保护模式

[INSTRSET "i486p"]				; 使用486指令 的描述

		LGDT	[GDTR0]			; 设置临时GDT
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; 设置bit31为0(为了禁止分页)
		OR		EAX,0x00000001	; 设置bit0为1(为了切换到保护模式)
		MOV		CR0,EAX
		JMP		pipelineflush	; 应为模式变了，要重新解释一遍，所以加入了JMP命令
pipelineflush:
		MOV		AX,1*8			;  可读写的段32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack的转送

		MOV		ESI,bootpack	; 转送源
		MOV		EDI,BOTPAK		; 转送目的地
		MOV		ECX,512*1024/4	; 512KB是自己决定的，要比bootpack.hrb的长度大很多
		CALL	memcpy

; 磁盘数据最终转送到它本来的位置去

; 首先从启动扇区开始

		MOV		ESI,0x7c00		; 转送源
		MOV		EDI,DSKCAC		; 装送目的地
		MOV		ECX,512/4
		CALL	memcpy

; 所有剩下的

		MOV		ESI,DSKCAC0+512	; 转送源
		MOV		EDI,DSKCAC+512	; 转送目的地
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; 从柱面数变换为字节数/4
		SUB		ECX,512/4		; 减去IPL
		CALL	memcpy

; 必须由asmhead.nas完成的工作，至此已经全部完成
;	以后交由bootpack完成

; bootpack启动

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; 没有要转送的东西时
		MOV		ESI,[EBX+20]	; 转送源
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; 转送目的地
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; 栈初始值
		JMP		DWORD 2*8:0x0000001b	;  将2*8带入CS中，同时移动到0x1b号地址, 第二段的0x1b, 是0x280000+0x1b

waitkbdout:
		IN		AL,0x64
		AND		AL,0x02
		IN		AL,0x60			; 读空(为了清空数据接收缓冲区的垃圾数据)
		JNZ		waitkbdout		; AND的结果如果不是0，就跳转到waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; 减法运算的结果如果不是0，就跳转到memcpy
		RET
; memcpy

		ALIGNB	16				; 一直添加DBO直到地址被16整除时
GDT0:
		RESB	8				; NULL selector
		DW		0xffff,0x0000,0x9200,0x00cf	; 可以读写的段(segment)32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; 可以执行的段(segment)32bit(bootpack用)

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
