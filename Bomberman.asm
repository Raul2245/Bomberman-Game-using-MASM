.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern rand: proc
includelib canvas.lib
extern BeginDrawing: proc
extern fopen: proc
extern fclose: proc
extern fprintf: proc
extern fscanf: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
window_title DB "BOMBERMAN", 0
area_width EQU 660
area_height EQU 540
area DD 0

counter DD 0 ; numara evenimentele de tip timer
score DD 0
hiScore DD 0
crntscr DD 0
scr_write DD 0
grid_x DD 30
grid_y DD 70
grid_size EQU 40

aux DD 0
box_x DD 0
box_y DD 0
box_no DD 65
enemy_no DD 0
prtmenu DD 1
winner DD 0

mode_write DB "a", 0
mode_read DB "r", 0
file_name DB "scores.txt", 0
format_d DB "%d ", 0
pwrup_x DD 0
pwrup_y DD 0
pwrup DD 0
pwrup_count DD 0

entity struct
	x DD 0
	y DD 0
	lpx DD 0
	lpy DD 0
	bmbx DD 0
	bmby DD 0
	bmbcount DD 0
	boomx DD 0
	boomy DD 0
	lives DD 1
	nobmb DD 1
	currentbmb DD 0
	immunity DD 1
entity ends

player entity {30, 70, 30, 70}
enemy1 entity {590, 70, 590, 70}
enemy2 entity {590, 470, 590, 470}
enemy3 entity {30, 470, 30, 470}

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
	
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
	
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
	
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov eax, [ebp + 24] ;culoare 
	mov dword ptr [edi], eax
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

make_text_macro macro symbol, drawArea, x, y, color
	push color
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 20
endm

get_position macro x, y
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
endm

line macro x, y, len, lat, color
local horizontal, vertical
	get_position x, y
	
	mov ecx, len
horizontal:
	mov esi, lat
	dec esi
	
	mov ebx, eax
	mov dword ptr [eax], color
	vertical:
	add eax, 4 * area_width
	mov dword ptr [eax], color
	dec esi
	cmp esi, 0
	jne vertical
	mov eax, ebx
	add eax, 4
loop horizontal
endm

numberPrint macro number, start_pos_x, start_pos_y, color
	mov ebx, 10
	mov eax, number
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, start_pos_x + 30, start_pos_y, color
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, start_pos_x + 20, start_pos_y, color
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, start_pos_x + 10, start_pos_y, color
	;cifra miilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, start_pos_x, start_pos_y, color
endm	

menu proc
	line 250, 200, 160, 140, 09E9E9Eh 
	make_text_macro 'D', area, 280, 225, 09E9E9Eh
	make_text_macro 'I', area, 290, 225, 09E9E9Eh
	make_text_macro 'F', area, 300, 225, 09E9E9Eh
	make_text_macro 'F', area, 310, 225, 09E9E9Eh
	make_text_macro 'I', area, 320, 225, 09E9E9Eh
	make_text_macro 'C', area, 330, 225, 09E9E9Eh
	make_text_macro 'U', area, 340, 225, 09E9E9Eh
	make_text_macro 'L', area, 350, 225, 09E9E9Eh
	make_text_macro 'T', area, 360, 225, 09E9E9Eh
	make_text_macro 'Y', area, 370, 225, 09E9E9Eh
	
	make_text_macro 'E', area, 310, 245, 09E9E9Eh
	make_text_macro 'A', area, 320, 245, 09E9E9Eh
	make_text_macro 'S', area, 330, 245, 09E9E9Eh
	make_text_macro 'Y', area, 340, 245, 09E9E9Eh
	
	make_text_macro 'M', area, 300, 265, 09E9E9Eh
	make_text_macro 'E', area, 310, 265, 09E9E9Eh
	make_text_macro 'D', area, 320, 265, 09E9E9Eh
	make_text_macro 'I', area, 330, 265, 09E9E9Eh
	make_text_macro 'U', area, 340, 265, 09E9E9Eh
	make_text_macro 'M', area, 350, 265, 09E9E9Eh
	
	make_text_macro 'H', area, 310, 285, 09E9E9Eh
	make_text_macro 'A', area, 320, 285, 09E9E9Eh
	make_text_macro 'R', area, 330, 285, 09E9E9Eh
	make_text_macro 'D', area, 340, 285, 09E9E9Eh
	ret
menu endp

winning proc
	cmp scr_write, 0
	jne cont_winning
	push offset mode_write
	push offset file_name
	call fopen 
	add esp, 8
	mov esi, eax
	
	push score
	push offset format_d
	push esi
	call fprintf
	add esp, 12
	
	inc scr_write
	
	push esi
	call fclose
	add esp, 4
	
cont_winning:
	line 250, 200, 160, 140, 09E9E9Eh 
	make_text_macro 'Y', area, 295, 230, 09E9E9Eh
	make_text_macro 'O', area, 305, 230, 09E9E9Eh
	make_text_macro 'U', area, 315, 230, 09E9E9Eh
	make_text_macro 'W', area, 335, 230, 09E9E9Eh
	make_text_macro 'O', area, 345, 230, 09E9E9Eh
	make_text_macro 'N', area, 355, 230, 09E9E9Eh
	make_text_macro 'S', area, 280, 250, 09E9E9Eh
	make_text_macro 'C', area, 290, 250, 09E9E9Eh
	make_text_macro 'O', area, 300, 250, 09E9E9Eh
	make_text_macro 'R', area, 310, 250, 09E9E9Eh
	make_text_macro 'E', area, 320, 250, 09E9E9Eh
	numberPrint score, 340, 250, 09E9E9Eh
	make_text_macro 'T', area, 285, 270, 09E9E9Eh
	make_text_macro 'I', area, 295, 270, 09E9E9Eh
	make_text_macro 'M', area, 305, 270, 09E9E9Eh
	make_text_macro 'E', area, 315, 270, 09E9E9Eh
	numberPrint counter, 335, 270, 09E9E9Eh
	make_text_macro 'R', area, 300, 300, 09E9E9Eh
	make_text_macro 'E', area, 310, 300, 09E9E9Eh
	make_text_macro 'P', area, 320, 300, 09E9E9Eh
	make_text_macro 'L', area, 330, 300, 09E9E9Eh
	make_text_macro 'A', area, 340, 300, 09E9E9Eh
	make_text_macro 'Y', area, 350, 300, 09E9E9Eh
	ret
winning endp

box_checker proc
	mov grid_x, 30
	mov grid_y, 70
	mov edi, grid_x
checker_loop:
	cmp grid_x, area_width - 30
	jg checker_new_line
	get_position grid_x, grid_y
	cmp dword ptr [eax], 0956E19h
	je box_found
	add grid_x, grid_size
	jmp checker_loop
checker_new_line:
	mov grid_x, edi
	add grid_y, grid_size
	cmp grid_y, area_height - 30
	jl checker_loop
	mov eax, 0
	jmp box_not_found
box_found:
	mov eax, 1
box_not_found:
	ret
box_checker endp
	
initializare proc
	mov winner, 0
	mov scr_write, 0
	mov grid_x, 70
	mov grid_y, 110
	mov player.x, 30
	mov player.y, 70
	mov enemy1.x, 590
	mov enemy1.y, 70
	mov enemy2.x, 590
	mov enemy2.y, 470
	mov enemy3.x, 30
	mov enemy3.y, 470
	mov box_no, 65
	mov player.lives, 1
	mov enemy1.lives, 1
	mov enemy2.lives, 1
	mov enemy3.lives, 1
	mov player.nobmb, 1
	mov enemy1.nobmb, 1
	mov enemy2.nobmb, 1
	mov enemy3.nobmb, 1
	mov player.currentbmb, 0
	mov enemy1.currentbmb, 0
	mov enemy2.currentbmb, 0
	mov enemy3.currentbmb, 0
	mov player.bmbcount, 0
	mov enemy1.bmbcount, 0
	mov enemy2.bmbcount, 0
	mov enemy3.bmbcount, 0
	mov score, 0
	mov counter, 0
	line 0, 0, area_width, area_height, 03CA73Ch ;background

	;obtinem high-score
	push offset mode_read
	push offset file_name
	call fopen
	add esp, 8
	mov esi, eax
	
	xor eax, eax
hi_score_find:
	cmp eax, -1
	je cont_int
	
	push offset crntscr 
	push offset format_d
	push esi
	call fscanf
	add esp, 12
	
	mov ebx, eax
	cmp eax, -1
	je cont_int
	
	mov ecx, crntscr
	cmp ecx, hiScore
	jl keep_searching
	
	mov hiScore, ecx
keep_searching:
	mov eax, ebx
	jmp hi_score_find
	
cont_int:	
	push esi
	call fclose
	add esp, 4
	;margine
	line 0, 0, area_width, 70, 0B5B9B5h ;latura de sus 
	line 0, area_height - 30, area_width, 30, 0B5B9B5h ;latura de jos
	line 0, 0, 30, area_height, 0B5B9B5h ;latura din stanga
	line area_width - 30, 0, 30, area_height, 0B5B9B5h ;latura din dreapta

	;header
	line 30, 5, area_width - 60, 60, 0FEEED6h
	
	;cutii/obstacole 
box_loop:
	 cmp box_no, 0
	 je iesire
	 call box_generator
	 dec box_no
	 jmp box_loop
iesire:

	;gridul de patrate
	 mov edi, grid_x
grid_loop:
	cmp grid_x, area_width - grid_size - 30
	jg new_line
	line grid_x, grid_y, grid_size, grid_size, 0B5B9B5h
	add grid_x, grid_size * 2
	jmp grid_loop
new_line:
	mov grid_x, edi
	add grid_y, grid_size * 2
	cmp grid_y, area_height - grid_size - 30
	jl grid_loop
	ret
initializare endp

box_generator proc
box_start:
	call rand
	mov esi, 15
	div esi
	mov ebx, edx
	
	;calculam coordonata x in matricea de obstacole
	mov eax, ebx
	mov esi, grid_size
	mul esi
	add eax, 30
	mov box_x, eax
	
	;calculam coordonata y in matricea de obstacole
	call rand
	mov esi, 11
	div esi
	mov edi, edx
	
	mov esi, grid_size
	mov eax, edi
	mul esi
	add eax, 70
	mov box_y, eax
	
	get_position box_x, box_y
	cmp dword ptr [eax], 0B5B9B5h
	je box_start
	cmp dword ptr [eax], 0956E19h
	je box_start
	cmp dword ptr [eax], 000FF00h
	je box_start
	cmp dword ptr [eax], 00000FFh
	je box_start
	cmp dword ptr [eax], 0FFFF00h
	je box_start
	cmp dword ptr [eax], 0000000h
	je box_start
	cmp dword ptr [eax], 0FEEED6h
	je box_start
	line box_x, box_y, grid_size, grid_size, 0956E19h
	ret 
box_generator endp

powerUp proc
pwr_start:
	call rand
	mov esi, 15
	div esi
	mov ebx, edx
	
	;calculam coordonata x in matricea de obstacole
	mov eax, ebx
	mov esi, grid_size
	mul esi
	add eax, 30
	mov pwrup_x, eax
	
	;calculam coordonata y in matricea de obstacole
	call rand
	mov esi, 11
	div esi
	mov edi, edx
	
	mov esi, grid_size
	mov eax, edi
	mul esi
	add eax, 70
	mov pwrup_y, eax
	
	get_position pwrup_x, pwrup_y 
	cmp dword ptr [eax], 0B5B9B5h
	je pwr_start
	cmp dword ptr [eax], 0956E19h
	je pwr_start
	cmp dword ptr [eax], 000FF00h
	je pwr_start
	cmp dword ptr [eax], 00000FFh
	je pwr_start
	cmp dword ptr [eax], 0FFFF00h
	je pwr_start
	cmp dword ptr [eax], 0000000h
	je pwr_start
	cmp dword ptr [eax], 0FEEED6h
	je pwr_start
	mov eax, counter
	mov ebx, 401
	xor edx, edx
	div ebx
	cmp edx, 200
	je life_pwrup
	cmp edx, 300
	je imm_pwrup
	jmp pwr_skip
	
life_pwrup:
	line pwrup_x, pwrup_y, grid_size, grid_size, 0FF0093h
	mov pwrup, 1
	jmp pwr_skip
	
imm_pwrup:
	line pwrup_x, pwrup_y, grid_size, grid_size, 000FFECh
	mov pwrup, 1
pwr_skip:
	ret 
powerUp endp

leftMovement macro entitate
local fail
	mov ebx, entitate.x
	mov ecx, ebx
	sub ebx, 10
	mov entitate.x, ebx
	get_position entitate.x, entitate.y
	mov entitate.x, ecx 
	cmp dword ptr [eax], 0B5B9B5h
	je fail
	cmp dword ptr [eax], 0956E19h
	je fail
	cmp dword ptr [eax], 0FF0000h
	je fail
	
	sub ecx, 40
	mov entitate.x, ecx
	line entitate.lpx, entitate.lpy, 40, 40, 03CA73Ch
	fail:
endm

upMovement macro entitate
local fail
	mov ebx, entitate.y
	mov ecx, ebx
	sub ebx, 5
	mov entitate.y, ebx
	get_position entitate.x, entitate.y
	mov entitate.y, ecx
	cmp dword ptr [eax], 0B5B9B5h
	je fail
	cmp dword ptr [eax], 0956E19h
	je fail
	cmp dword ptr [eax], 0FF0000h
	je fail
	
	sub ecx, 40
	mov entitate.y, ecx
	line entitate.lpx, entitate.lpy, 40, 40, 03CA73Ch
fail:
endm

downMovement macro entitate
local fail
	mov ebx, entitate.y
	mov ecx, ebx
	add ebx, 60
	mov entitate.y, ebx
	get_position entitate.x, entitate.y
	mov entitate.y, ecx
	cmp dword ptr [eax], 0B5B9B5h
	je fail
	cmp dword ptr [eax], 0956E19h
	je fail
	cmp dword ptr [eax], 0FF0000h
	je fail
	
	mov ebx, ecx
	add ebx, 40
	mov entitate.y, ebx
	line entitate.lpx, entitate.lpy, 40, 40, 03CA73Ch
fail:
endm

rightMovement macro entitate
local fail
	mov ebx, entitate.x
	mov ecx, ebx
	add ebx, 60
	mov entitate.x, ebx
	get_position entitate.x, entitate.y
	mov entitate.x, ecx
	cmp dword ptr [eax], 0B5B9B5h
	je fail
	cmp dword ptr [eax], 0956E19h
	je fail
	cmp dword ptr [eax], 0FF0000h
	je fail
	
	mov ebx, ecx
	add ebx, 40
	mov entitate.x, ebx
	line entitate.lpx, entitate.lpy, 40, 40, 03CA73Ch
fail:
endm

bomb_boom macro entitate, scr
local next1, next2, next3, fail, success1, success2, success3, success4, box1, box2, box3, box4, en11, en12, en13, en14, en21, en22, en23, en24, en31, en32, en33, en34, pl1, pl2, pl3, pl4, skip1, skip2, skip3, skip4, keep1
	mov eax, entitate.bmbx
	mov entitate.boomx, eax
	mov eax, entitate.bmby
	mov entitate.boomy, eax
	
	line entitate.bmbx, entitate.bmby, grid_size, grid_size, 03CA73Ch
	xor eax, eax
	mov entitate.currentbmb, eax
	mov entitate.bmbcount, eax
	inc entitate.nobmb
	
	mov ecx, entitate.boomx
	cmp ecx, entitate.x
	jne keep1
	mov ecx, entitate.boomy
	cmp ecx, entitate.y
	jne keep1
	cmp counter, 50
	jl keep1
	cmp player.immunity, 0
	jne keep1
	dec entitate.lives
	
keep1:
	;left
	mov ecx, entitate.boomx
	sub ecx, 10
	mov entitate.boomx, ecx
	get_position entitate.boomx, entitate.boomy
	cmp dword ptr [eax], 0956E19h
	je box1
	cmp dword ptr [eax], 0FFFF00h
	je en11
	cmp dword ptr [eax], 0000000h
	je pl1
	cmp dword ptr [eax], 000FF00h
	je en21
	cmp dword ptr [eax], 00000FFh
	je en31
	jmp next1
box1:
	mov ebx, 50
	add ebx, scr
	mov scr, ebx
	jmp skip1
en11:
	cmp counter, 50
	jl skip1
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy1.lives
	jmp skip1
en21:
	cmp counter, 50
	jl skip1
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy2.lives
	jmp skip1
en31:
	cmp counter, 50
	jl skip1
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy3.lives
	jmp skip1
pl1:
	cmp counter, 50
	jl skip1
	dec player.lives
skip1:
	sub ecx, 30
	mov entitate.boomx, ecx
	line entitate.boomx, entitate.boomy, grid_size, grid_size, 03CA73Ch
	
next1:
	;right
	mov ecx, entitate.bmbx
	add ecx, 50
	mov entitate.boomx, ecx
	get_position entitate.boomx, entitate.boomy
	cmp dword ptr [eax], 0956E19h
	je box2
	cmp dword ptr [eax], 0FFFF00h
	je en12
	cmp dword ptr [eax], 0000000h
	je pl2
	cmp dword ptr [eax], 000FF00h
	je en22
	cmp dword ptr [eax], 00000FFh
	je en32
	jne next2
box2:
	mov ebx, 50
	add ebx, scr
	mov scr, ebx
	jmp skip2
en12:
	cmp counter, 50
	jl skip2
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy1.lives
	jmp skip2
en22:
	cmp counter, 50
	jl skip2
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy2.lives
	jmp skip2
en32:
	cmp counter, 50
	jl skip2
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy3.lives
	jmp skip2
pl2:
	cmp counter, 50
	jl skip2
	dec player.lives
skip2:
	sub ecx, 10
	mov entitate.boomx, ecx
	line entitate.boomx, entitate.boomy, grid_size, grid_size, 03CA73Ch
	
next2:
	;up
	mov ecx, entitate.bmbx
	mov entitate.boomx, ecx
	mov ecx, entitate.boomy
	sub ecx, 10
	mov entitate.boomy, ecx
	get_position entitate.boomx, entitate.boomy
	cmp dword ptr [eax], 0956E19h
	je box3
	cmp dword ptr [eax], 0FFFF00h
	je en13
	cmp dword ptr [eax], 0000000h
	je pl3
	cmp dword ptr [eax], 000FF00h
	je en23
	cmp dword ptr [eax], 00000FFh
	je en33
	jmp next3
box3:
	mov ebx, 50
	add ebx, scr
	mov scr, ebx
	jmp skip3
en13:
	cmp counter, 50
	jl skip3
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy1.lives
	jmp skip3
en23:
	cmp counter, 50
	jl skip3
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy2.lives
	jmp skip3
en33:
	cmp counter, 50
	jl skip3
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy3.lives
	jmp skip3
pl3:
	cmp counter, 50
	jl skip3
	dec player.lives
skip3:
	sub ecx, 30
	mov entitate.boomy, ecx
	line entitate.boomx, entitate.boomy, grid_size, grid_size, 03CA73Ch
	
next3:
	;down
	mov ecx, entitate.bmby
	add ecx, 50
	mov entitate.boomy, ecx
	get_position entitate.boomx, entitate.boomy
	cmp dword ptr [eax], 0956E19h
	je box4
	cmp dword ptr [eax], 0FFFF00h
	je en14
	cmp dword ptr [eax], 0000000h
	je pl4
	cmp dword ptr [eax], 000FF00h
	je en24
	cmp dword ptr [eax], 00000FFh
	je en34
	jmp fail
box4:
	mov ebx, 50
	add ebx, scr
	mov scr, ebx
	jmp skip4
en14:
	cmp counter, 50
	jl skip4
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy1.lives
	jmp skip4
en24:
	cmp counter, 50
	jl skip4
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy2.lives
	jmp skip4
en34:
	cmp counter, 50
	jl skip4
	mov ebx, 200
	add ebx, scr
	mov scr, ebx
	dec enemy3.lives
	jmp skip4
pl4:
	cmp counter, 50
	jl skip4
	dec player.lives
skip4:
	sub ecx, 10
	mov entitate.boomy, ecx
	line entitate.boomx, entitate.boomy, grid_size, grid_size, 03CA73Ch
fail:
endm

bombMovement macro entitate
local iesire
	;daca numarul de bombe pe care le poate plasa jucatorul este 0 atunci sarim
	mov eax, entitate.nobmb
	cmp eax, 0
	je iesire
	
	;daca am apasat butonul de bomba incrementam numarul de bombe plasate pe tabla de joc si decrementam numarul de bombe pe care le poate plasa jucatorul
	inc entitate.currentbmb
	dec entitate.nobmb
	
	;memoram pozitia la care plasam bomba
	mov eax, entitate.x
	mov entitate.bmbx, eax
	mov eax, entitate.y
	mov entitate.bmby, eax
iesire:
endm

boom_compare macro entitate
local iesire
	cmp entitate.currentbmb, 0
	je iesire
	inc entitate.bmbcount
iesire:
endm

verify macro entitate
local continue, finish
	get_position entitate.x, entitate.y
	cmp dword ptr [eax], 0FF0000h
	je continue
	add eax, 50
	cmp dword ptr [eax], 0FF0000h
	je continue
	sub eax, 60
	cmp dword ptr [eax], 0FF0000h
	je continue
	add eax, 10
	sub eax, 4 * area_width
	cmp dword ptr [eax], 0FF0000h
	je continue
	add eax, 161 * area_width
	cmp dword ptr [eax], 0FF0000h
	je continue
	mov eax, 1
	jmp finish
continue:
	xor eax, eax
finish:
endm

getAway macro entitate
local skip
	verify entitate
	cmp eax, 1
	je skip
	leftMovement entitate
	verify entitate
	cmp eax, 1
	je skip
	rightMovement entitate
	verify entitate
	cmp eax, 1
	je skip
	downMovement entitate
	verify entitate
	cmp eax, 1
	je skip
	upMovement entitate
	verify entitate
	cmp eax, 1
	je skip
skip:
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 3
	jz evt_key
	jmp evt_timer
	
evt_click:
	cmp prtmenu, 1
	jne cont_menu
	
	mov eax, [ebp + arg2]
	cmp eax, 310
	jl next_mode1
	cmp eax, 340
	jg next_mode1
	mov eax, [ebp + arg3]
	cmp eax, 245
	jl evt_timer
	cmp eax, 265
	jg next_mode1
	jmp easy_mode
next_mode1:
	mov eax, [ebp + arg2]
	cmp eax, 300
	jl evt_timer
	cmp eax, 350
	jg evt_timer
	mov eax, [ebp + arg3]
	cmp eax, 285
	jg next_mode2
	jmp medium_mode
next_mode2:
	cmp eax, 305
	jg evt_timer
	jmp hard_mode
	
easy_mode:	
	mov enemy_no, 1
	mov prtmenu, 0
	call initializare
	jmp cont_menu
medium_mode:
	mov enemy_no, 2
	mov prtmenu, 0
	call initializare
	jmp cont_menu
hard_mode:
	mov enemy_no, 3
	mov prtmenu, 0
	call initializare
cont_menu:	
	cmp player.lives, 0
	je next_condition
	cmp winner, 1
	je next_condition
	jmp evt_timer
next_condition:
	mov eax, [ebp + arg2]
	cmp eax, 300
	jl evt_timer
	cmp eax, 350
	jg evt_timer
	mov eax, [ebp + arg3]
	cmp eax, 300
	jl evt_timer
	cmp eax, 320
	jg evt_timer
	
	call initializare
	jmp evt_timer
	
evt_key:
	cmp winner, 1
	je afisare_litere
	
	mov ebx, player.x
	mov player.lpx, ebx
	mov ebx, player.y
	mov player.lpy, ebx
	
	mov eax, [ebp + arg2]
	cmp eax, 'A'
	jz left
	cmp eax, 'W'
	jz up
	cmp eax, 'S'
	jz down
	cmp eax, 'D'
	jz right
	cmp eax, ' '
	jz bomb
	
left:
	leftMovement player
	jmp evt_timer
	
up:
	upMovement player
	jmp evt_timer

down:
	downMovement player
	jmp evt_timer
	
right:
	rightMovement player
	jmp evt_timer
	
bomb:
	bombMovement player
	
evt_timer:
	call box_checker
	cmp eax, 1
	je no_winner
	cmp enemy1.lives, 0
	jne no_winner
	cmp enemy_no, 2
	jl oneenemy
	cmp enemy2.lives, 0
	jne no_winner
	cmp enemy_no, 3
	jl oneenemy
	cmp enemy3.lives, 0
	jne no_winner
oneenemy:
	mov winner, 1
	call winning
no_winner:
	cmp prtmenu, 1
	je final_draw
	
	cmp winner, 1
	je afisare_litere
	
	mov eax, counter
	mov ebx, 401
	xor edx, edx
	div ebx
	cmp edx, 200
	je pwrup_et2
	cmp edx, 300
	je pwrup_et2
	
	cmp pwrup, 0
	je no_pwrup
	 
	mov eax, pwrup_x
	cmp player.x, eax
	jne pwrup_et3
	mov eax, pwrup_y
	cmp player.y, eax
	jne pwrup_et3
	
	get_position pwrup_x, pwrup_y
	cmp dword ptr [eax], 0FF0093h
	je pwrup_life
	cmp dword ptr [eax], 000FFECh
	je pwrup_imm
	jmp no_pwrup
	
pwrup_et3:
	inc pwrup_count
	cmp pwrup_count, 60
	jne no_pwrup 
	line pwrup_x, pwrup_y, grid_size, grid_size, 03CA73Ch
	mov pwrup, 0
	mov pwrup_count, 0
	jmp no_pwrup	
	 
pwrup_et2:
	call powerUp
	
	mov eax, counter
	mov ebx, 401
	xor edx, edx
	div ebx
	cmp edx, 200
	jne pwrup_next
	line pwrup_x, pwrup_y, grid_size, grid_size, 0FF0093h
	jmp pwrup_et3
pwrup_next:
	cmp edx, 300
	jne no_pwrup
	line pwrup_x, pwrup_y, grid_size, grid_size, 000FFECh
	jmp no_pwrup
	
pwrup_life:
	inc player.lives
	add score, 25
	mov pwrup_x, 0
	mov pwrup_y, 0
	mov pwrup, 0
	mov pwrup_count, 0
	jmp no_pwrup
	
pwrup_imm:
	mov player.immunity, 100
	add score, 25
	mov pwrup_x, 0
	mov pwrup_y, 0
	mov pwrup, 0
	mov pwrup_count, 0
	jmp no_pwrup
	
no_pwrup:
	mov ebx, enemy1.x
	mov enemy1.lpx, ebx
	mov ebx, enemy1.y
	mov enemy1.lpy, ebx
	
	mov ebx, enemy2.x
	mov enemy2.lpx, ebx
	mov ebx, enemy2.y
	mov enemy2.lpy, ebx
	 
	mov ebx, enemy3.x
	mov enemy3.lpx, ebx
	mov ebx, enemy3.y
	mov enemy3.lpy, ebx
	 
	cmp player.lives, 0
	je afisare_litere
	inc counter
	cmp player.immunity, 0
	je no_immunity
	dec player.immunity
no_immunity:
	mov ebx, 6
	mov eax, counter
	xor edx, edx
	div ebx
	dec ebx
	cmp edx, ebx
	jne skip
	 
	call rand
	
	mov ebx, 5
	xor edx, edx
	div ebx
	cmp edx, 0
	je enemy_left
	cmp edx, 1
	je enemy_up
	cmp edx, 2
	je enemy_right
	cmp edx, 3
	je enemy_down
	cmp edx, 4
	je enemy_bomb
	jmp afisare_litere
	 
enemy_left:
	cmp enemy1.lives, 0
	je nextAliveEnemy1
	leftMovement enemy1
	getAway enemy1
nextAliveEnemy1:
	cmp enemy_no, 2
	jl skip
	cmp enemy2.lives, 0
	je nextAliveEnemy2
	rightMovement enemy2
	getAway enemy2
nextAliveEnemy2:
	cmp enemy_no, 3
	jl skip
	cmp enemy3.lives, 0
	je skip
	upMovement enemy3
	getAway enemy3
	jmp skip
	
enemy_up:
	cmp enemy1.lives, 0
	je nextAliveEnemy3
	upMovement enemy1
	getAway enemy1
nextAliveEnemy3:
	cmp enemy_no, 2
	jl skip
	cmp enemy2.lives, 0
	je nextAliveEnemy4
	upMovement enemy2
	getAway enemy2
nextAliveEnemy4:
	cmp enemy_no, 3
	jl skip
	cmp enemy3.lives, 0
	je skip
	leftMovement enemy3
	getAway enemy3
	jmp skip

enemy_down:
	cmp enemy1.lives, 0
	je nextAliveEnemy5
	downMovement enemy1
	getAway enemy1
nextAliveEnemy5:
	cmp enemy_no, 2
	jl skip
	cmp enemy2.lives, 0
	je nextAliveEnemy6
	downMovement enemy2
	getAway enemy2
nextAliveEnemy6:
	cmp enemy_no, 3
	jl skip
	cmp enemy3.lives, 0
	je skip
	rightMovement enemy3
	getAway enemy3
	jmp skip
	
enemy_right:
	cmp enemy1.lives, 0
	je nextAliveEnemy7
	rightMovement enemy1
	getAway enemy1
nextAliveEnemy7:
	cmp enemy_no, 2
	jl skip
	cmp enemy2.lives, 0
	je nextAliveEnemy8
	leftMovement enemy2
	getAway enemy2
nextAliveEnemy8:
	cmp enemy_no, 3
	jl skip
	cmp enemy3.lives, 0
	je skip
	downMovement enemy3
	getAway enemy3
	jmp skip
	
enemy_bomb:
	cmp enemy1.lives, 0
	je nextAliveEnemy9
	bombMovement enemy1
	getAway enemy1
nextAliveEnemy9:
	cmp enemy_no, 2
	jl skip
	cmp enemy2.lives, 0
	je nextAliveEnemy10
	bombMovement enemy2
	getAway enemy2
nextAliveEnemy10:
	cmp enemy_no, 3
	jl skip
	cmp enemy3.lives, 0
	je skip
	bombMovement enemy3
	getAway enemy3
skip:
	boom_compare player
	boom_compare enemy1
	boom_compare enemy2
	boom_compare enemy3

afisare_litere:
	make_text_macro 'T', area, 50, 10, 0FEEED6h
	make_text_macro 'I', area, 60, 10, 0FEEED6h
	make_text_macro 'M', area, 70, 10, 0FEEED6h
	make_text_macro 'E', area, 80, 10, 0FEEED6h
	numberPrint counter, 50, 30, 0FEEED6h
	
	make_text_macro 'S', area, 560, 10, 0FEEED6h
	make_text_macro 'C', area, 570, 10, 0FEEED6h
	make_text_macro 'O', area, 580, 10, 0FEEED6h
	make_text_macro 'R', area, 590, 10, 0FEEED6h
	make_text_macro 'E', area, 600, 10, 0FEEED6h
	numberPrint score, 565, 30, 0FEEED6h
	
	make_text_macro 'H', area, 450, 10, 0FEEED6h
	make_text_macro 'I', area, 460, 10, 0FEEED6h
	make_text_macro 'S', area, 470, 10, 0FEEED6h
	make_text_macro 'C', area, 480, 10, 0FEEED6h
	make_text_macro 'O', area, 490, 10, 0FEEED6h
	make_text_macro 'R', area, 500, 10, 0FEEED6h
	make_text_macro 'E', area, 510, 10, 0FEEED6h
	
	numberPrint hiScore, 465, 30, 0FEEED6h
	
	make_text_macro 'L', area, 250, 10, 0FEEED6h
	make_text_macro 'I', area, 260, 10, 0FEEED6h
	make_text_macro 'V', area, 270, 10, 0FEEED6h
	make_text_macro 'E', area, 280, 10, 0FEEED6h
	make_text_macro 'S', area, 290, 10, 0FEEED6h
	
	mov eax, player.lives
	add eax, '0'
	make_text_macro eax, area, 270, 30, 0FEEED6h
	
	make_text_macro 'E', area, 340, 10, 0FEEED6h
	make_text_macro 'N', area, 350, 10, 0FEEED6h
	make_text_macro 'E', area, 360, 10, 0FEEED6h
	make_text_macro 'M', area, 370, 10, 0FEEED6h
	make_text_macro 'I', area, 380, 10, 0FEEED6h
	make_text_macro 'E', area, 390, 10, 0FEEED6h
	make_text_macro 'S', area, 400, 10, 0FEEED6h
	
	mov eax, enemy_no
	add eax, '0'
	make_text_macro eax, area, 370, 30, 0FEEED6h
	
	cmp player.immunity, 0
	je cover_immunity
	make_text_macro 'I', area, 130, 10, 0FEEED6h
	make_text_macro 'M', area, 140, 10, 0FEEED6h
	make_text_macro 'M', area, 150, 10, 0FEEED6h
	make_text_macro 'U', area, 160, 10, 0FEEED6h
	make_text_macro 'N', area, 170, 10, 0FEEED6h
	make_text_macro 'I', area, 180, 10, 0FEEED6h
	make_text_macro 'T', area, 190, 10, 0FEEED6h
	make_text_macro 'Y', area, 200, 10, 0FEEED6h

	numberPrint player.immunity, 150, 30, 0FEEED6h
	jmp no_print_immunity
cover_immunity:
	line 90, 10, 120, 40, 0FEEED6h
no_print_immunity:
	cmp player.lives, 0
	je player_dead
	cmp player.immunity, 0
	je cont_no_immunity
	line player.x, player.y, grid_size, grid_size, 0FFFFFFh
	jmp cont_immunity
cont_no_immunity:
	line player.x, player.y, grid_size, grid_size, 0000000h
cont_immunity:
	cmp enemy1.lives, 0
	je no_print_enemy1
	line enemy1.x, enemy1.y, grid_size, grid_size, 0FFFF00h
	cmp enemy1.currentbmb, 0
	je nextenemy2
	cmp enemy1.bmbcount, 25
	je enemy1_boom
	line enemy1.bmbx, enemy1.bmby , grid_size, grid_size, 0FF0000h
	jmp nextenemy2
no_print_enemy1:
	cmp enemy1.currentbmb, 0
	je nextenemy2
	cmp enemy1.bmbcount, 25
	je enemy1_boom
	jmp nextenemy2
enemy1_boom:
	bomb_boom enemy1, aux
nextenemy2:
	cmp enemy_no, 2
	jl nextenemy4
	cmp enemy2.lives, 0
	je no_print_enemy2
	line enemy2.x, enemy2.y, grid_size, grid_size, 000FF00h 
	cmp enemy2.currentbmb, 0
	je nextenemy3
	cmp enemy2.bmbcount, 35
	je enemy2_boom
	line enemy2.bmbx, enemy2.bmby , grid_size, grid_size, 0FF0000h
	jmp nextenemy3
no_print_enemy2:
	cmp enemy2.currentbmb, 0
	je nextenemy3
	cmp enemy2.bmbcount, 35
	je enemy2_boom
	jmp nextenemy3
enemy2_boom:
	bomb_boom enemy2, aux
nextenemy3:
	cmp enemy_no, 3
	jl nextenemy4
	cmp enemy3.lives, 0
	je no_print_enemy3
	line enemy3.x, enemy3.y, grid_size, grid_size, 00000FFh 
	cmp enemy3.currentbmb, 0
	je nextenemy4
	cmp enemy3.bmbcount, 45
	je enemy3_boom
	line enemy3.bmbx, enemy3.bmby , grid_size, grid_size, 0FF0000h
	jmp nextenemy4
no_print_enemy3:
	cmp enemy3.currentbmb, 0
	je nextenemy4
	cmp enemy3.bmbcount, 45
	je enemy3_boom
	jmp nextenemy4
enemy3_boom:
	bomb_boom enemy3, aux
nextenemy4:
	cmp player.currentbmb, 0
	je final_draw
	cmp player.bmbcount, 15
	je boom

	line player.bmbx, player.bmby , grid_size, grid_size, 0FF0000h
	jmp final_draw
boom:
	bomb_boom player, score
	cmp player.lives, 0
	je player_dead
	jmp final_draw
	
player_dead:
	cmp scr_write, 0
	jne cont_death
	push offset mode_write
	push offset file_name
	call fopen 
	add esp, 8
	mov esi, eax
	
	push score
	push offset format_d
	push esi
	call fprintf
	add esp, 12
	
	inc scr_write
	
	push esi
	call fclose
	add esp, 4
	
cont_death:
	mov ecx, score
	cmp ecx, hiScore
	jl cont_death1
	mov hiScore, ecx
cont_death1:
	line 250, 200, 160, 140, 09E9E9Eh 
	make_text_macro 'G', area, 285, 230, 09E9E9Eh
	make_text_macro 'A', area, 295, 230, 09E9E9Eh
	make_text_macro 'M', area, 305, 230, 09E9E9Eh
	make_text_macro 'E', area, 315, 230, 09E9E9Eh
	make_text_macro 'O', area, 335, 230, 09E9E9Eh
	make_text_macro 'V', area, 345, 230, 09E9E9Eh
	make_text_macro 'E', area, 355, 230, 09E9E9Eh
	make_text_macro 'R', area, 365, 230, 09E9E9Eh
	make_text_macro 'S', area, 280, 250, 09E9E9Eh
	make_text_macro 'C', area, 290, 250, 09E9E9Eh
	make_text_macro 'O', area, 300, 250, 09E9E9Eh
	make_text_macro 'R', area, 310, 250, 09E9E9Eh
	make_text_macro 'E', area, 320, 250, 09E9E9Eh
	numberPrint score, 340, 250, 09E9E9Eh
	make_text_macro 'T', area, 285, 270, 09E9E9Eh
	make_text_macro 'I', area, 295, 270, 09E9E9Eh
	make_text_macro 'M', area, 305, 270, 09E9E9Eh
	make_text_macro 'E', area, 315, 270, 09E9E9Eh
	numberPrint counter, 335, 270, 09E9E9Eh
	make_text_macro 'R', area, 300, 300, 09E9E9Eh
	make_text_macro 'E', area, 310, 300, 09E9E9Eh
	make_text_macro 'P', area, 320, 300, 09E9E9Eh
	make_text_macro 'L', area, 330, 300, 09E9E9Eh
	make_text_macro 'A', area, 340, 300, 09E9E9Eh
	make_text_macro 'Y', area, 350, 300, 09E9E9Eh
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	
	call initializare
	call initializare
	call initializare
	
	call menu
	
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
