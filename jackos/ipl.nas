; jackos-ipl，??程序加?器(Initial Program Loader)
; TAB=4

CYLS	EQU		10				; CYLS常量, CYLS=10

		ORG		0x7c00			; 指明程序的装?地址

; 一下的?述用于?准的FAT12格式??

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; ブートセクタの名前を自由に書いてよい（8バイト）
		DW		512				; 1セクタの大きさ（512にしなければいけない）
		DB		1				; クラスタの大きさ（1セクタにしなければいけない）
		DW		1				; FATがどこから始まるか（普通は1セクタ目からにする）
		DB		2				; FATの個数（2にしなければいけない）
		DW		224				; ルートディレクトリ領域の大きさ（普通は224エントリにする）
		DW		2880			; このドライブの大きさ（2880セクタにしなければいけない）
		DB		0xf0			; メディアのタイプ（0xf0にしなければいけない）
		DW		9				; FAT領域の長さ（9セクタにしなければいけない）
		DW		18				; 1トラックにいくつのセクタがあるか（18にしなければいけない）
		DW		2				; ヘッドの数（2にしなければいけない）
		DD		0				; パーティションを使ってないのでここは必ず0
		DD		2880			; このドライブ大きさをもう一度書く
		DB		0,0,0x29		; よくわからないけどこの値にしておくといいらしい
		DD		0xffffffff		; たぶんボリュームシリアル番号
		DB		"HARIBOTEOS "	; ディスクの名前（11バイト）
		DB		"FAT12   "		; フォーマットの名前（8バイト）
		RESB	18				; とりあえず18バイトあけておく

; 程序核心

entry:
		MOV		AX,0			; 初始化
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; ?磁?

		MOV		AX,0x0820
		MOV		ES,AX			; ES附加段寄存器，?在内存地址?0x0820 * 16 = 0x8200
		MOV		CH,0			;柱面0
		MOV		DH,0			;磁?0
		MOV		CL,2			;扇区2
readloop:
		MOV		SI,0			; ??失?次数的寄存器
retry:
		MOV		AH,0x02			; AH=0x02??，0x03写?
		MOV		AL,1			; 1一个扇区
		MOV		BX,0			; BX基址寄存器
		MOV		DL,0x00			; A??器
		INT		0x13			; ?用磁?BIOS
		JNC		next			; 没有出?跳?到next
		ADD		SI,1			; SI+=1
		CMP		SI,5			; 比?SI和5
		JAE		error			; SI >= 5 ?跳?到error
		MOV		AH,0x00
		MOV		DL,0x00			; A??器
		INT		0x13			; 重置??器
		JMP		retry
next:
		MOV		AX,ES			; 把内存地址后移0x200
		ADD		AX,0x0020		; 0x0020 x 16 = 0x200 使用[ES:BX]
		MOV		ES,AX			; 没有ADD ES,0x020??的指令，所以??干
		ADD		CL,1			; CL+=1
		CMP		CL,18			; CL和18比?
		JBE		readloop		; CL <= 18 ?跳?到readloop
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readloop		; DH < 2 ?跳?到readloop
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS
		JB		readloop		; CH < CYLS ?跳?到readloop

; 読み終わったけどとりあえずやることないので寝る
		
		MOV		[0x0ff0],CH
		JMP		0xc200

error:
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; SIに1を足す
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; ?示一个文字
		MOV		BX,15			; 指示字符?色
		INT		0x10			; ?用??BIOS
		JMP		putloop
fin:
		HLT						; ?CPU停止，等待命令
		JMP		fin				; 无限循?
msg:
		DB		0x0a, 0x0a		; ?次?行
		DB		"load error"
		DB		0x0a			; ?行
		DB		0

		RESB	0x7dfe-$		; 填写0x00,直到0x7dfe

		DB		0x55, 0xaa
