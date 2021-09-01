.PHONY: all
all: fdd.img

boot: boot.s
	nasm boot.s

stage2: stage2.s
	nasm stage2.s
	./tools/pad.py stage2

fdd.img: boot stage2
	cat boot > fdd.img
	cat stage2 >> fdd.img

clean:
	- rm fdd.img boot stage2
	- rm ./tools/gdt
	- rm ./var/bochs.log

run: fdd.img
	rlwrap bochs -qf etc/osdev.bochsrc

.PHONY: tools
tools: tools/gdt

tools/gdt: tools/gdt.c
	cc tools/gdt.c -o tools/gdt
