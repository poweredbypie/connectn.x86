.model flat

includelib kernel32
extern _CreateFileA@28: proc
extern _WriteFile@20: proc
extern _ReadFile@20: proc

.data
    stdout dword 0
    stdin dword 0

.code
io_init proc
    ; open stdout
    push 0
    push 80h ; FILE_ATTRIBUTE_NORMAL
    push 3 ; OPEN_EXISTING
    push 0
    push 0
    push 040000000h ; GENERIC_WRITE
    .data
        con byte "CON", 0
    .code
    lea eax, con
    push eax
    call _CreateFileA@28
    mov [stdout], eax
    push 0
    push 080h ; FILE_ATTRIBUTE_NORMAL
    push 3 ; OPEN_EXISTING
    push 0
    push 0
    push 080000000h ; GENERIC_READ
    lea eax, con
    push eax
    call _CreateFileA@28
    mov [stdin], eax
    ret
io_init endp

; PARAMS:
; eax - address of string
; ecx - length of string
out_print proc
    push 0 ; OVERLAPPED struct
    push 0 ; bytes written (who cares)
    push ecx
    push eax
    mov eax, [stdout]
    push eax
    call _WriteFile@20
    ret
out_print endp

; PARAMS:
; eax - an int
out_write_int proc
    ; make room for string to give to WriteFile
    sub esp, 16
    ; null terminate
    mov byte ptr [esp + 15], 0

    ; ecx = 10 - use in div
    mov ecx, 10
    ; ebx = iter
    push ebx
    mov ebx, 14

parse:
    ; clear edx
    xor edx, edx
    ; edx - mod (remainder)
    ; eax - quotient
    div ecx

    mov byte ptr [esp + ebx], dl
    add byte ptr [esp + ebx], '0'

    dec ebx

    test ax, ax
    jz finish

    jmp parse

finish:
    mov eax, esp
    add eax, ebx
    inc eax
    mov ecx, 14
    sub ecx, ebx
    call out_print

    pop ebx

    add esp, 16
    ret
out_write_int endp

; helper just to make things less verbose
out_write_newline proc
    .data
        newline byte 0Ah, 0Dh
    .code

    lea eax, newline
    mov ecx, lengthof newline
    call out_print
    ret
out_write_newline endp

; same as above, helper
out_write_space proc
    .data
        space byte " "
    .code

    lea eax, space
    mov ecx, lengthof space
    call out_print
    ret
out_write_space endp

; this is rly similar to str_to_int but i dont wanna deal with allocation in asm
; PARAMS:
; none
; RETURN:
; eax - output int (0FFFFFFFFh if failed)
in_read_int proc
    ; make space for char (but aligned is faster)
    sub esp, 4
    mov byte ptr [esp], 0

    ; esi - return int
    push esi
    xor esi, esi

    ; bl - invalid
    ; bh - at least 1 char read
    push ebx
    xor bx, bx

parse:
    mov eax, esp

    push 0
    push 0
    push 1 ; 1 byte lol
    push eax
    push stdin
    call _ReadFile@20

    ; well that's annoying, what a waste of speed
    xor eax, eax
    mov al, byte ptr [esp]

    ; finished reading line
    cmp al, 0Ah
    je validate

    ; if invalid, dont bother with the rest
    test bl, bl
    jnz parse

    ; ofc windows is weird and uses '\r' instead, ignore and get last char
    cmp al, 0Dh
    je parse

    cmp al, '0'
    setb bl
    jb parse

    cmp al, '9'
    seta bl
    ja parse

    sub al, '0'
    imul esi, 10
    add esi, eax
    mov bh, 1

    jmp parse

validate:
    ; bh - at least 1 char (1)
    ; bl - valid (0)
    cmp bx, 0100h
    ; kinda redundant but i dont rly wanna make more labels lol
    mov eax, esi
    je finish

    mov eax, 0FFFFFFFFh

finish:
    pop ebx
    pop esi
    add esp, 4
    ret
in_read_int endp

end