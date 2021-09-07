.PHONY: all
all: fdd.img

boot: boot.s tools/mbr
	nasm boot.s
	./tools/mbr boot

stage2: stage2.s
	nasm stage2.s
	./tools/pad.py stage2

fdd.img: boot stage2 kernel
	cat boot > fdd.img
	cat stage2 >> fdd.img
	./tools/pad.py kernel
	cat kernel >> fdd.img
	ls -l boot stage2 kernel
	ls -l boot stage2 kernel | awk '{sum += $$5} END {print "\x1b[38;5;4mtotal sectors " sum/512 "\x1b[0m"}'

clean:
	- rm fdd.img boot stage2
	- rm ./tools/gdt
	- rm ./tools/mbr
	- rm ./var/bochs.log
	- rm kernel
	- yes y | docker system prune

run: fdd.img
	rlwrap bochs -qf etc/osdev.bochsrc

.PHONY: tools
tools: tools/gdt tools/mbr

tools/gdt: tools/gdt.c
	$(CC) tools/gdt.c -o tools/gdt

tools/mbr: tools/mbr.c
	$(CC) tools/mbr.c -o tools/mbr

kernel: kernel.c
	yes y | docker system prune
	docker build -t kernel .
	docker create -it --name kernel kernel
	docker start -i kernel
	docker cp kernel:kernel .
