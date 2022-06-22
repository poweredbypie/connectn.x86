.model flat

includelib kernel32
extern _GetProcessHeap@0: proc
extern _HeapAlloc@12: proc
extern _HeapFree@12: proc
extern _ExitProcess@4: proc

; io.asm
extern out_print: proc
extern out_write_int: proc
extern out_write_newline: proc
extern out_write_space: proc
extern in_read_int: proc

include game.inc

.code
; PARAMS:
; eax - rows
; ecx - cols
; edx - win
; esp + 4 - pointer to game struct
game_init proc
    push esi

    assume esi: ptr Game
    mov esi, esp
    add esi, 8
    mov [esi].rows, eax
    mov [esi].cols, ecx
    mov [esi].win, edx
    mul ecx
    mov [esi].turns_left, eax
    mov [esi].player_two, 0

    ; allocate rows
    imul eax, [esi].rows, sizeof dword
    push eax
    push 8 ; zero memory
    call _GetProcessHeap@0
    push eax
    call _HeapAlloc@12

    mov [esi].arr, eax

    ; allocate cols
    ; ebx - i
    push ebx
    xor ebx, ebx

init_cols:
    cmp ebx, [esi].cols
    je finish

    push [esi].cols
    push 8
    call _GetProcessHeap@0
    push eax
    call _HeapAlloc@12
    mov ecx, [esi].arr
    mov [ecx + ebx * sizeof dword], eax

    push edi
    mov edi, eax
    mov al, '*'
    mov ecx, [esi].cols
    rep stosb
    pop edi

    inc ebx
    jmp init_cols

finish:
    pop ebx
    pop esi
    ret
game_init endp

; params:
; esp + 4 - pointer to game struct
game_deinit proc
    push esi

    assume esi: ptr Game
    mov esi, esp
    add esi, 8

    ; edi - heap (cached cuz its useful)
    push edi
    call _GetProcessHeap@0
    mov edi, eax

    ; ebx - i
    push ebx
    xor ebx, ebx

free_cols:
    cmp ebx, [esi].cols
    je finish

    mov eax, [esi].arr
    mov eax, [eax + ebx * sizeof dword]
    push eax
    push 0
    push edi
    call _HeapFree@12

    inc ebx
    jmp free_cols

finish:
    ; free 2d array
    push [esi].arr
    push 0
    push edi
    call _HeapFree@12

    pop ebx
    pop edi
    pop esi
    ret
game_deinit endp

; PARAMS:
; esi - Game*
game_print proc
    assume esi: ptr Game
    ; ebx - row
    push ebx
    xor ebx, ebx
    ; edi - col
    push edi

rows:
    xor edi, edi
    cmp ebx, [esi].rows
    je finish

    cols:
        cmp edi, [esi].cols
        je next

        ; [esi].arr[row] + col
        mov eax, [esi].arr
        mov eax, [eax + ebx * sizeof dword]
        add eax, edi
        mov ecx, 1
        call out_print
        call out_write_space

        inc edi
        jmp cols

next:
    call out_write_newline
    inc ebx
    jmp rows

finish:
    call out_write_newline
    pop edi
    pop ebx
    ret
game_print endp

; PARAMS:
; esi - Game*
; eax - col
; RETURN:
; ecx - first free row, or 0FFFFFFFFh if failed
game_valid_column proc
    assume esi: ptr Game
    ; ecx = iter
    mov ecx, [esi].rows

check:
    dec ecx
    cmp ecx, 0FFFFFFFFh
    je finish

    mov edx, [esi].arr
    mov edx, [edx + ecx * sizeof dword]
    mov dl, [edx + eax]
    cmp dl, '*'
    jne check

finish:
    ret
game_valid_column endp

; PARAMS
; cl - player_two
; RETURN
; cl - current player char
game_current_char proc
    test cl, cl
    jz p1

; p2:
    mov cl, 'O'
    ret

p1:
    mov cl, 'X'
    ret
game_current_char endp

; PARAMS:
; esi - Game*
; al - char to compare to
; ebx - row
; edi - col
; RETURN:
; cl - if successful
game_check_vertical proc
    assume esi: ptr Game
    push ebx

    ; ecx = chain length
    xor ecx, ecx

check:
    cmp ebx, [esi].rows
    je not_found

    mov edx, [esi].arr
    mov edx, [edx + ebx * sizeof dword]
    mov dl, [edx + edi]

    cmp dl, al
    je matching

    xor ecx, ecx
    jmp compare

matching:
    inc ecx

compare:
    cmp ecx, [esi].win
    jne next

    ; we found a match!
    mov cl, 1
    jmp finish

next:
    inc ebx
    jmp check

not_found:
    xor cl, cl
    
finish:
    pop ebx
    ret
game_check_vertical endp

; PARAMS:
; esi - Game*
; al - char to compare to
; ebx - row
; edi - col
; RETURN:
; cl - if successful
game_check_horizontal proc
    assume esi: ptr Game
    push edi

    ; we start from the beginning of the columns
    xor edi, edi

    ; ecx = chain length
    xor ecx, ecx

check:
    cmp edi, [esi].cols
    je not_found

    mov edx, [esi].arr
    mov edx, [edx + ebx * sizeof dword]
    mov dl, [edx + edi]

    cmp dl, al
    je matching

    xor ecx, ecx
    jmp compare

matching:
    inc ecx

compare:
    cmp ecx, [esi].win
    jne next

    ; we found a match!
    mov cl, 1
    jmp finish

next:
    inc edi
    jmp check

not_found:
    xor cl, cl
    
finish:
    pop edi
    ret
game_check_horizontal endp

; PARAMS:
; esi - Game*
; al - char to compare to
; ebx - row
; edi - col
; RETURN:
; cl - if successful
game_check_up_diagonal proc
    assume esi: ptr Game
    push ebx
    push edi

    ; ecx = chain length
    xor ecx, ecx

check:
    cmp ebx, [esi].rows
    je not_found

    cmp edi, [esi].cols
    je not_found

    mov edx, [esi].arr
    mov edx, [edx + ebx * sizeof dword]
    mov dl, [edx + edi]

    cmp dl, al
    je matching

    xor ecx, ecx
    jmp compare

matching:
    inc ecx

compare:
    cmp ecx, [esi].win
    jne next

    ; we found a match!
    mov cl, 1
    jmp finish

next:
    inc ebx
    inc edi
    jmp check

not_found:
    xor cl, cl
    
finish:
    pop edi
    pop ebx
    ret
game_check_up_diagonal endp

; PARAMS:
; esi - Game*
; al - char to compare to
; ebx - row
; edi - col
; RETURN:
; cl - if successful
game_check_down_diagonal proc
    assume esi: ptr Game
    push ebx
    push edi

    ; ecx = chain length
    xor ecx, ecx

check:
    ; -1
    cmp ebx, 0FFFFFFFFh
    je not_found

    cmp edi, [esi].cols
    je not_found

    mov edx, [esi].arr
    mov edx, [edx + ebx * sizeof dword]
    mov dl, [edx + edi]

    cmp dl, al
    je matching

    xor ecx, ecx
    jmp compare

matching:
    inc ecx

compare:
    cmp ecx, [esi].win
    jne next

    ; we found a match!
    mov cl, 1
    jmp finish

next:
    dec ebx
    inc edi
    jmp check

not_found:
    xor cl, cl
    
finish:
    pop edi
    pop ebx
    ret
game_check_down_diagonal endp

; PARAMS:
; esi - Game*
; al - char to compare to
; ebx - row
; edi - col
; this is rly unconventional but idc my abi is awesome
; RETURN:
; cl - if successful
game_check_around proc
    assume esi: ptr Game

    call game_check_vertical
    test cl, cl
    jnz finish

    call game_check_horizontal
    test cl, cl
    jnz finish

    call game_check_up_diagonal
    test cl, cl
    jnz finish

    call game_check_down_diagonal
    test cl, cl
    jnz finish

    xor cl, cl

finish:
    ret
game_check_around endp

; PARAMS:
; esi - Game*
; RETURN:
; al - if someone won
game_check_win proc
    assume esi: ptr Game

    ; ebx - row
    push ebx
    xor ebx, ebx
    ; edi - col
    push edi

row:
    xor edi, edi
    cmp ebx, [esi].rows
    je not_found

    col:
        cmp edi, [esi].cols
        je next_row

        mov eax, [esi].arr
        mov eax, [eax + ebx * sizeof dword]
        mov al, [eax + edi]
        
    ; p1:
        xor cl, cl
        call game_current_char

        cmp al, cl
        jne p2

        call game_check_around
        test cl, cl
        jz p2

        .data
            p1_won byte "Player 1 Won!", 0Ah
        .code

        lea eax, p1_won
        mov ecx, lengthof p1_won
        call out_print

        mov al, 1
        jmp finish

    p2:
        ; get player 2 char
        mov cl, 1
        call game_current_char

        cmp al, cl
        jne next_col

        call game_check_around
        test cl, cl
        jz next_col

        .data
            p2_won byte "Player 2 Won!", 0Ah
        .code

        lea eax, p2_won
        mov ecx, lengthof p2_won
        call out_print

        mov al, 1
        jmp finish

    next_col:
        inc edi
        jmp col

next_row:
    inc ebx
    jmp row

not_found:
    xor al, al

finish:
    pop edi
    pop ebx
    ret
game_check_win endp

; PARAMS:
; esi - Game*
; RETURN:
; al - keep playing?
game_turn proc
    ; check preconditions

    ; check if someone won lol
    call game_check_win
    test al, al
    jz turns

    xor al, al
    ret

turns:
    ; no turns left? tie (since we already checked wins)
    mov eax, [esi].turns_left
    test al, al
    jnz query

    .data
        tie_game byte "Tie game!", 0Ah
    .code

    lea eax, tie_game
    mov ecx, lengthof tie_game
    call out_print
    push 0
    call _ExitProcess@4

query:
    .data
        prompt_first byte "Enter a column between 0 and "
        prompt_second byte " to play in: "
    .code

    lea eax, prompt_first
    mov ecx, lengthof prompt_first
    call out_print

    mov eax, [esi].cols
    dec eax
    call out_write_int

    lea eax, prompt_second
    mov ecx, lengthof prompt_second
    call out_print

    call in_read_int

    mov ecx, [esi].cols
    dec ecx
    cmp eax, ecx
    ja query

    call game_valid_column
    cmp ecx, 0FFFFFFFFh
    je query

    mov edx, [esi].arr
    mov edx, [edx + ecx * sizeof dword]
    ; get char
    mov ecx, [esi].player_two
    call game_current_char
    mov [edx + eax], cl

    ; turn cleanup
    ; toggle player_two
    xor [esi].player_two, 1

    ; decrement turn count
    dec [esi].turns_left

    mov al, 1
    ret
game_turn endp

; oh boy
; PARAMS:
; esp + 4 - Game*
game_play proc
    push esi
    assume esi: ptr Game
    mov esi, esp
    add esi, 8

play:
    call game_print
    call game_turn
    test al, al
    jnz play

    pop esi
    ret
game_play endp

end