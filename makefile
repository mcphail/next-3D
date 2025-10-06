IDIR=../include
CC=zcc
CFLAGS=+zxn -vn -c -SO3 --list --c-code-in-asm --opt-code-speed -clib=sdcc_iy -pragma-include:zpragma.inc --max-allocs-per-node300000
ODIR=obj
LDIR=../lib
LIBS=-lm

ifeq ($(OS),Windows_NT)
    CP=copy /y
	DD=%userprofile%/Dev/next/dev
else
	CP=cp -f
	DD=~/Dev/next/dev
endif

OBJS = \
	$(ODIR)/main.o \
	$(ODIR)/kernel.o \
	$(ODIR)/irq.o \
	$(ODIR)/data.o \
	$(ODIR)/render.o \
	$(ODIR)/clipping.o \
	$(ODIR)/maths.o \
	$(ODIR)/experiments.o \
	$(ODIR)/render_3D.o \
	$(ODIR)/sprites.o

next-3D.nex: $(OBJS)
	$(CC) +zxn -vn -m --list --c-code-in-asm -clib=sdcc_iy -Cz"--clean" -pragma-include:zpragma.inc -startup=1 --math32 $(OBJS) -o next-3D.nex -create-app -subtype=nex

# Prerequisites
#
$(ODIR):
	mkdir -p $@

# Main program at $8000
#
$(ODIR)/main.o: main.c main.h | $(ODIR)
	$(CC) $(CFLAGS) -o $(ODIR)/main.o main.c

$(ODIR)/experiments.o: experiments.c experiments.h | $(ODIR)
	$(CC) $(CFLAGS) -o $(ODIR)/experiments.o experiments.c

$(ODIR)/data.o: data.c kernel.h core.h render.h clipping.h experiments.h | $(ODIR)
	$(CC) $(CFLAGS) -o $(ODIR)/data.o data.c

# Kernel section
#
$(ODIR)/kernel.o: kernel.asm globals.inc | $(ODIR)
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o $(ODIR)/kernel.o kernel.asm

$(ODIR)/render.o: render.asm globals.inc | $(ODIR)
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o $(ODIR)/render.o render.asm

$(ODIR)/clipping.o: clipping.asm globals.inc | $(ODIR)
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o $(ODIR)/clipping.o clipping.asm

$(ODIR)/maths.o: maths.asm globals.inc | $(ODIR)
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o $(ODIR)/maths.o maths.asm

$(ODIR)/render_3D.o: render_3D.asm globals.inc | $(ODIR)
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o $(ODIR)/render_3D.o render_3D.asm

$(ODIR)/sprites.o: sprites.asm globals.inc | $(ODIR)
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o $(ODIR)/sprites.o sprites.asm

$(ODIR)/irq.o: irq.asm globals.inc | $(ODIR)
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_IRQ --constsegPAGE_02_KERNEL_IRQ -o $(ODIR)/irq.o irq.asm

install: next-3D.nex
	$(CP) *.nex $(DD)

clean:
	$(RM) $(ODIR)/*.*
	$(RM) *.o 
	$(RM) *.lis
	$(RM) *.bin
	$(RM) *.map
#	$(RM) *.nex


