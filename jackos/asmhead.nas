; jack-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; bootpackのロード先
DSKCAC	EQU		0x00100000		; ディスクキャッシュの場所
DSKCAC0	EQU		0x00008000		; ディスクキャッシュの場所（リアルモード）

; BOOT_INFO関係
CYLS	EQU		0x0ff0			; ブートセクタが設定する
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; 色数に関する情報。何ビットカラーか？
SCRNX	EQU		0x0ff4			; 解像度のX
SCRNY	EQU		0x0ff6			; 解像度のY
VRAM	EQU		0x0ff8			; グラフィックバッファの開始番地

		ORG		0xc200			; このプログラムがどこに読み込まれるのか

; 画面モードを設定

		MOV		AL,0x13			; VGAグラフィックス、320x200x8bitカラー
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; 画面モードをメモする（C言語が参照する）
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; キーボードのLED状態をBIOSに教えてもらう

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; PIC??一切中断
;	根据AT兼容机的?格，如果要初始化PIC
;	必?在CLI之前?行，否?有?会挂起
;	随后?行PIC的初始化

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						;NOP休息一个???的??， 如果???行OUT指令，有些机?会无法正常?行
		OUT		0xa1,AL

		CLI						; 禁止CPU??的中断

; ?了?CPU能???1MB以上的内存空?，?定A20GATE

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; 切?到保?模式

[INSTRSET "i486p"]				; 想使用486指令的叙述

		LGDT	[GDTR0]			; ?定??GDT
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; ?置bit31?0（?了禁止分?）
		OR		EAX,0x00000001	; ?置bit0?1 （?了切?到保?模式）
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			;  可?写的段
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack的?送

		MOV		ESI,bootpack	; ?送源
		MOV		EDI,BOTPAK		; ?送目的地
		MOV		ECX,512*1024/4
		CALL	memcpy

; 磁?数据最??送到它本来的位置去

; 首先从??扇区?始

		MOV		ESI,0x7c00		; ?送源
		MOV		EDI,DSKCAC		; ?送目的地
		MOV		ECX,512/4
		CALL	memcpy

; 所有剩下的

		MOV		ESI,DSKCAC0+512	; ?送源
		MOV		EDI,DSKCAC+512	; ?送目的地
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; 从柱面数???字?数/4
		SUB		ECX,512/4		; ?去IPL
		CALL	memcpy

; 必?由asmhead来完成的工作，至此已?全部完成
;	以后就交由bootpack来完成

; bootpack的??

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; 没有要?送的?西?
		MOV		ESI,[EBX+20]	; ?送源
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; ?送目的地
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; ?初始?
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		AL,0x64
		AND		AL,0x02
		IN		AL,0x60			; 空?（?了清空数据接收?冲区的??数据）
		JNZ		waitkbdout		; AND的?果如果不是0，就跳到waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; ?法的?果如果不是0，就跳到memcpy
		RET
; memcpyはアドレスサイズプリフィクスを入れ忘れなければ、ストリング命令でも書ける

		ALIGNB	16
GDT0:
		RESB	8				; NULL selector
		DW		0xffff,0x0000,0x9200,0x00cf	; 可以?写的段(segment)32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; 可以?行的段(segment)32bit (bootpack用)

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
