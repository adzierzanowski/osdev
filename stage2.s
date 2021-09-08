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
  mov byte [es:di+2], 0
  mov byte [es:di+4], al
  mov byte [es:di+5], 0x13
  mov byte [es:di+6], ah
  mov byte [es:di+7], 0x13
  mov byte [es:di+8], 0
  pop dx

  inc dx
  add di, 0xa0

  loop print_color

  mov cx, (msg1_end - msg1)
  mov di, 10
  xor si, si
print_msg1:
  mov ax, [msg1+si]
  mov ah, 0xf
  mov word [es:di], ax
  add di, 2
  inc si
  loop print_msg1

  ; kbd input
  xor ax, ax
  int 0x16

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
  mov ax, 0x10 ; gdt idx = 2
  mov ds, ax
  mov es, ax
  mov ss, ax

  ; some graphics
  lea eax, [0xb8000]
  mov ecx, 4000 ; 80x25 -> 80 * 2 * 25
  xor edi, edi
  xor edx, edx
fill_blue:
  mov dword [eax + edi], 0x0a001a00
  add edi, 4
  loop fill_blue

  mov ecx, (msg2_end - msg2)
  xor esi, esi
  xor edi, edi
print_msg2:
  mov dl, byte [msg2 + 0x20000 + esi]
  mov byte [eax + edi], dl
  add edi, 2
  inc esi
  loop print_msg2

  ; little delay
  mov ecx, 0x5000000
  loop $

  ; as for now, I don't know how to fetch keypress in the 32-bit mode
  ; so just print X and go immediately to 64-bit mode
  mov byte [eax+160], 'X'

goto64:
  ; load paging table into CR3
  mov eax, (PML4 - $$) + 0x20000
  mov cr3, eax

  ; Enable PAE (required for entering long mode)
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; Enable long mode
  mov ecx, 0xc0000080 ; set EFER MSR
  rdmsr ; read from the model-specific register
  or eax, 1 << 8 ; set IA-32e enable bit
  wrmsr

  ; Enable paging
  mov eax, cr0
  or eax, 1 << 31
  mov cr0, eax

  lgdt [GDT64_addr + 0x20000]
  jmp dword 0x8:(0x20000 + start64)

start64:
  [bits 64]
  mov ax, 0x10
  mov es, ax
  mov ss, ax
  mov ds, ax

  mov r8, 0x41
  cmp rax, r8
  je $

  mov rax, 0xb8000
  xor rdi, rdi

  ; again, show some graphics indicating 64-bit mode
  mov rcx, 4000
gfx64:
  mov byte [rax+rdi], 0x41
  inc edi
  loop gfx64

  ; ELF loader
  ;0x20 	4 	8 	e_phoff
  ; Points to the start of the program header table.
  ; It usually follows the file header immediately, making the offset 0x34
  ; or 0x40 for 32- and 64-bit ELF executables, respectively.
load_elf64:
  mov rsi, [0x20000 + kernel + 0x20] ; load offset
  add rsi, 0x20000 + kernel  ; add kernel position to offset

  ; 0x38 e_phnum (number of entries in the header table)
  movzx ecx, word [0x20000 + kernel + 0x38]
  cld ; clear direction flag (for movsb)
.ph_loop:
  mov eax, [rsi + 0]
  cmp eax, 1 ; is it loadable segment? (PT_LOAD)
  jne .next

; 0x20147
  mov r8, [rsi + 0x8] ; p_offset offset of the segment
  mov r9, [rsi + 0x10] ; p_vaddr
  mov r10, [rsi + 0x20] ; p_filesz

  ; could be push, but registers are faster
  mov rbp, rsi
  mov r15, rcx

  ; load segment to vaddr
  lea rsi, [0x20000 + kernel + r8d]
  mov rdi, r9
  mov rcx, r10
  rep movsb

  mov rcx, r15
  mov rsi, rbp

.next:
  add rsi, 0x38 ; next header
  loop .ph_loop

  ; Indicate success by writing "64" to the GPU text buffer
  mov rax, 0xb8000
  mov byte [rax], 0x36
  mov byte [rax+1], 0xf
  mov byte [rax+2], 0x34
  mov byte [rax+3], 0xf
  mov byte [rax+4], 0
  mov byte [rax+5], 0xf

jmp $

GDT_addr:
  dw (GDT_end - GDT) - 1
  dd 0x20000 + GDT ; GDT_ADDR

; 32-bit Global Descriptor Table
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
  dd 0, 0
GDT_end:


; 64-bit Global Descriptor Table
GDT64_addr:
  dw (GDT64_end - GDT64) - 1
  dd 0x20000 + GDT64

align 32
GDT64:
  ; 1st segment must be null
  dd 0, 0

  ; Code segment
  dd 0x0000ffff
  dd (10 << 8) | (1 << 12) | (1 << 15) | (0xf << 16) | (1 << 21) | (1 << 23)

  ; Data segment
  dd 0x0000ffff
  dd (2 << 8) | (1 << 12) | (1 << 15) | (0xf << 16) | (1 << 21) | (1 << 23)

  ; null segment
  dd 0, 0
GDT64_end:

align 1024*4
; IA-32e Paging
PML4:
  ; Exists  R/W
  dq    1 | (1 << 1) | (PDPT - $$ + 0x20000)
  times 511 dq 0

; Level 3 table
PDPT:
  dq 1 | (1 << 1) | (PDT - $$ + 0x20000)
  times 511 dq 0

; Level 2 table
PDT:
%assign i 0
%rep 512
  dq 0x200000*i+0x83
%assign i i+1
%endrep

msg1:
  db 'Press any key to jump into 32-bit mode'
msg1_end:

msg2:
  db 'Welcome to 32-bit mode'
msg2_end:

align 512
kernel:
