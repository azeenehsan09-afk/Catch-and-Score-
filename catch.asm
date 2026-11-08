; ============================================================
; COAL Project - CATCH & SCORE   (Phase I)

; Theme   : Coins / Apples / Stars  -> Basket -> Bombs / Crosses
; Phase I : start screen, game screen (3x3 objects, timer,
;           live score) and end screen.
;

[org 0x0100]
 jmp start

; ------------------------------------------------------------
; Variables
; ------------------------------------------------------------
score:      dw 0            ; live score (0..9999)
timeleft:   dw 30           ; remaining game time in seconds
tickdelay:  dw 10           ; outer delay count for ~1 second
                            ; (tune: bigger = slower clock)

; ------------------------------------------------------------
; 3x3 sprites: 9 words each. High byte = attribute, low byte =
; ASCII / CP437 code.  0x0000 = transparent.
; ------------------------------------------------------------
coin:   dw 0x0000, 0x0EDC, 0x0000      ;   ▄
        dw 0x0EDE, 0x0E24, 0x0EDD      ;  ▐$▌
        dw 0x0000, 0x0EDF, 0x0000      ;   ▀

apple:  dw 0x0000, 0x0A2F, 0x0000      ;   /   (green leaf)
        dw 0x0CDE, 0x0CDB, 0x0CDD      ;  ▐█▌  (red body)
        dw 0x0000, 0x0CDF, 0x0000      ;   ▀

star:   dw 0x0000, 0x0B7C, 0x0000      ;   |
        dw 0x0B2D, 0x0F2A, 0x0B2D      ;  -*-
        dw 0x0000, 0x0B7C, 0x0000      ;   |

bomb:   dw 0x0000, 0x0C2A, 0x0000      ;   *   (red spark)
        dw 0x07DB, 0x07DB, 0x07DB      ;  ███  (grey body)
        dw 0x0000, 0x07DF, 0x0000      ;   ▀

cross:  dw 0x0C5C, 0x0000, 0x0C2F      ;  \ /
        dw 0x0000, 0x0C58, 0x0000      ;   X
        dw 0x0C2F, 0x0000, 0x0C5C      ;  / \

basket: dw 0x0F5C, 0x0000, 0x0F2F      ;  \ /
        dw 0x06DB, 0x06DB, 0x06DB      ;  ███  (brown)
        dw 0x0000, 0x06DF, 0x0000      ;   ▀

; ------------------------------------------------------------
; Big title font: 5x5 pixels per letter, 5 bytes per letter
; (one byte per pixel row, bits 4..0 = pixels left to right).
; Letter numbers: 0=C 1=A 2=T 3=H 4=S 5=O 6=R 7=E
; ------------------------------------------------------------
font:   db 0x0F, 0x10, 0x10, 0x10, 0x0F    ; 0 = C
        db 0x0E, 0x11, 0x1F, 0x11, 0x11    ; 1 = A
        db 0x1F, 0x04, 0x04, 0x04, 0x04    ; 2 = T
        db 0x11, 0x11, 0x1F, 0x11, 0x11    ; 3 = H
        db 0x0F, 0x10, 0x0E, 0x01, 0x1E    ; 4 = S
        db 0x0E, 0x11, 0x11, 0x11, 0x0E    ; 5 = O
        db 0x1E, 0x11, 0x1E, 0x12, 0x11    ; 6 = R
        db 0x1F, 0x10, 0x1E, 0x10, 0x1F    ; 7 = E
w_catch: db 0, 1, 2, 0, 3, 0xFF            ; C A T C H  (0xFF = end)
w_score: db 4, 0, 5, 6, 7, 0xFF            ; S C O R E

; ------------------------------------------------------------
; Strings (null terminated). *_len = length without the zero.
; ------------------------------------------------------------
s_how:      db 'H O W   T O   P L A Y', 0
s_how_len   equ $ - s_how - 1
s_sub:      db 'A Falling Object Collection Game', 0
s_sub_len   equ $ - s_sub - 1
s_hdr1:     db 'CATCH THESE TO SCORE:', 0
s_hdr2:     db 'AVOID THESE (THEY END THE GAME):', 0
s_coin:     db 'Coin  = 10 pts', 0
s_apple:    db 'Apple = 20 pts', 0
s_star:     db 'Star  = 50 pts', 0
s_bomb:     db 'Bomb  = GAME OVER', 0
s_cross:    db 'Cross = GAME OVER', 0
s_basket:   db 'Basket = YOU', 0
s_inst1:    db 'Use the LEFT / RIGHT arrow keys to move the basket', 0
s_inst1_len equ $ - s_inst1 - 1
s_inst2:    db 'Catch the coins, apples and stars to score points', 0
s_inst2_len equ $ - s_inst2 - 1
s_inst3:    db 'Catch a bomb or a cross and the game is over!', 0
s_inst3_len equ $ - s_inst3 - 1
s_enter:    db 'Press ENTER to Start', 0
s_enter_len equ $ - s_enter - 1
s_play:     db 'Press ENTER to Play', 0
s_play_len equ $ - s_play - 1
s_score:    db 'SCORE:', 0
s_time:     db 'TIME:', 0
s_game:     db 'CATCH & SCORE', 0
s_game_len  equ $ - s_game - 1
s_legend:   db 'Coin=10   Apple=20   Star=50   Bomb / Cross = GAME OVER', 0
s_legend_len equ $ - s_legend - 1
s_over:     db 'G A M E   O V E R', 0
s_over_len  equ $ - s_over - 1
s_timeup:   db 'The time is up!', 0
s_timeup_len equ $ - s_timeup - 1
s_final:    db 'FINAL SCORE:', 0
s_exit:     db 'Press ENTER to exit', 0
s_exit_len  equ $ - s_exit - 1

; ============================================================
; SUBROUTINES
; ============================================================

; ------------------------------------------------------------
; fillrect - fills a rectangle of screen cells with one cell
; Parameters (pushed in this order): top, left, height, width,
;   cell (high byte attribute, low byte character).
; height and width must be at least 1.
; ------------------------------------------------------------
fillrect:   push bp
            mov bp, sp                  ; [bp+12]=top  [bp+10]=left
            push ax                     ; [bp+8]=height [bp+6]=width
            push bx                     ; [bp+4]=cell
            push cx
            push dx
            push di
            push es
            mov ax, 0xb800
            mov es, ax                  ; es -> video memory
            mov al, 80                  ; columns per row
            mul byte [bp+12]            ; ax = top * 80
            add ax, [bp+10]             ; + left
            shl ax, 1                   ; two bytes per cell
            mov di, ax                  ; di = offset of first cell
            mov dx, [bp+8]              ; rows left to fill
            mov ax, [bp+4]              ; ax = cell to write
fr_row:     mov cx, [bp+6]              ; columns in this row
            mov bx, di                  ; bx = start of this row
fr_col:     mov [es:bx], ax             ; write one cell
            add bx, 2                   ; next cell
            dec cx
            jnz fr_col
            add di, 160                 ; next screen row
            dec dx
            jnz fr_row
            pop es
            pop di
            pop dx
            pop cx
            pop bx
            pop ax
            mov sp, bp
            pop bp
            ret 10

; ------------------------------------------------------------
; clrscr - clears the whole screen (no parameters)
; ------------------------------------------------------------
clrscr:     push bp
            mov bp, sp
            push ax
            mov ax, 0
            push ax                     ; top = 0
            push ax                     ; left = 0
            mov ax, 25
            push ax                     ; height = 25
            mov ax, 80
            push ax                     ; width = 80
            mov ax, 0x0720              ; space, grey on black
            push ax
            call fillrect
            pop ax
            mov sp, bp
            pop bp
            ret

; ------------------------------------------------------------
; drawborder - double line yellow border around the screen
; (no parameters)
; ------------------------------------------------------------
drawborder: push bp
            mov bp, sp
            push ax
            ; top line
            mov ax, 0
            push ax
            push ax
            mov ax, 1
            push ax
            mov ax, 80
            push ax
            mov ax, 0x0ECD
            push ax
            call fillrect
            ; bottom line
            mov ax, 24
            push ax
            mov ax, 0
            push ax
            mov ax, 1
            push ax
            mov ax, 80
            push ax
            mov ax, 0x0ECD
            push ax
            call fillrect
            ; left line
            mov ax, 1
            push ax
            mov ax, 0
            push ax
            mov ax, 23
            push ax
            mov ax, 1
            push ax
            mov ax, 0x0EBA
            push ax
            call fillrect
            ; right line
            mov ax, 1
            push ax
            mov ax, 79
            push ax
            mov ax, 23
            push ax
            mov ax, 1
            push ax
            mov ax, 0x0EBA
            push ax
            call fillrect
            ; top left corner
            mov ax, 0
            push ax
            push ax
            mov ax, 1
            push ax
            push ax
            mov ax, 0x0EC9
            push ax
            call fillrect
            ; top right corner
            mov ax, 0
            push ax
            mov ax, 79
            push ax
            mov ax, 1
            push ax
            push ax
            mov ax, 0x0EBB
            push ax
            call fillrect
            ; bottom left corner
            mov ax, 24
            push ax
            mov ax, 0
            push ax
            mov ax, 1
            push ax
            push ax
            mov ax, 0x0EC8
            push ax
            call fillrect
            ; bottom right corner
            mov ax, 24
            push ax
            mov ax, 79
            push ax
            mov ax, 1
            push ax
            push ax
            mov ax, 0x0EBC
            push ax
            call fillrect
            pop ax
            mov sp, bp
            pop bp
            ret

; ------------------------------------------------------------
; printstr - prints a null terminated string
; Parameters: row, column, attribute, address of string
; ------------------------------------------------------------
printstr:   push bp
            mov bp, sp                  ; [bp+10]=row [bp+8]=col
            push ax                     ; [bp+6]=attr [bp+4]=string
            push dx
            push si
            push di
            push es
            mov ax, 0xb800
            mov es, ax
            mov al, 80
            mul byte [bp+10]            ; ax = row * 80
            add ax, [bp+8]              ; + column
            shl ax, 1
            mov di, ax                  ; di = screen offset
            mov si, [bp+4]              ; si = string
            mov dh, [bp+6]              ; dh = attribute
ps_next:    mov dl, [si]                ; next character
            cmp dl, 0
            je ps_done                  ; zero ends the string
            mov [es:di], dx             ; attribute:character
            add di, 2
            add si, 1
            jmp ps_next
ps_done:    pop es
            pop di
            pop si
            pop dx
            pop ax
            mov sp, bp
            pop bp
            ret 8

; ------------------------------------------------------------
; printnum - prints an unsigned decimal number (no DIV needed:
; digits are found by repeated subtraction of 1000/100/10/1)
; Parameters: row, column, attribute, value, number of digits
;             (1 to 4)
; Local array: [bp-2]=1  [bp-4]=10  [bp-6]=100  [bp-8]=1000
; ------------------------------------------------------------
printnum:   push bp
            mov bp, sp                  ; [bp+12]=row [bp+10]=col
            sub sp, 8                   ; [bp+8]=attr [bp+6]=value
            push ax                     ; [bp+4]=digits
            push bx
            push dx
            push si
            push di
            push es
            mov word [bp-2], 1
            mov word [bp-4], 10
            mov word [bp-6], 100
            mov word [bp-8], 1000
            mov ax, 0xb800
            mov es, ax
            mov al, 80
            mul byte [bp+12]            ; ax = row * 80
            add ax, [bp+10]
            shl ax, 1
            mov di, ax                  ; di = screen offset
            mov si, [bp+4]              ; si = number of digits
            shl si, 1                   ; bytes in local array
            mov ax, 0
            sub ax, si
            mov si, ax                  ; si = -2 * digits
            mov ax, [bp+6]              ; ax = value
pn_digit:   mov bx, [bp+si]             ; bx = current divisor
            mov dx, 0                   ; dx = digit counter
pn_count:   cmp ax, bx
            jb pn_got                   ; remainder < divisor
            sub ax, bx
            add dx, 1
            jmp pn_count
pn_got:     add dl, 0x30                ; digit -> ASCII
            mov dh, [bp+8]              ; attribute
            mov [es:di], dx
            add di, 2
            add si, 2                   ; next smaller divisor
            cmp si, 0
            jne pn_digit
            pop es
            pop di
            pop si
            pop dx
            pop bx
            pop ax
            mov sp, bp
            pop bp
            ret 10

; ------------------------------------------------------------
; drawobj - draws a 3x3 object (9 words, row by row)
; Parameters: row, column (top-left cell), address of sprite
; ------------------------------------------------------------
drawobj:    push bp
            mov bp, sp                  ; [bp+8]=row [bp+6]=col
            push ax                     ; [bp+4]=sprite
            push bx
            push cx
            push dx
            push si
            push di
            push es
            mov ax, 0xb800
            mov es, ax
            mov al, 80
            mul byte [bp+8]             ; ax = row * 80
            add ax, [bp+6]
            shl ax, 1
            mov di, ax                  ; di = offset of top-left
            mov si, [bp+4]              ; si = sprite data
            mov dx, 3                   ; 3 object rows
do_row:     mov cx, 3                   ; 3 object columns
            mov bx, di
do_col:     mov ax, [si]                ; next cell of sprite
            cmp ax, 0
            je do_skip                  ; 0 = transparent
            mov [es:bx], ax
do_skip:    add bx, 2
            add si, 2
            dec cx
            jnz do_col
            add di, 160                 ; next screen row
            dec dx
            jnz do_row
            pop es
            pop di
            pop si
            pop dx
            pop cx
            pop bx
            pop ax
            mov sp, bp
            pop bp
            ret 6

; ------------------------------------------------------------
; drawletter - draws one big 5x5 letter. Every pixel is a full
; block 2 cells wide, so a letter covers 5 rows x 10 columns.
; Parameters: row, column, attribute, address of 5-byte shape
; Local: [bp-2] = pixel rows still to draw
; ------------------------------------------------------------
drawletter: push bp
            mov bp, sp                  ; [bp+10]=row [bp+8]=col
            sub sp, 2                   ; [bp+6]=attr [bp+4]=shape
            push ax
            push bx
            push cx
            push dx
            push si
            push di
            push es
            mov ax, 0xb800
            mov es, ax
            mov al, 80
            mul byte [bp+10]            ; ax = row * 80
            add ax, [bp+8]              ; + column
            shl ax, 1
            mov di, ax                  ; di = start of letter row
            mov si, [bp+4]              ; si = shape bytes
            mov dh, [bp+6]              ; dh = colour
            mov dl, 0xDB                ; dl = full block
            mov word [bp-2], 5          ; 5 pixel rows
dlt_row:    mov al, [si]                ; al = pixels of this row
            mov bx, di                  ; bx = screen pointer
            mov cx, 5                   ; 5 pixels per row
dlt_pix:    test al, 0x10               ; is the left pixel set?
            jz dlt_skip
            mov [es:bx], dx             ; pixel = two block cells
            mov [es:bx+2], dx
dlt_skip:   add bx, 4                   ; next pixel (2 cells)
            shl al, 1                   ; bring next pixel to bit 4
            dec cx
            jnz dlt_pix
            add si, 1                   ; next shape byte
            add di, 160                 ; next screen row
            sub word [bp-2], 1
            jnz dlt_row
            pop es
            pop di
            pop si
            pop dx
            pop cx
            pop bx
            pop ax
            mov sp, bp
            pop bp
            ret 8

; ------------------------------------------------------------
; drawword - draws a word of big letters, left to right
; Parameters: row, column, attribute, address of word,
;             address of font
; The word is a list of letter numbers ended by 0xFF.
; Local: [bp-2] = column of the next letter
; ------------------------------------------------------------
drawword:   push bp
            mov bp, sp                  ; [bp+12]=row [bp+10]=col
            sub sp, 2                   ; [bp+8]=attr [bp+6]=word
            push ax                     ; [bp+4]=font
            push bx
            push si
            mov ax, [bp+10]
            mov [bp-2], ax              ; first letter column
            mov si, [bp+6]              ; si = letter numbers
dw_next:    mov al, [si]
            cmp al, 0xFF
            je dw_done                  ; 0xFF ends the word
            mov ah, 0
            mov bx, ax
            shl bx, 1
            shl bx, 1                   ; bx = number * 4
            add bx, ax                  ; bx = number * 5
            add bx, [bp+4]              ; + font = this letter's shape
            push word [bp+12]           ; row
            push word [bp-2]            ; column
            push word [bp+8]            ; colour
            push bx                     ; shape address
            call drawletter
            add word [bp-2], 11         ; 10 columns + 1 gap
            add si, 1
            jmp dw_next
dw_done:    pop si
            pop bx
            pop ax
            mov sp, bp
            pop bp
            ret 10

; ------------------------------------------------------------
; delay - busy wait, about (count * 65536) loop iterations
; Parameter: count
; ------------------------------------------------------------
delay:      push bp
            mov bp, sp
            push bx
            push cx
            mov bx, [bp+4]              ; outer count
dl_outer:   mov cx, 0                   ; 0 -> 65536 inner rounds
dl_inner:   dec cx
            jnz dl_inner
            dec bx
            jnz dl_outer
            pop cx
            pop bx
            mov sp, bp
            pop bp
            ret 2

; ------------------------------------------------------------
; waitenter - waits until the Enter key (ASCII 13) is pressed
; (uses BIOS keyboard service INT 16h / AH=0)
; ------------------------------------------------------------
waitenter:  push bp
            mov bp, sp
            push ax
we_again:   mov ah, 0
            int 0x16
            cmp al, 13
            jne we_again
            pop ax
            mov sp, bp
            pop bp
            ret

; ============================================================
; MAIN PROGRAM
; ============================================================
start:

; ------------------------------------------------------------
; PAGE 1 : TITLE SCREEN - big block letters "CATCH / SCORE"
; ------------------------------------------------------------
            call clrscr
            call drawborder

            ; shadow of CATCH (one cell down and right)
            mov ax, 3
            push ax                     ; row
            mov ax, 4
            push ax                     ; column
            mov ax, 0x01
            push ax                     ; dark blue
            mov ax, w_catch
            push ax                     ; word = C A T C H
            mov ax, font
            push ax                     ; letter shapes
            call drawword
            ; CATCH in light blue
            mov ax, 2
            push ax
            mov ax, 3
            push ax
            mov ax, 0x09
            push ax
            mov ax, w_catch
            push ax
            mov ax, font
            push ax
            call drawword
            ; shadow of SCORE
            mov ax, 9
            push ax
            mov ax, 21
            push ax
            mov ax, 0x06
            push ax                     ; brown
            mov ax, w_score
            push ax
            mov ax, font
            push ax
            call drawword
            ; SCORE in yellow
            mov ax, 8
            push ax
            mov ax, 20
            push ax
            mov ax, 0x0E
            push ax
            mov ax, w_score
            push ax
            mov ax, font
            push ax
            call drawword

            ; decoration: falling objects around the title
            mov ax, 3
            push ax
            mov ax, 66
            push ax
            mov ax, star
            push ax
            call drawobj
            mov ax, 3
            push ax
            mov ax, 72
            push ax
            mov ax, coin
            push ax
            call drawobj
            mov ax, 9
            push ax
            mov ax, 6
            push ax
            mov ax, apple
            push ax
            call drawobj
            mov ax, 9
            push ax
            mov ax, 12
            push ax
            mov ax, bomb
            push ax
            call drawobj
            mov ax, 16
            push ax
            mov ax, 10
            push ax
            mov ax, coin
            push ax
            call drawobj
            mov ax, 16
            push ax
            mov ax, 68
            push ax
            mov ax, star
            push ax
            call drawobj
            mov ax, 19
            push ax
            mov ax, 16
            push ax
            mov ax, bomb
            push ax
            call drawobj
            mov ax, 19
            push ax
            mov ax, 60
            push ax
            mov ax, cross
            push ax
            call drawobj
            mov ax, 19
            push ax
            mov ax, 38
            push ax
            mov ax, basket
            push ax
            call drawobj

            ; ground under the basket
            mov ax, 22
            push ax
            mov ax, 1
            push ax
            mov ax, 1
            push ax
            mov ax, 78
            push ax
            mov ax, 0x06DF
            push ax
            call fillrect

            ; tagline
            mov ax, 15
            push ax
            mov ax, (80 - s_sub_len) / 2
            push ax
            mov ax, 0x0B
            push ax
            mov ax, s_sub
            push ax
            call printstr
            ; press enter prompt
            mov ax, 18
            push ax
            mov ax, (80 - s_enter_len) / 2
            push ax
            mov ax, 0x0F
            push ax
            mov ax, s_enter
            push ax
            call printstr

            call waitenter              ; page 1 -> page 2 on Enter

; ------------------------------------------------------------
; PAGE 2 : INSTRUCTIONS
; ------------------------------------------------------------
            call clrscr
            call drawborder

            ; page heading
            mov ax, 2
            push ax
            mov ax, (80 - s_how_len) / 2
            push ax
            mov ax, 0x0E
            push ax
            mov ax, s_how
            push ax
            call printstr


            ; header: score objects
            mov ax, 5
            push ax
            mov ax, 14
            push ax
            mov ax, 0x0A
            push ax
            mov ax, s_hdr1
            push ax
            call printstr
            ; coin sprite + label
            mov ax, 6
            push ax
            mov ax, 14
            push ax
            mov ax, coin
            push ax
            call drawobj
            mov ax, 7
            push ax
            mov ax, 18
            push ax
            mov ax, 0x0F
            push ax
            mov ax, s_coin
            push ax
            call printstr
            ; apple sprite + label
            mov ax, 6
            push ax
            mov ax, 34
            push ax
            mov ax, apple
            push ax
            call drawobj
            mov ax, 7
            push ax
            mov ax, 38
            push ax
            mov ax, 0x0F
            push ax
            mov ax, s_apple
            push ax
            call printstr
            ; star sprite + label
            mov ax, 6
            push ax
            mov ax, 54
            push ax
            mov ax, star
            push ax
            call drawobj
            mov ax, 7
            push ax
            mov ax, 58
            push ax
            mov ax, 0x0F
            push ax
            mov ax, s_star
            push ax
            call printstr

            ; header: game ending objects
            mov ax, 10
            push ax
            mov ax, 14
            push ax
            mov ax, 0x0C
            push ax
            mov ax, s_hdr2
            push ax
            call printstr
            ; bomb sprite + label
            mov ax, 11
            push ax
            mov ax, 24
            push ax
            mov ax, bomb
            push ax
            call drawobj
            mov ax, 12
            push ax
            mov ax, 28
            push ax
            mov ax, 0x0F
            push ax
            mov ax, s_bomb
            push ax
            call printstr
            ; cross sprite + label
            mov ax, 11
            push ax
            mov ax, 48
            push ax
            mov ax, cross
            push ax
            call drawobj
            mov ax, 12
            push ax
            mov ax, 52
            push ax
            mov ax, 0x0F
            push ax
            mov ax, s_cross
            push ax
            call printstr

            ; player sprite + label
            mov ax, 15
            push ax
            mov ax, 14
            push ax
            mov ax, basket
            push ax
            call drawobj
            mov ax, 16
            push ax
            mov ax, 18
            push ax
            mov ax, 0x0B
            push ax
            mov ax, s_basket
            push ax
            call printstr

            ; instructions
            mov ax, 18
            push ax
            mov ax, (80 - s_inst1_len) / 2
            push ax
            mov ax, 0x07
            push ax
            mov ax, s_inst1
            push ax
            call printstr
            mov ax, 19
            push ax
            mov ax, (80 - s_inst2_len) / 2
            push ax
            mov ax, 0x07
            push ax
            mov ax, s_inst2
            push ax
            call printstr
            mov ax, 20
            push ax
            mov ax, (80 - s_inst3_len) / 2
            push ax
            mov ax, 0x07
            push ax
            mov ax, s_inst3
            push ax
            call printstr

            ; press enter prompt
            mov ax, 22
            push ax
            mov ax, (80 - s_play_len) / 2
            push ax
            mov ax, 0x0A
            push ax
            mov ax, s_play
            push ax
            call printstr

            call waitenter              ; page 2 -> game on Enter

; ------------------------------------------------------------
; GAME SCREEN
; ------------------------------------------------------------
            call clrscr

            ; blue HUD bar on row 0
            mov ax, 0
            push ax
            push ax
            mov ax, 1
            push ax
            mov ax, 80
            push ax
            mov ax, 0x1F20
            push ax
            call fillrect
            ; "SCORE:" label
            mov ax, 0
            push ax
            mov ax, 2
            push ax
            mov ax, 0x1F
            push ax
            mov ax, s_score
            push ax
            call printstr
            ; game name in the middle of the HUD
            mov ax, 0
            push ax
            mov ax, (80 - s_game_len) / 2
            push ax
            mov ax, 0x1E
            push ax
            mov ax, s_game
            push ax
            call printstr
            ; "TIME:" label
            mov ax, 0
            push ax
            mov ax, 64
            push ax
            mov ax, 0x1F
            push ax
            mov ax, s_time
            push ax
            call printstr
            ; separator line under the HUD (row 1)
            mov ax, 1
            push ax
            mov ax, 0
            push ax
            mov ax, 1
            push ax
            mov ax, 80
            push ax
            mov ax, 0x07C4
            push ax
            call fillrect
            ; ground (row 23)
            mov ax, 23
            push ax
            mov ax, 0
            push ax
            mov ax, 1
            push ax
            mov ax, 80
            push ax
            mov ax, 0x06DF
            push ax
            call fillrect
            ; legend bar (row 24)
            mov ax, 24
            push ax
            mov ax, 0
            push ax
            mov ax, 1
            push ax
            mov ax, 80
            push ax
            mov ax, 0x7020
            push ax
            call fillrect
            mov ax, 24
            push ax
            mov ax, (80 - s_legend_len) / 2
            push ax
            mov ax, 0x70
            push ax
            mov ax, s_legend
            push ax
            call printstr

            ; ---- objects placed in the play area (rows 2..22) ----
            ; score-giving objects
            mov ax, 3
            push ax
            mov ax, 8
            push ax
            mov ax, coin
            push ax
            call drawobj
            mov ax, 10
            push ax
            mov ax, 30
            push ax
            mov ax, apple
            push ax
            call drawobj
            mov ax, 5
            push ax
            mov ax, 46
            push ax
            mov ax, star
            push ax
            call drawobj
            mov ax, 12
            push ax
            mov ax, 66
            push ax
            mov ax, coin
            push ax
            call drawobj
            mov ax, 15
            push ax
            mov ax, 12
            push ax
            mov ax, star
            push ax
            call drawobj
            mov ax, 3
            push ax
            mov ax, 70
            push ax
            mov ax, apple
            push ax
            call drawobj
            ; game-ending objects
            mov ax, 4
            push ax
            mov ax, 24
            push ax
            mov ax, bomb
            push ax
            call drawobj
            mov ax, 8
            push ax
            mov ax, 56
            push ax
            mov ax, cross
            push ax
            call drawobj
            mov ax, 14
            push ax
            mov ax, 48
            push ax
            mov ax, bomb
            push ax
            call drawobj
            mov ax, 9
            push ax
            mov ax, 4
            push ax
            mov ax, cross
            push ax
            call drawobj
            ; collecting object (player) just above the ground
            mov ax, 20
            push ax
            mov ax, 38
            push ax
            mov ax, basket
            push ax
            call drawobj

            ; ---- game timer: count down from 30 to 0 ----
gameloop:   ; show remaining time (2 digits)
            mov ax, 0
            push ax
            mov ax, 70
            push ax
            mov ax, 0x1E
            push ax
            push word [timeleft]
            mov ax, 2
            push ax
            call printnum
            ; show live score (4 digits)
            mov ax, 0
            push ax
            mov ax, 9
            push ax
            mov ax, 0x1E
            push ax
            push word [score]
            mov ax, 4
            push ax
            call printnum
            ; wait about one second
            push word [tickdelay]
            call delay
            cmp word [timeleft], 0
            je gameover                 ; time is up
            sub word [timeleft], 1
            jmp gameloop

; ------------------------------------------------------------
; END SCREEN
; ------------------------------------------------------------
gameover:   call clrscr
            call drawborder

            ; a bomb above the message
            mov ax, 4
            push ax
            mov ax, 38
            push ax
            mov ax, bomb
            push ax
            call drawobj
            ; GAME OVER
            mov ax, 8
            push ax
            mov ax, (80 - s_over_len) / 2
            push ax
            mov ax, 0x0C
            push ax
            mov ax, s_over
            push ax
            call printstr
            ; reason
            mov ax, 10
            push ax
            mov ax, (80 - s_timeup_len) / 2
            push ax
            mov ax, 0x0E
            push ax
            mov ax, s_timeup
            push ax
            call printstr
            ; FINAL SCORE: label (col 31) and value (col 44)
            mov ax, 13
            push ax
            mov ax, 31
            push ax
            mov ax, 0x0F
            push ax
            mov ax, s_final
            push ax
            call printstr
            mov ax, 13
            push ax
            mov ax, 44
            push ax
            mov ax, 0x0E
            push ax
            push word [score]
            mov ax, 4
            push ax
            call printnum
            ; exit prompt
            mov ax, 17
            push ax
            mov ax, (80 - s_exit_len) / 2
            push ax
            mov ax, 0x0A
            push ax
            mov ax, s_exit
            push ax
            call printstr

            call waitenter
            call clrscr

            mov ax, 0x4c00              ; terminate program
            int 0x21