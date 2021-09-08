.PHONY: all
all: fdd.img

boot: boot.s tools/mbr
	nasm boot.s

boot-mbr: boot
	cp boot boot-mbr
	./tools/mbr boot-mbr

stage2: stage2.s
	nasm stage2.s
	./tools/pad.py stage2

fdd.img: boot stage2 kernel
	cat boot > fdd.img
	cat stage2 >> fdd.img
	cat stage2 > stage2+kernel
	./tools/pad.py kernel
	cat kernel >> fdd.img
	cat kernel >> stage2+kernel
	ls -l boot stage2 kernel
	ls -l boot stage2 kernel | awk '{sum += $$5} END {print "\x1b[38;5;4mtotal sectors " sum/512 "\x1b[0m"}'

big-fdd: boot stage2 kernel boot-mbr
	cat boot-mbr > fdd.img
	dd if=/dev/zero of=fdd.img oseek=1 bs=512 count=$$((2048))
	cat stage2 >> fdd.img
	cat kernel >> fdd.img
	./tools/mbr

clean:
	- rm fdd.img boot stage2
	- rm ./tools/gdt
	- rm ./tools/mbr
	- rm ./var/bochs.log
	- rm kernel
	- rm stage2+kernel
	- rm boot-mbr
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

.PHONY: usb-boot
usb-boot: boot-mbr
	- sudo diskutil unmount /Volumes/UNTITLED
	sudo dd if=boot-mbr of=$(OUTDEV) bs=512 count=1 conv=sync

.PHONY: usb-kernel
usb-kernel: fdd.img
	- sudo diskutil unmount /Volumes/UNTITLED
	sudo dd if=stage2+kernel of=$(OUTDEV) bs=512 conv=sync oseek=$$((2048*2))

.PHONY: usb
usb: usb-boot usb-kernel
