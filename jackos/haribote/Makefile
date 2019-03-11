TOOLPATH = ../../z_tools/
INCPATH	 = ../../z_tools/haribote/

OBJS_BOOTPACK = bootpack.obj naskfunc.obj hankaku.obj graphic.obj \
		dsctbl.obj int.obj fifo.obj keyboard.obj \
		mouse.obj memory.obj sheet.obj timer.obj mtask.obj \
		file.obj window.obj console.obj tek.obj

MAKE     = $(TOOLPATH)make.exe -r
NASK     = $(TOOLPATH)nask.exe
CC1		 = $(TOOLPATH)cc1.exe -I$(INCPATH) -Os -Wall -quiet
GAS2NASK = $(TOOLPATH)gas2nask.exe -a
OBJ2BIM  = $(TOOLPATH)obj2bim.exe
MAKEFONT = $(TOOLPATH)makefont.exe
BIN2OBJ  = $(TOOLPATH)bin2obj.exe
BIM2HRB  = $(TOOLPATH)bim2hrb.exe
RULEFILE = ../haribote.rul
EDIMG    = $(TOOLPATH)edimg.exe
IMGTOL   = $(TOOLPATH)imgtol.com
GOLIB	 = $(TOOLPATH)golib00.exe
COPY     = copy
DEL      = del

#默认目标
default :
	$(MAKE) ipl09.bin
	$(MAKE) jackos.sys

ipl09.bin : ipl09.nas Makefile
	$(NASK) ipl09.nas ipl09.bin ipl09.lst
	
asmhead.bin : asmhead.nas Makefile
	$(NASK) asmhead.nas asmhead.bin asmhead.lst
	
hankaku.bin	: hankaku.txt Makefile
	$(MAKEFONT) hankaku.txt hankaku.bin

hankaku.obj : hankaku.bin Makefile
	$(BIN2OBJ) hankaku.bin hankaku.obj _hankaku

naskfunc.obj : naskfunc.nas Makefile
	$(NASK) naskfunc.nas naskfunc.obj naskfunc.lst

bootpack.bim : $(OBJS_BOOTPACK) Makefile
	$(OBJ2BIM) @$(RULEFILE) out:bootpack.bim stack:3136k map:bootpack.map \
		$(OBJS_BOOTPACK)
# 3MB+64KB=3136KB

bootpack.hrb : bootpack.bim Makefile
	$(BIM2HRB) bootpack.bim bootpack.hrb 0

jackos.sys : asmhead.bin bootpack.hrb Makefile
	copy /B asmhead.bin /B + bootpack.hrb jackos.sys
		
#一般规则
%.gas : %.c Makefile
	@$(CC1) -o $*.gas $*.c

%.nas : %.gas Makefile
	@$(GAS2NASK) $*.gas $*.nas

%.obj : %.nas Makefile
	@$(NASK) $*.nas $*.obj $*.lst
	
clean :
	-$(DEL) asmhead.bin
	-$(DEL) hankaku.bin
	-$(DEL) *.lst
	-$(DEL) *.obj
	-$(DEL) *.hrb
	-$(DEL) *.bim
	-$(DEL) *.bin
	-$(DEL) jackos.sys
	-$(DEL) bootpack.map
	
src_only :
	$(MAKE) clean
	-$(DEL) ipl09.bin
	-$(DEL) jackos.sys
