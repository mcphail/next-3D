IDIR=../include
CC=zcc
CFLAGS=+zxn -vn -c -SO3 --list --c-code-in-asm --opt-code-speed -clib=sdcc_iy -pragma-include:zpragma.inc --max-allocs-per-node300000
ODIR=../../obj
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
	main.o \
	$(ODIR)/kernel.o \
	$(ODIR)/irq.o \
	$(ODIR)/data.o \
	$(ODIR)/render.o \
	$(ODIR)/clipping.o \
	$(ODIR)/maths.o \
	${ODIR}/maths_3D.o \
	$(ODIR)/experiments.o \
	$(ODIR)/render_3D.o \
	$(ODIR)/sprites.o

cube.nex: $(OBJS) 
	$(CC) +zxn -vn -m --list --c-code-in-asm -clib=sdcc_iy -Cz"--clean" -pragma-include:zpragma.inc -startup=1 --math32 $(OBJS) -o cube.nex -create-app -subtype=nex

# Main program at $8000
#
obj/main.o: main.c main.h 
	$(CC) $(CFLAGS) -o main.o main.c

install: cube.nex
	$(CP) *.nex $(DD)

clean:
	$(RM) *.o 
	$(RM) *.lis
	$(RM) *.bin
	$(RM) *.map
#	$(RM) *.nex


