.model flat

; io.asm
extern io_init: proc

; cmdline.asm
extern process_cmdline: proc

include game.asm

.code
start proc
    call io_init
    call process_cmdline

    ; alloc local space for game var
    sub esp, sizeof Game
    call game_init

    call game_play

    call game_deinit

    ; restore stack!
    add esp, sizeof Game
    xor eax, eax
    ret
start endp

end