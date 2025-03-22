; nasm -f elf64 -l aaa.lst aaa.s
; ld -s -o aaa aaa.o
; ./aaa

section .text

global _start

_start:

    mov rsi, String             ; string to print
    mov rdi, Buffer
    push 100
    push 'T'
    push 'I'
    push 'N'
    push 'E'                    ;
    push 'Z'                    ; arguments for %c

Symbol:
    cmp byte [rsi], '$'         ; terminal symbol
    je Finish

    cmp byte [rsi], '%'
    je Prcnt_handler

    mov rcx, 1                  ;
    movsb                       ; a byte from rsi (string) to rdi (Buffer)

    jmp Symbol

Prcnt_handler: ; DESTROYING RAX
    inc rsi                     ; to identifier
    xor rax, rax                ;
    mov al, [rsi]               ;
    shl rax, 3                  ;
    add rax, JumpTable          ;
    jmp [rax]                   ; jumping to [JumpTable + ASCII * 8]

prcnt_b:

;========================================%c===========================================
prcnt_c: ; DESTROYING RAX
    pop rax                     ; getting the argument
    mov [rdi], al               ; putting it in buffer
    inc rdi
    inc rsi

    jmp Symbol                  ; consider next symbol

;========================================%d===========================================
prcnt_d: ; DESTROYING RAX, RDX, RCX
    pop rax                     ; getting the number
    push rsi                    ; saving rsi
    mov rsi, NumBuffer          ; buffer for the number

GetDigit:                       ; while (rax > 0)
    cmp rax, 0                  ; {
    je PutDigit                 ;   NumBuffer[rsi - NumBuffer] = rax % 10;
                                ;   rax /= 10;
    xor rdx, rdx                ;   rsi++;
    mov rcx, 10                 ; }
    div rcx                     ;
    mov [rsi], dl               ;
    inc rsi                     ;
    jmp GetDigit                ;

PutDigit:                       ;
    cmp rsi, NumBuffer          ; while (rsi > NumBuffer)
    je PrcntDEnd                ; {
    dec rsi                     ;   rsi--;
    add byte [rsi], '0'         ;   NumBuffer[rsi - NumBuffer] += '0';
    movsb                       ;   Buffer[rdi - Buffer] = NumBuffer[rsi - NumBuffer];
    dec rsi                     ;   rdi++;
    jmp PutDigit                ; }

PrcntDEnd:
    pop rsi
    inc rsi
    jmp Symbol                  ; considering next symbol

;=====================================================================================

prcnt_o:
prcnt_s:
prcnt_x:

;========================================%%===========================================
prcnt_prcnt:
    mov byte [rdi], '%'         ; putting '%' in buffer
    inc rsi
    inc rdi
    jmp Symbol                  ; consider next symbol

;====================================SyntaxError======================================
synterr:                        ; display syntax error message and exit
    mov rax, 0x01
    mov rdi, 1
    mov rsi, ErrorMsg
    mov rdx, ErrMsgLen
    syscall

    mov rax, 0x3c
    xor rdi, rdi
    syscall

;=====================================================================================
Finish:                         ; display Buffer and exit

    mov rax, 0x01
    mov rdi, 1
    mov rsi, Buffer
    mov rdx, BufLen
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

Buffer    dq 64 dup (0)
BufLen    equ $ - Buffer
ErrorMsg  db "Syntax Error!", 0x0a, "$"
ErrMsgLen equ $ - ErrorMsg
DbgMsg    db "BUGBUGBUGBUGBUGBUG", 0x0a
NumBuffer dq 32 dup (0)
DbgMsgLen equ $ - DbgMsg
String    dq "The winner  is ... %c%c%c%c%c!", 0x0a, "Probability is ... %d%%", 0x0a, "$"

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
