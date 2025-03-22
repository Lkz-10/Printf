; nasm -f elf64 -l aaa.lst aaa.s
; ld -s -o aaa aaa.o
; ./aaa

section .text

global _start

_start:

    mov rsi, String             ; format string
    mov rdi, Buffer

; arguments:
    mov rax, BufEnd
    sub rax, Buffer
    push rax
    push 1000
    push 1000
    push 1000
    push 1000
    push 'T'
    push 'I'
    push 'N'
    push 'E'
    push 'Z'
    push 100
    push 100

Symbol:
    cmp byte [rsi], '$'         ; terminal symbol
    jne NotEnd
    call PrintBuffer
    jmp Finish

NotEnd:
    cmp byte [rsi], '%'
    je Prcnt_handler

    cmp rdi, BufEnd             ;
    jne ContinueSymbol          ; printing buffer if it is full
    call PrintBuffer

ContinueSymbol:
    mov rcx, 1                  ;
    movsb                       ; a byte from rsi (string) to rdi (Buffer)

    jmp Symbol

;=====================================================================================
Prcnt_handler: ; DESTROYS RAX

    inc rsi                     ; to identifier
    xor rax, rax                ;
    mov al, [rsi]               ;
    shl rax, 3                  ;
    add rax, JumpTable          ;
    jmp [rax]                   ; jumping to [JumpTable + ASCII * 8]

;========================================%c===========================================
prcnt_c: ; DESTROYS RAX

    cmp rdi, BufEnd             ;
    jne ContinuePrcntC          ; if (rdi == BufEnd) PrintBuffer();
    call PrintBuffer            ;

ContinuePrcntC:
    pop rax                     ; getting the argument
    mov [rdi], al               ; putting it in buffer
    inc rdi
    inc rsi

    jmp Symbol                  ; consider next symbol

;========================================%b===========================================
prcnt_b:
    mov rcx, 2                  ; bin system index
    jmp NumberHandler

;========================================%o===========================================
prcnt_o:
    mov rcx, 8                  ; oct system index
    jmp NumberHandler

;========================================%d===========================================
prcnt_d:
    mov rcx, 10                 ; dec system index
    jmp NumberHandler

;========================================%x===========================================
prcnt_x:
    mov rcx, 16                 ; hex system index
    jmp NumberHandler

;===============================Universal Number Hadler===============================
NumberHandler: ; DESTROYS RAX, RDX. ENTRY: INDEX OF THE NUMBER SYSTEM IN RCX

    pop rax                     ; getting the number
    push rsi                    ; saving rsi
    mov rsi, NumBuffer          ; buffer for the number

GetDigit:                       ; while (rax > 0)
    cmp rax, 0                  ; {
    je PutDigit                 ;   NumBuffer[rsi - NumBuffer] = rax % 10;
                                ;   rax /= 10;
    xor rdx, rdx                ;   rsi++;
    div rcx                     ; }
    mov [rsi], dl               ;
    inc rsi                     ;
    jmp GetDigit                ;

PutDigit:

    cmp rsi, NumBuffer          ; while (rsi > NumBuffer)
    je NumHandlerEnd            ; {

    cmp rdi, BufEnd             ;
    jne ContinueNumber          ; if (rdi == BufEnd) PrintBuffer();
    call PrintBuffer            ;

ContinueNumber:                 ;
    dec rsi                     ;   rsi--;
    add byte [rsi], '0'         ;   NumBuffer[rsi - NumBuffer] += '0';

    cmp byte [rsi], '9'         ;   if (NumBuffer[rsi - NumBuffer] <= '9')
    jbe NotHex                  ;   { // skip symbols between '9' and 'A' in ASCII table:
    add byte [rsi], 'A'         ;       NumBuffer[rsi - NumBuffer] += 'A' - 1 - '9';
    dec byte [rsi]              ;   }
    sub byte [rsi], '9'         ;

NotHex:                         ;
    movsb                       ;   Buffer[rdi - Buffer] = NumBuffer[rsi - NumBuffer];
    dec rsi                     ;   rdi++;
    jmp PutDigit                ; }

NumHandlerEnd:
    pop rsi
    inc rsi
    jmp Symbol                  ; considering next symbol

;========================================%s===========================================
prcnt_s:

;========================================%%===========================================
prcnt_prcnt:
    mov byte [rdi], '%'         ; putting '%' in buffer
    inc rsi
    inc rdi
    jmp Symbol                  ; consider next symbol

;====================================SyntaxError======================================
synterr:                        ; print syntax error message and exit
    mov rax, 0x01
    mov rdi, 1
    mov rsi, ErrorMsg
    mov rdx, ErrMsgLen
    syscall

    mov rax, 0x3c
    xor rdi, rdi
    syscall

;=====================================================================================
PrintBuffer: ; DESTROYS RAX, RDX
    push rsi

    mov rax, 0x01
    mov rdx, rdi
    sub rdx, Buffer
    mov rdi, 1
    mov rsi, Buffer
    syscall

    mov rdi, Buffer
    pop rsi

    ret
;=====================================================================================
Finish:                         ; exit

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

Buffer      dq  1 dup (0)
BufEnd      equ $
ErrorMsg    db  "Syntax Error!", 0x0a, "$"
ErrMsgLen   equ $ - ErrorMsg
DbgMsg      db  "BUGBUGBUGBUGBUGBUG", 0x0a
NumBuffer   dq  32 dup (0)
DbgMsgLen   equ $ - DbgMsg
String      dq "Probability is ... %d%% of %d%%", 0x0a, "The winner  is ... %c%c%c%c%c!", 0x0a
            dq "Dec - %d, Hex - %x, Oct - %o, Bin - %b", 0x0a, "Actually, the buffer length is %d!", 0x0a, "$"

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
