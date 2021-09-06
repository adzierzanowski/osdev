[bits 16]
[org 0x7c00]

; 1 MB = 0x100_000
; addr = segment * 0x10 + offset

jmp start
nop

start:
  ; load stage2 into 0x2000
  ;   AH = 02h
  ;   AL = number of sectors to read (must be nonzero)
  ;   CH = low eight bits of cylinder number
  ;   CL = sector number 1-63 (bits 0-5)
  ;   high two bits of cylinder (bits 6-7, hard disk only)
  ;   DH = head number
  ;   DL = drive number (bit 7 set for hard disk) [already set by BIOS]
  ;   ES:BX -> data buffer addr
  mov ax, 0x2000
  mov es, ax
  xor bx, bx

  mov ah, 2
  mov al, 19 ; * 512 B
  xor ch, ch
  mov cl, 2 ; sector 2 (this is boot sector, the next is stage 2)
  xor dh, dh
  int 0x13

  jmp word 0x2000:0x0000

end:
%if ($ - $$) > 510
  %fatal "Bootloader exceeds 512 B."
%endif

times 510 - ($ - $$) db 0
db 0x55, 0xaa
