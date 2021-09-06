.PHONY: all
all: fdd.img

boot: boot.s tools/mbr
	nasm boot.s
	./tools/mbr boot

stage2: stage2.s
	nasm stage2.s
	./tools/pad.py stage2

fdd.img: boot stage2
	cat boot > fdd.img
	cat stage2 >> fdd.img

clean:
	- rm fdd.img boot stage2
	- rm ./tools/gdt
	- rm ./tools/mbr
	- rm ./var/bochs.log

run: fdd.img
	rlwrap bochs -qf etc/osdev.bochsrc

.PHONY: tools
tools: tools/gdt tools/mbr

tools/gdt: tools/gdt.c
	$(CC) tools/gdt.c -o tools/gdt

tools/mbr: tools/mbr.c
	$(CC) tools/mbr.c -o tools/mbr
