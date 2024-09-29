org 0x7C00
use16

start_point:

initialize_system:
    xor     ax, ax
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, 0x7C00

clear_screen:
    mov     ax, 0xB800
    mov     es, ax
    mov     ax, 3
    int     0x10
    inc     ah
    mov     cx, 0x2000
    int     0x10
    xor     di, di
    mov     cx, (160*25)/2
    mov     ax, 0x0720
    pusha
    rep     stosw

setup_game_state:
    mov     di, tick_counter
    stosd
    stosd
    mov     ax, (160*25)/2
    stosw
    add     al, 4
    stosw
    add     al, 4
    stosw
    mov     al, 0xFF
    out     0x60, al
    in      al, 0x61
    and     al, 0xFC
    out     0x61, al
    mov     di, (160*12) + 80    
    mov     [snake_ptr], di


draw_game_border:
    mov     ax, 0x072A
    mov     cx, 38
    mov     di, (160*4)+40
    rep     stosw
    mov     cx, 16
border_draw_loop:
    stosw
    pusha
    mov     cx, 41
    xor     ah, ah
    rep     stosw
    mov     ah, 0x07
    stosw
    popa
    add     di, 158
    loop    border_draw_loop
    mov     cx, 38
    mov     di, (160*20)+42
    rep     stosw

display_texts:
    mov     di, (160*3)+42
    mov     si, title_text
    call    render_text
    mov     si, score_text
    mov     di, (160*3)+94
    call    render_text
    mov     si, control_text
    mov     di, (160*21)+42
    call    render_text

main_game_loop:

prepare_game:
    popa

    mov     di, cx
    mov     si, initial_snake    
    call    render_text
    mov     bp, 6               
    call    spawn_food

game_delay:
    xor     eax, eax
    int     0x1A
    mov     ax, cx
    shl     eax, 16
    mov     ax, dx

    mov     ebx, eax
    sub     eax, [tick_counter]

    cmp     eax, 3
    jl      game_delay

    mov     [tick_counter], ebx

    in      al, 0x60

handle_input:
    cmp     al, 177
    je      start_point
    and     al, 0x7F
    cmp     al, 17
    je      move_up
    cmp     al, 30
    je      move_left
    cmp     al, 31
    je      move_down
    cmp     al, 32
    jne     game_delay

move_right:
    mov     al, '>'
    add     di, 4
    jmp     execute_move

move_up:
    mov     al, '|'
    sub     di, 160
    jmp     execute_move

move_down:
    mov     al, '|'
    add     di, 160
    jmp     execute_move

move_left:
    mov     al, '<'
    sub     di, 4

execute_move:
    cmp     byte [es:di], '@'
    sete    ah
    je      safe_move
    cmp     byte [es:di], ' '
    jne     game_over

safe_move:
    stosb
    dec     di

    pusha

    push    es
    push    ds
    pop     es
    mov     cx, bp
    inc     cx
    mov     si, snake_ptr
    add     si, bp
    mov     di, si
    inc     di
    inc     di
    std
    rep     movsb
    cld
    pop     es

    popa
    push    di
    mov     [snake_ptr], di
    mov     di, [snake_ptr+2]
    mov     al, '*'        
    stosb

    cmp     ah, 1
    je      handle_food

    mov     di, [snake_ptr + bp]
    mov     al, ' '       
    stosb

    jmp     continue_game

handle_food:
    inc     bp
    inc     bp

    mov     di, (160*3)+114
    add     dword [current_score], 1
    mov     ax, [current_score]
    mov     bl, 10

update_score_display:
    div     bl
    xchg    al, ah
    add     al, '0'
    stosb
    dec     di
    dec     di
    dec     di
    mov     al, ah
    xor     ah, ah
    or      al, al
    jnz     update_score_display
    call    spawn_food

continue_game:
    pop     di
    jmp     game_delay

game_over:
    mov     di, (160*19)+92
    mov     si, gameover_text
    call    render_text
wait_for_restart:
    in      al, 0x60
    cmp     al, 177
    jne     wait_for_restart
    jmp     start_point

spawn_food:
    pusha
    xor     eax, eax
    xor     bl, bl
    int     0x1A
spawn_seed:
    xor     eax, eax
    xor     bl, bl
    int     0x1A
random_position:
    cmp     bl, 5
    jg      spawn_seed

    mov     ax, dx
    mov     cx, 75
    mul     cx
    movzx   edx, dx
    mov     ecx, 65537
    div     ecx
    mov     ax, dx
    shr     edx, 16
    mov     ecx, (160*20)
    div     cx
    and     dl, 0xFC

    inc     bl
    cmp     dx, (160*5)
    jl      random_position
    mov     di, dx
    cmp     byte [es:di], 0x20
    jne     random_position

    mov     al, '@'
    stosb
    popa
    ret

render_text:
    pusha
render_loop_text:
    lodsb
    or      al, al
    jz      render_done_text
    stosb
    inc     di
    jmp     render_loop_text
render_done_text:
    popa
    ret

title_text:        db 'Snake',0
control_text:      db 'WASD, N - restart',0
gameover_text:     db 'Game Over',0
score_text:        db 'Score:',0
initial_snake:     db '      ',0    

times 510-($-$$) db 0
dw 0xAA55

section .bss
tick_counter:      resd 1
current_score:     resd 1
snake_ptr:         resd 1
