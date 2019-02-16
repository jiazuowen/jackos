TOOLPATH = ../z_tools/
INCPATH	 = ../z_tools/haribote/


OBJS_BOOTPACK = bootpack.obj naskfunc.obj hankaku.obj graphic.obj \
		dsctbl.obj int.obj fifo.obj keyboard.obj \
		mouse.obj memory.obj sheet.obj timer.obj mtask.obj \
		file.obj window.obj console.obj

MAKE     = $(TOOLPATH)make.exe -r
NASK     = $(TOOLPATH)nask.exe
CC1		 = $(TOOLPATH)cc1.exe -I$(INCPATH) -Os -Wall -quiet
GAS2NASK = $(TOOLPATH)gas2nask.exe -a
OBJ2BIM  = $(TOOLPATH)obj2bim.exe
MAKEFONT = $(TOOLPATH)makefont.exe
BIN2OBJ  = $(TOOLPATH)bin2obj.exe
BIM2HRB  = $(TOOLPATH)bim2hrb.exe
RULEFILE = $(TOOLPATH)haribote/haribote.rul
EDIMG    = $(TOOLPATH)edimg.exe
IMGTOL   = $(TOOLPATH)imgtol.com
COPY     = copy
DEL      = del

#默认目标
default :
	$(MAKE) img

ipl.bin : ipl.nas Makefile
	$(NASK) ipl.nas ipl.bin ipl.lst
	
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

# hello.hrb : hello.nas Makefile
# 	$(NASK) hello.nas hello.hrb hello.lst
	
jackos.sys : asmhead.bin bootpack.hrb Makefile
	copy /B asmhead.bin /B + bootpack.hrb jackos.sys

jackos.img : ipl.bin jackos.sys hello.hrb hello2.hrb Makefile
	$(EDIMG)   imgin:$(TOOLPATH)fdimg0at.tek \
		wbinimg src:ipl.bin len:512 from:0 to:0 \
		copy from:jackos.sys to:@: \
		copy from:ipl.nas to:@: \
		copy from:make.bat to:@: \
		copy from:hello.hrb to:@: \
		copy from:hello2.hrb to:@: \
		imgout:jackos.img
		
#一般规则
%.gas : %.c Makefile
	$(CC1) -o $*.gas $*.c

%.nas : %.gas Makefile
	$(GAS2NASK) $*.gas $*.nas

%.obj : %.nas Makefile
	$(NASK) $*.nas $*.obj $*.lst

%.hrb : %.nas Makefile
	$(NASK) $*.nas $*.hrb $*.lst

img :
	$(MAKE) jackos.img
	
run :
	$(MAKE) img
	$(COPY) jackos.img ..\z_tools\qemu\fdimage0.bin
	$(MAKE) -C ../z_tools/qemu

run_only:
	$(COPY) jackos.img ..\z_tools\qemu\fdimage0.bin
	$(MAKE) -C ../z_tools/qemu
	
clean :
	-$(DEL) *.bin
	-$(DEL) *.lst
	-$(DEL) *.obj
	-$(DEL) *.hrb
	-$(DEL) bootpack.map
	-$(DEL) bootpack.bim
	-$(DEL) jackos.sys
	
src_only :
	$(MAKE) clean
	-$(DEL) jackos.img