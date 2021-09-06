[bits 16]
[org 0x0000]


start:
  mov ax, 0x2000
  mov ds, ax
  mov es, ax

  mov ax, 0x1f00
  mov ss, ax
  xor sp, sp

  mov ax, 0xb800
  mov es, ax
  mov cx, 25
  xor di, di
  xor dx, dx

print_color:
  mov byte [es:di], '#'
  mov ax, dx
  mov byte [es:di+1], al

  push dx
  mov dx, 10
  div dl
  add al, 48
  add ah, 48
  mov byte[es:di+2], 0
  mov byte[es:di+4], al
  mov byte[es:di+5], 0x13
  mov byte[es:di+6], ah
  mov byte[es:di+7], 0x13
  mov byte[es:di+8], 0
  pop dx

  inc dx
  add di, 0xa0

  ; kbd input
  ;xor ax, ax
  ;int 0x16

  loop print_color

  cli
  lgdt [GDT_addr]
  mov eax, cr0
  or eax, 1
  mov cr0, eax

  ; far jmp
  ; 0x8 is segment selector **for GDT**
  ; SELECTOR = | index[15:3] | TI | RPL[1:0] |
  ; so 0x08 = 0b0000_0000_0000_1000
  ; index == 1
  ; TI = 0 -> GDT (not LDT)
  ; RPL = 0 -> highest privilege
  jmp dword 0x8:(0x20000+start32)

start32:
  [bits 32]
  mov ax, 0x10
  mov ds, ax
  mov es, ax
  mov ss, ax
  lea eax, [0xb8000]
  mov dword [eax], 0x41414141

  mov ecx, 4000 ; 80x25 -> 80 * 2 * 25
  xor edi, edi
wr_vga:
  mov dword [eax + edi], 0x13411341
  add edi, 4
  loop wr_vga

jmp $

GDT_addr:
  dw (GDT_end - GDT) - 1
  dd 0x20000 + GDT ; GDT_ADDR

; Global Descriptor Table
align 32
GDT:
  ; 1st segment must be null
  dd 0, 0

  ; Code segment
  dd 0x0000ffff
  dd (10 << 8) | (1 << 12) | (1 << 15) | (0xf << 16) | (1 << 22) | (1 << 23)

  ; Data segment
  dd 0x0000ffff
  dd (2 << 8) | (1 << 12) | (1 << 15) | (0xf << 16) | (1 << 22) | (1 << 23)

  ; null segment
  ;dd 0, 0
GDT_end:
