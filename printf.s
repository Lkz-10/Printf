; nasm -f elf64 -l aaa.lst aaa.s
; ld -s -o aaa aaa.o
; ./aaa

section .text

global _start

_start:

    mov rsi, String             ; string to print
    mov rdi, buffer
    push 'E'                    ;
    push 'Z'                    ; arguments for %c

Symbol:
    cmp byte [rsi], '$'         ; terminal symbol
    je Finish

    cmp byte [rsi], '%'
    je Prcnt_handler

    mov rcx, 1                  ;
    movsb                       ; a byte from rsi (string) to rdi (buffer)

    jmp Symbol

Prcnt_handler: ; DESTROYING RAX, RCX
    inc rsi                     ; to identifier
    xor rax, rax                ;
    mov al, [rsi]               ;
    shl rax, 3                  ;
    add rax, JumpTable          ;
    jmp [rax]                   ; jumping to [JumpTable + ASCII * 8]

prcnt_b:
prcnt_c: ; DESTROYING RAX
    pop rax                     ; getting the argument

    mov [rdi], al               ; putting it in buffer
    inc rdi
    inc rsi

    jmp Symbol                  ; consider next symbol

prcnt_d:
prcnt_o:
prcnt_s:
prcnt_x:
prcnt_prcnt:
synterr:                        ; display syntax error message and exit
    mov rax, 0x01
    mov rdi, 1
    mov rsi, ErrorMsg
    mov rdx, ErrMsgLen
    syscall

    mov rax, 0x3c
    xor rdi, rdi
    syscall

Finish:                         ; display buffer and exit

    mov rax, 0x01
    mov rdi, 1
    mov rsi, buffer
    mov rdx, buf_len
    syscall

    mov rax, 0x3c
    xor rdi, rdi
    syscall

;======================================Jump Table=====================================

section .rodata

; ASCII codes:
    ; '%' = 37
    ; 'b' = 98
    ; 'c' = 99
    ; 'd' = 100
    ; 'o' = 111
    ; 's' = 115
    ; 'x' = 120

JumpTable:
  dq 37 dup  (synterr)
  dq prcnt_prcnt
  dq 60 dup  (synterr)
  dq prcnt_b
  dq prcnt_c
  dq prcnt_d
  dq 10 dup  (synterr)
  dq prcnt_o
  dq 3 dup   (synterr)
  dq prcnt_s
  dq 4 dup   (synterr)
  dq prcnt_x
  dq 135 dup (synterr)

;======================================DATA=========================================

section .data

buffer    dq 64 dup (0)
buf_len   equ $ - buffer
ErrorMsg  db "Syntax Error!", 0x0a, "$"
ErrMsgLen equ $ - ErrorMsg
DbgMsg    db "BUGBUGBUGBUGBUGBUG", 0x0a
DbgMsgLen equ $ - DbgMsg
String    dq "The char is... %c%c", 0x0a, "$"

;     push rsi
;     push rdi
;     push rdx
;     push rax
;
;     mov rax, 0x01
;     mov rdi, 1
;     mov rsi, DbgMsg
;     mov rdx, DbgMsgLen
;     syscall
;
;     pop rax
;     pop rdx
;     pop rdi
;     pop rsi
