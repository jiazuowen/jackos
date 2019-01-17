; jackos-ipl�C??������?��(Initial Program Loader)
; TAB=4

CYLS	EQU		10				; CYLS���, CYLS=10

		ORG		0x7c00			; �w�������I��?�n��

; �ꉺ�I?�q�p��?�y�IFAT12�i��??

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; �u�[�g�Z�N�^�̖��O�����R�ɏ����Ă悢�i8�o�C�g�j
		DW		512				; 1�Z�N�^�̑傫���i512�ɂ��Ȃ���΂����Ȃ��j
		DB		1				; �N���X�^�̑傫���i1�Z�N�^�ɂ��Ȃ���΂����Ȃ��j
		DW		1				; FAT���ǂ�����n�܂邩�i���ʂ�1�Z�N�^�ڂ���ɂ���j
		DB		2				; FAT�̌��i2�ɂ��Ȃ���΂����Ȃ��j
		DW		224				; ���[�g�f�B���N�g���̈�̑傫���i���ʂ�224�G���g���ɂ���j
		DW		2880			; ���̃h���C�u�̑傫���i2880�Z�N�^�ɂ��Ȃ���΂����Ȃ��j
		DB		0xf0			; ���f�B�A�̃^�C�v�i0xf0�ɂ��Ȃ���΂����Ȃ��j
		DW		9				; FAT�̈�̒����i9�Z�N�^�ɂ��Ȃ���΂����Ȃ��j
		DW		18				; 1�g���b�N�ɂ����̃Z�N�^�����邩�i18�ɂ��Ȃ���΂����Ȃ��j
		DW		2				; �w�b�h�̐��i2�ɂ��Ȃ���΂����Ȃ��j
		DD		0				; �p�[�e�B�V�������g���ĂȂ��̂ł����͕K��0
		DD		2880			; ���̃h���C�u�傫����������x����
		DB		0,0,0x29		; �悭�킩��Ȃ����ǂ��̒l�ɂ��Ă����Ƃ����炵��
		DD		0xffffffff		; ���Ԃ�{�����[���V���A���ԍ�
		DB		"HARIBOTEOS "	; �f�B�X�N�̖��O�i11�o�C�g�j
		DB		"FAT12   "		; �t�H�[�}�b�g�̖��O�i8�o�C�g�j
		RESB	18				; �Ƃ肠����18�o�C�g�����Ă���

; �����j�S

entry:
		MOV		AX,0			; ���n��
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; ?��?

		MOV		AX,0x0820
		MOV		ES,AX			; ES�����i�񑶊�C?�ݓ����n��?0x0820 * 16 = 0x8200
		MOV		CH,0			;����0
		MOV		DH,0			;��?0
		MOV		CL,2			;���2
readloop:
		MOV		SI,0			; ??��?�����I�񑶊�
retry:
		MOV		AH,0x02			; AH=0x02??�C0x03��?
		MOV		AL,1			; 1�꘢���
		MOV		BX,0			; BX��񑶊�
		MOV		DL,0x00			; A??��
		INT		0x13			; ?�p��?BIOS
		JNC		next			; �v�L�o?��?��next
		ADD		SI,1			; SI+=1
		CMP		SI,5			; ��?SI�a5
		JAE		error			; SI >= 5 ?��?��error
		MOV		AH,0x00
		MOV		DL,0x00			; A??��
		INT		0x13			; �d�u??��
		JMP		retry
next:
		MOV		AX,ES			; �c�����n���@��0x200
		ADD		AX,0x0020		; 0x0020 x 16 = 0x200 �g�p[ES:BX]
		MOV		ES,AX			; �v�LADD ES,0x020??�I�w�߁C����??��
		ADD		CL,1			; CL+=1
		CMP		CL,18			; CL�a18��?
		JBE		readloop		; CL <= 18 ?��?��readloop
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readloop		; DH < 2 ?��?��readloop
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS
		JB		readloop		; CH < CYLS ?��?��readloop

; �ǂݏI��������ǂƂ肠������邱�ƂȂ��̂ŐQ��
		
		MOV		[0x0ff0],CH
		JMP		0xc200

error:
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; SI��1�𑫂�
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; ?���꘢����
		MOV		BX,15			; �w������?�F
		INT		0x10			; ?�p??BIOS
		JMP		putloop
fin:
		HLT						; ?CPU��~�C���Җ���
		JMP		fin				; �ٌ��z?
msg:
		DB		0x0a, 0x0a		; ?��?�s
		DB		"load error"
		DB		0x0a			; ?�s
		DB		0

		RESB	0x7dfe-$		; �U��0x00,����0x7dfe

		DB		0x55, 0xaa
