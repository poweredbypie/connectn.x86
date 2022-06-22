.model flat

.code
; strips spaces in the front of a string.
; PARAMS:
; eax - input string
; RETURN:
; eax - the same pointer but shifted lol
str_strip proc
    mov cl, [eax]
    cmp cl, 020h
    jne finish

    inc eax
    jmp str_strip

finish:
    ret
str_strip endp

; PARAMS:
; eax - input string
; RETURN:
; eax - the input pointer shifted past the parsed int
; ecx - output int (0FFFFFFFFh if invalid)
str_to_int proc
    call str_strip

    ; dl  - *str
    ; bl - invalid
    ; bh - empty
    ; ecx - output
    push ebx
    xor bx, bx
    xor ecx, ecx
    xor edx, edx

    ; if the string is empty, we leave as 0
    mov dl, [eax]
    test dl, dl
    setz bh
    jz validate

parse:
    mov dl, [eax]
    test dl, dl
    je validate

    cmp dl, ' '
    je validate

    inc eax

    ; if it's invalid, we don't want to keep parsing
    ; we only want to keep going until next space or null
    test bl, bl
    jnz parse

    cmp dl, '0'
    setb bl
    jb parse

    cmp dl, '9'
    seta bl
    ja parse

    sub dl, '0'

    imul ecx, 10
    add ecx, edx

    jmp parse

validate:
    test bx, bx
    jz finish

    test bh, bh
    jnz empty

; invalid:
    mov ecx, 0
    jmp finish

empty:
    mov ecx, 0FFFFFFFFh

finish:
    pop ebx
    ret
str_to_int endp

end