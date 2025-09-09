IDIR=../include
CC=zcc
CFLAGS=+zxn -vn -c -SO3 --list --c-code-in-asm --opt-code-speed -clib=sdcc_iy -pragma-include:zpragma.inc --max-allocs-per-node300000
ODIR=obj
LDIR=../lib
LIBS=-lm

OBJS = \
	obj/main.o \
	obj/kernel.o \
	obj/irq.o \
	obj/data.o \
	obj/render.o \
	obj/clipping.o \
	obj/maths.o \
	obj/experiments.o \
	obj/render_3D.o

next-3D.nex: $(OBJS) 
	$(CC) +zxn -vn -m --list --c-code-in-asm -clib=sdcc_iy -Cz"--clean" -pragma-include:zpragma.inc -startup=1 --math32 $(OBJS) -o next-3D.nex -create-app -subtype=nex

# Main program at $8000
#
obj/main.o: main.c main.h 
	$(CC) $(CFLAGS) -o obj/main.o main.c

# Comment in to compile the C portion of clipping (for debug/test purposes only)
#
# obj/clipping.o: clipping.c clipping.h 
#	$(CC) $(CFLAGS) -o obj/clipping.o clipping.c clipping.asm 

obj/experiments.o: experiments.c experiments.h 
	$(CC) $(CFLAGS) -o obj/experiments.o experiments.c

obj/data.o: data.c kernel.h core.h render.h clipping.h experiments.h
	$(CC) $(CFLAGS) -o obj/data.o data.c

# Kernel section
#
obj/kernel.o: kernel.asm globals.inc
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o obj/kernel.o kernel.asm

obj/render.o: render.asm globals.inc
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o obj/render.o render.asm

# Comment out when compiling the C portion of clipping (for debug/test purposes only)
#
obj/clipping.o: clipping.asm globals.inc
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o obj/clipping.o clipping.asm

obj/maths.o: maths.asm globals.inc
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o obj/maths.o maths.asm

obj/render_3D.o: render_3D.asm globals.inc
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_CODE --constsegPAGE_02_KERNEL_CODE -o obj/render_3D.o render_3D.asm

obj/irq.o: irq.asm globals.inc
	$(CC) $(CFLAGS) --codesegPAGE_02_KERNEL_IRQ --constsegPAGE_02_KERNEL_IRQ -o obj/irq.o irq.asm

clean:
	$(RM) obj/*.*
	$(RM) *.o 
	$(RM) *.lis
	$(RM) *.bin
	$(RM) *.map
#	$(RM) *.nex


