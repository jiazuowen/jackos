; jackos-ipl (Initial Program Loader)
; TAB=4

CYLS	EQU		20				;

		ORG		0x7c00			; 指明程序的装载地址

; 一下是记述于标准的FAT12格式的软盘

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; 启动区的名称，任意的8个字节
		DW		512				; 每个扇区的大小，必须是512个字节
		DB		1				; 簇的(cluster)大小(必须为一个扇区)
		DW		1				; FAT的起始位置(一般从第一个扇区开始)
		DB		2				; FAT的个数(必须为2)
		DW		224				; 根目录的大小(一般设成224项)
		DW		2880			; 该磁盘的大小(必须为2889个扇区)
		DB		0xf0			; 磁盘的种类(必须是0xf0)
		DW		9				; FAT的长度(必须是9个扇区)
		DW		18				; 一个磁道(track)由几个扇区(必须是18)
		DW		2				; 磁头数(必须是2)
		DD		0				; 不使用分区(必须是0)
		DD		2880			; 重写一次磁盘的大小
		DB		0,0,0x29		; 意义不明，固定
		DD		0xffffffff		; (可能是)卷标号码
		DB		"HARIBOTEOS "	; 磁盘的名称(11字节)
		DB		"FAT12   "		; 磁盘格式名(8字节)
		RESB	18				; 先空出18个字节

; 程序核心

entry:
		MOV		AX,0			; 初始化寄存器
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; 读磁盘

		MOV		AX,0x0820
		MOV		ES,AX			; ES * 16 = 0x8200 实际的内存地址
		MOV		CH,0			; 柱面0
		MOV		DH,0			; 磁头0
		MOV		CL,2			; 扇区2
readloop:
		MOV		SI,0			; 记录失败次数的寄存器
retry:							; 试错
		MOV		AH,0x02			; AH=0x02 读入磁盘
		MOV		AL,1			; 1个扇区
		MOV		BX,0			;
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 调用磁盘BOIS
		JNC		next			; 没有出错的话跳转到next
		ADD		SI,1			; SI+=1
		CMP		SI,5			; 比较SI和5
		JAE		error			; SI >= 5 时，跳转到error
		MOV		AH,0x00
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 重置驱动器
		JMP		retry
next:
		MOV		AX,ES			; 内存地址后移0x200个位置
		ADD		AX,0x0020		; 0x0020 x 16 = 0x200 使用的时[ES:BX] ES*16+BX代表实际地址
		MOV		ES,AX			; 因为没有ADD ES,0x020的指令，所以绕弯了
		ADD		CL,1			; CL+=1
		CMP		CL,18			; 比较CL和18
		JBE		readloop		; CL <= 18 时，跳转到readloop
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readloop		; DH < 2 时，跳转到readloop
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS
		JB		readloop		; CH < CYLS 时，跳转到readloop

;
		
		MOV		[0x0ff0],CH
		JMP		0xc200			; 操作系统程序在内存中的位置

error:
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1			;
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; 显示一个文字
		MOV		BX,15			; 指定字符颜色
		INT		0x10			; 调用显卡BOIS
		JMP		putloop
fin:
		HLT						; 让CPU停止等待指令
		JMP		fin				; 无限循环
msg:
		DB		0x0a, 0x0a		; 换行2次
		DB		"load error"
		DB		0x0a			; 换行
		DB		0

		RESB	0x7dfe-$		; = 0x7e00 - 2 - $

		DB		0x55, 0xaa		; 最后两个字节必须是 0x55,0xaa
