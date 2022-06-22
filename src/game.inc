; Definition shared between main.asm and game.asm.

Game struct
    rows dword ?
    cols dword ?
    win dword ?
    turns_left dword ?
    ; this is a bool but word alignment is better lol
    player_two dword ?
    arr dword ?
Game ends