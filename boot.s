[bits 16]
[org 0x7c00]

; 1 MB = 0x100_000
; addr = segment * 0x10 + offset

_s:
jmp start
nop

start:
  jmp word 0x0000:cs_reload
cs_reload:

  ; show A on screen
  mov ax, 0xb800
  mov es, ax
  mov word [es:0], 0x4141

  xor ax, ax
  mov ds, ax

  ; if bootable MBR entry is present
  ; try to load data from the usb flash
  ; this doesn't work yet though
  cmp byte [_s+0x1be], 0x80
  je .load_mbr

  mov ax, 0x2000
  mov es, ax

  ; load stage2 into 0x2000
  ;   AH = 02h
  ;   AL = number of sectors to read (must be nonzero)
  ;   CH = low eight bits of cylinder number
  ;   CL = sector number 1-63 (bits 0-5)
  ;   high two bits of cylinder (bits 6-7, hard disk only)
  ;   DH = head number
  ;   DL = drive number (bit 7 set for hard disk) [already set by BIOS]
  ;   ES:BX -> data buffer addr
  xor bx, bx
  mov ah, 2
  mov al, 62 ; * 512 B
  xor ch, ch
  mov cl, 2 ; sector 2 (this is boot sector, the next is stage 2)
  xor dh, dh
  int 0x13

  jmp word 0x2000:0x0000

.load_mbr:
  mov ax, 0xb800
  mov es, ax
  mov byte [es:0], 'M'
  mov byte [es:2], 'B'
  mov byte [es:4], 'R'

  xor ax, ax
  int 0x16

  mov ax, 0x2000
  mov es, ax

  ; DS:SI -> pointer to DAP
  mov ax, 0x7c00
  mov ds, ax

  mov si, (DAP - $$)
  mov ah, 0x42
  int 0x13

  ; CF = 1 if loading data failed
  jc fail
  jmp word 0x2000:0x0000

fail:
  mov ax, 0xb800
  mov es, ax
  mov byte [es:0], 'F'
  mov byte [es:2], 'A'
  mov byte [es:4], 'I'
  mov byte [es:6], 'L'
  mov byte [es:8], ' '
  mov byte [es:0x10], ' '

  ; print error code
  movzx ax, ah
  mov dl, 100
  div dl
  add al, '0'
  mov byte [es:10], al
  mov dl, 10
  movzx ax, ah
  div dl
  add al, '0'
  add ah, '0'
  mov byte [es:12], al
  mov byte [es:14], ah

  jmp $

; Disk Address Packet
DAP:
  db 0x10 ; size of packet
  db 0 ; rsvd
  dw 62 ; sectors to read
  dw 0x0000 ; target offset
  dw 0x2000 ; target segment
  dd 2048 ; starting LBA
  dd 0

%if ($ - DAP) != 0x10
  %fatal "DAP: bad size"
%endif

end:
%if ($ - $$) > 510
  %fatal "Bootloader exceeds 512 B."
%endif

times 510 - ($ - $$) db 0
db 0x55, 0xaa
