;naskfunc
;TAB=4

[FORMAT "WCOFF"]		;制作目标文件的模式
[INSTRSET "i486p"]		;这个程序是个486用的
[BITS 32]				;制作32二位模式用的语言
[FILE "naskfunc.nas"]	;源文件名称

	GLOBAL	_io_hlt, _io_cli, _io_sti, _io_stihlt
	GLOBAL  _io_in8, _io_in16, _io_in32
	GLOBAL  _io_out8, _io_out16, _io_out32
	GLOBAL  _io_load_eflags, _io_store_eflags
	GLOBAL  _load_gdtr, _load_idtr
	GLOBAL  _asm_inthandler21, _asm_inthandler27, _asm_inthandler2c
	EXTERN 	_inthandler21, _inthandler27, _inthandler2c

[SECTION .text]			;目标文件中写了这些之后再写程序


_io_hlt:				; void io_hlt(void)
	HLT
	RET
	
_io_cli:
	CLI
	RET

_io_sti:
	STI
	RET
	
_io_stihlt:
	STI
	HLT
	RET
	
_io_in8:			;int io_in8(int port)
	MOV		EDX,[ESP+4]		;Port
	MOV		EAX,0
	IN		AL,DX
	RET

_io_in16:			; int io_in16(int port);
	MOV		EDX,[ESP+4]		; port
	MOV		EAX,0
	IN		AX,DX
	RET

_io_in32:			; int io_in32(int port);
	MOV		EDX,[ESP+4]		; port
	IN		EAX,DX
	RET

_io_out8:
	MOV		EDX,[ESP+4]		;port
	MOV		AL,[ESP+8]		;data
	OUT		DX,AL
	RET

_io_out16:			; void io_out16(int port, int data);
	MOV		EDX,[ESP+4]		; port
	MOV		EAX,[ESP+8]		; data
	OUT		DX,AX
	RET

_io_out32:			; void io_out32(int port, int data);
	MOV		EDX,[ESP+4]		; port
	MOV		EAX,[ESP+8]		; data
	OUT		DX,EAX
	RET

_io_load_eflags:	; int io_load_eflags(void);
	PUSHFD			;指的是 PUSH eflags
	POP		EAX
	RET

_io_store_eflags:	; void io_store_eflags(int eflags);
	MOV		EAX,[ESP+4]
	PUSH    EAX
	POPFD			;指的是 Pop eflags
	RET

_load_gdtr:			; void load_gdtr(int limit, int addr);
	MOV		AX,[ESP+4]		; limit
	MOV		[ESP+6],AX
	LGDT	[ESP+6]
	RET
	
_load_idtr:			; void load_idtr(int limit, int addr);
	MOV		AX,[ESP+4]		; limit
	MOV		[ESP+6],AX
	LIDT	[ESP+6]
	RET
	
_asm_inthandler21:
	PUSH	ES
	PUSH	DS
	PUSHAD
	MOV		EAX,ESP
	PUSH	EAX
	MOV		AX,SS
	MOV		DS,AX
	MOV		ES,AX
	CALL	_inthandler21
	POP		EAX
	POPAD
	POP		DS
	POP		ES
	IRETD
		
_asm_inthandler27:
	PUSH	ES
	PUSH	DS
	PUSHAD
	MOV		EAX,ESP
	PUSH	EAX
	MOV		AX,SS
	MOV		DS,AX
	MOV		ES,AX
	CALL	_inthandler27
	POP		EAX
	POPAD
	POP		DS
	POP		ES
	IRETD

_asm_inthandler2c:
	handler2c:
	PUSH	ES
	PUSH	DS
	PUSHAD
	MOV		EAX,ESP
	PUSH	EAX
	MOV		AX,SS
	MOV		DS,AX
	MOV		ES,AX
	CALL	_inthandler2c
	POP		EAX
	POPAD
	POP		DS
	POP		ES
	IRETD
