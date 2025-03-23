section .note.GNU-stack noalloc noexec nowrite progbits ; for non-executable stack
section .text

global MyPrintf

MyPrintf:

    cld                         ; clear destination flag (for movsb to work properly)

    pop rax                     ;
    mov [RetAddr], rax          ; saving C return address

    push r9                     ;
    push r8                     ;
    push rcx                    ;
    push rdx                    ;
    push rsi                    ;
    push rdi                    ; moving parameters from registers to stack

    pop rsi                     ; format string address to rsi
    mov rdi, Buffer             ; buffer address to rdi

Symbol:
    cmp byte [rsi], 0           ; terminal symbol '\0', ASCII = 0
    jne NotEnd                  ;
    call PrintBuffer            ;
    jmp Finish                  ; Print buffer and exit if \0 is reached

NotEnd:
    cmp byte [rsi], '%'         ;
    je Prcnt_handler            ; go to Prcnt_handler if '%' reached

    cmp rdi, BufEnd             ;
    jne ContinueSymbol          ; printing buffer if it is full
    call PrintBuffer            ;

ContinueSymbol:
    movsb                       ; a byte from rsi (string) to rdi (Buffer)

    jmp Symbol                  ; consider next symbol of format string

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

    jmp Symbol                  ; consider next symbol of format string

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

    pop  rax                    ; getting the number into rax
    push rsi                    ; saving rsi
    mov  rsi, NumBuffer         ; buffer for the number

GetDigit:                       ;
    cmp rax, 0                  ; while (rax > 0)
    je PutDigit                 ; {
                                ;   NumBuffer[rsi - NumBuffer] = rax % 10;
    xor rdx, rdx                ;   rax /= 10;
    div rcx                     ;   rsi++;
    mov [rsi], dl               ; }
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
    jmp Symbol                  ; considering next symbol of format string

;========================================%s===========================================
prcnt_s: ; DESTROYS RAX, RCX, RDX

    pop rax                     ; getting the string
    push rsi                    ; saving rsi
    mov rsi, rax                ; rsi = rax (the string address)

    dec rax                     ;
SearchEOS:                      ; // EOS - End of string
    inc rax                     ; while (string[rax - string] != '\0') rax++;
    cmp byte [rax], 0           ; // Finally address of the end of the string in rax
    jne SearchEOS               ;

    sub rax, rsi                ; rax -= rsi; // the string length is in rax now
    mov rdx, BufEnd             ;
    sub rdx, rdi                ; rdx = BufEnd - rdi; // amount of buffer's free memory is in rdx now

    cmp rax, rdx                ;
    jbe StringToBuffer          ; if (rax <= rdx) StringToBuffer();

    call PrintBuffer

    cmp rax, BufEnd - Buffer    ; // BufEnd - Buffer equals the buffer capacity
    jae PrintString             ; if (rax >= BufEnd - Buffer) PrintString();

StringToBuffer:
    mov rcx, rax                ; rcx = rax; // length of the string
    rep movsb                   ; putting rcx symbols from string to bugger

PrcntSEnd:
    pop rsi                     ; restoring rsi
    inc rsi                     ;
    jmp Symbol                  ; considering next symbol of the format string

PrintString:
    push rdi                    ;
    push rax                    ; saving rdi, rax

    mov rdx, rax                ; rdx = rax (length of the string)
    mov rax, 0x01
    mov rdi, 1
    syscall

    pop rax                     ;
    pop rdi                     ; restoring rax, rdi
    jmp PrcntSEnd

;========================================%%===========================================
prcnt_prcnt:
    mov byte [rdi], '%'         ; putting '%' in buffer
    inc rsi
    inc rdi
    jmp Symbol                  ; consider next symbol of format string

;====================================SyntaxError======================================
synterr:                        ; print syntax error message and exit(1)
    mov rax, 0x01
    mov rdi, 1
    mov rsi, ErrorMsg
    mov rdx, ErrMsgLen
    syscall

    mov  rax, [RetAddr]
    push rax
    mov  rax, 1
    ret

;=====================================================================================
PrintBuffer:
    push rax                    ;
    push rsi                    ; saving rax, rsi, rdx
    push rdx                    ;

    mov rax, 0x01
    mov rdx, rdi                ;
    sub rdx, Buffer             ; rdx = rdi - Buffer (legth of filled part of buffer)
    mov rdi, 1
    mov rsi, Buffer
    syscall

    mov rdi, Buffer             ; rdi = Buffer (beginning of the buffer)
    pop rdx                     ;
    pop rsi                     ; restoring rdx, rsi, rax
    pop rax                     ;

    ret
;=====================================================================================
Finish:                         ; exit(0)

    mov  rax, [RetAddr]
    push rax
    xor  rax, rax
    ret

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

Buffer      dq  64 dup (0)
BufEnd      equ $
ErrorMsg    dq  "Syntax Error!", 0x0a
ErrMsgLen   equ $ - ErrorMsg
NumBuffer   dq  32 dup (0)
RetAddr     dq 0
