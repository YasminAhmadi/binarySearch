%ifndef SYS_EQUAL
%define SYS_EQUAL
    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
   
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
     

    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
   
     
    sys_exit     equ     60
   
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
 
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
   
    ;access mode
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000

   
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20

%endif
;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:

   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret
;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, byte [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------
readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
   
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx
   cmp    bl, 0
   je     sEnd
   neg    rax
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret
;-------------------------------------------
printString:
    push    rax
    push    rcx
    push    rsi
    push    rdx
    push    rdi

    mov     rdi, rsi
    call    GetStrlen
    mov     rax, sys_write  
    mov     rdi, stdout
    syscall
   
    pop     rdi
    pop     rdx
    pop     rsi
    pop     rcx
    pop     rax
    ret
;-------------------------------------------
; rsi : zero terminated string start
GetStrlen:
    push    rbx
    push    rcx
    push    rax  

    xor     rcx, rcx
    not     rcx
    xor     rax, rax
    cld
    repne   scasb
    not     rcx
    lea     rdx, [rcx -1]  ; length in rdx

    pop     rax
    pop     rcx
    pop     rbx
    ret
;-------------------------------------------

section .data
    nan db "NaN"

section .bss
    arr resq 10000000
    len: resb 4

section .text
global _start
   
_start:

_get_input:
        call readNum
        ; The first number is stored in rax
        mov [len], rax
        ; storing the first number in r9
        mov r8,[len]
        mov rax, [len]
        ;r9 is the counter of input_loop
        xor r9, r9
        ;get input array
        mov r10, arr
        input_loop:
            call readNum
            mov [r10 + r9*8], rax
            xor rax, rax
            mov rax, [r10 + r9*8]
            inc r9
            cmp r8,r9
            jne input_loop
        ;get the number we're searching for and store it in r9
        call readNum

       
pre_process:
    mov r8, 0   ; first of the start index
    mov r9, [len] ; last of the array index
    mov r11, rax ;number to find
    mov r12, arr ;set the arrat
    push r12 ;array
    push r11 ;key
    push r8 ;low
    push r9 ;high
    call binary_search
    ; check if its NO
    mov rax, r15
    cmp rax, -1
    jne contCheck
    mov rsi, nan
    call printString
    call newLine
    jmp exit
contCheck:
    mov r8, r15
    dec r8
    mov rax, [arr + r15 * 8]
    cmp rax, [arr + r8 * 8]
    jne final_print
    dec r15
    jmp contCheck
final_print:
    mov rax, r15
    call writeNum
    call newLine

exit:
    mov rax,1 ;system call number (sys_exit)
    mov rbx,0
    int 0x80 ;call kernel

; create funcitons for searching upper and lower bound
search_upper:
    push qword [rbp + 40] ; 1- save the arr pointer(the old one) -- array
    push qword [rbp + 32] ; 2- save the number to find(the old one) -- key
    mov rax, [rbp - 8]    ; get the middle to save as first of array -- mid value
    inc rax               ; increase it by one because we have check it already
    push qword rax        ; 3- save the index first of array(updated) -- new low
    push qword [rbp + 16] ; 4- save the index last of array(the old one) -- old/new high
    call binary_search    ; call the binary search again
    ; leave
    mov rsp, rbp
    pop rbp
    ret  32
search_lower:
    push qword [rbp + 40] ; 1- save the arr pointer(the old one)
    push qword [rbp + 32] ; 2- save the number to find(the old one)
    push qword [rbp + 24] ; 3- save the index first of array(the old one)
    mov rax, [rbp - 8]    ; get the middle to use as index last of array
    dec rax               ; dec because it has already been checked
    push qword rax        ; 4- save the index last of array(the old one)
    call binary_search    ; call the binary search
    ; leave
    mov rsp, rbp
    pop rbp
    ret  32
; create a funciton for found or not found
founded:
    mov r15,rax ; mov the answer (mid index) to r15
    ;leave
    mov rsp, rbp
    pop rbp
    ret  32
not_found:
    mov r15, -1 ; if not found, move -1 to r15
    ; leave
    mov rsp, rbp
    pop rbp
    ret  32

; create a function for binary search
binary_search:
    ;storing 64 bits for mid on top of the parameters
    ; use stack for the recursive code
    push rbp        ; Enter 8, 0
    mov rbp, rsp    ; Enter 8, 0
    sub rsp, 8      ; Enter 8, 0
    jmp find_mid

find_mid:
    ; get the variables from the stack
    mov r8, [rbp + 16] ; last of array
    mov r9, [rbp + 24] ; first of array
    cmp r8, r9 ; check if the array is ended
    jl not_found ; jump to not found
    mov rax, r8 ; mid = l + (r - l) // 2
    sub rax, r9 ; mid = l + (r - l) // 2
    mov r13, 2  ; mid = l + (r - l) // 2
    xor rdx, rdx; mid = l + (r - l) // 2
    div r13     ; mid = l + (r - l) // 2
    add rax, r9 ; mid = l + (r - l) // 2
    ;mid index is stored in rax
    jmp compare_with_list

compare_with_list:
    mov [rbp - 8], rax  ; save the  middle index
    ;storing the mid value in r14
    mov r14, qword [r12 + rax * 8] ; compare the middle with the value we want
    cmp r14, r11 ;r11 is the key and r14 is mid value
    je founded
    jg search_lower
    jl search_upper