.model flat

includelib kernel32
extern _GetCommandLineA@0: proc
extern _ExitProcess@4: proc

; io.asm
extern out_print: proc

; str.asm
extern str_to_int: proc

.code

; PARAMS:
; eax - str
; ecx - len
print_usage proc
    call out_print

    .data
        help_string byte 0Dh, "Usage: [rows] [cols] [win]"
    .code
    lea eax, help_string
    mov ecx, lengthof help_string
    call out_print

    push 0
    call _ExitProcess@4
print_usage endp

; PARAMS:
; none
; RETURN:
; eax - rows
; ecx - cols
; edx - win
process_cmdline proc
    call _GetCommandLineA@0

    ; edi = count
    push edi
    mov edi, 0

    ; cmdline will contain procname, so we need to skip it
skip_procname:
    mov cl, [eax]
    inc eax

    ; if we reach the space, we can start parsing the rest
    cmp cl, ' '
    je parse

    ; if we reach the end, there are 0 args (too little)
    test cl, cl
    jz not_enough

    jmp skip_procname

parse:
    mov cl, [eax]
    ; exit when str is done
    test cl, cl
    jz check_count

    call str_to_int
    cmp ecx, 0FFFFFFFFh
    je skip

    inc edi
    push ecx

skip:
    jmp parse

check_count:
    cmp edi, 3
    je finish
    jb not_enough

; too_much:
    .data
        too_many byte "Too many arguments.", 0Ah
    .code
    lea eax, too_many
    mov ecx, lengthof too_many
    call print_usage

not_enough:
    .data
        too_few byte "Too few arguments.", 0Ah
    .code
    lea eax, too_few
    mov ecx, lengthof too_few
    call print_usage

finish:
    ; win
    pop edx
    ; cols
    pop ecx
    ; rows
    pop eax

    pop edi
    ret
process_cmdline endp

end