.386
instructions SEGMENT use16
    x dw ? ; variable used in 'draw_square' function
    y dw ? ; variable used in 'draw_square' function
    x_head dw 144 ; x position of the head
    y_head dw 88 ; y position of the head
    x_point dw 104 ; x position of a point
    y_point dw 32 ; y position of a point
    tail_size dw 1 
    x_tail dw  144
        dw 1000 dup (?) ; an array of x positions of snake parts (first one is the head)
    y_tail dw  88
        dw 1000 dup (?) ; an array of y positions of snake parts (first one is the head)
    unit dw 8 ; size of a square wall (in pixels)
    color db ? ; variable used in 'draw_square' function
    green db 2
    light_green db 10
    black db 0
    red db 4
    direction db 0 ; the direction in which the snake is moving 
    counter db 0 ; frame counter used to 'slow down' the snake
    if_ended db 0 ; variable used to determine if the game has ended
    random_factor dw 5 ; variable used to create a random number

ASSUME cs:instructions

clock_interrupt PROC
    push ax
    push bx
    push es
    push cx
    mov ax, 0A000H
    mov es, ax

    ;the snake moves every 3 ticks 
    inc cs:counter
    cmp cs:counter, 3  
    jne tutaj2
    mov cs:counter,0

    ;loading head position in the first elements of 'x_tail' and 'y_tail'
    mov ax, cs:x_head
    mov cs:x_tail[0], ax
    mov ax, cs:y_head
    mov cs:y_tail[0], ax

    ;checking if head is the only part of the snake
    mov cx, cs:tail_size
    cmp cx, 0
    je et

    ;shifting every element by one position in the array
    mov bx, cx
    shl bx,1 ; every element is 2 bytes
ptl:
    mov ax, cs:x_tail[bx-2]
    mov cs:x_tail[bx], ax
    mov ax, cs:y_tail[bx-2]
    mov cs:y_tail[bx], ax
    sub bx, 2
    loop ptl
et:
    ;deleting a square on the last position
    mov cx, cs:tail_size
    shl cx, 1
    mov bx, cx
    mov ax, cs:x_tail[bx]
    mov cs:x, ax
    mov ax, cs:y_tail[bx]
    mov cs:y, ax
    call delete_square

    ;moving the snake
    cmp cs:direction, 0
    je prawo
    cmp cs:direction,1
    je lewo
    cmp cs:direction, 2
    je gora
    cmp cs:direction, 3
    je dol

prawo:
    call move_right
    jmp dalej
lewo:
    call move_left
    jmp dalej
gora:
    call move_up
    jmp dalej
dol:
    call move_down
    jmp dalej
dalej:
    ;checking if any collision occurred
    call check_wall_collision
    call check_snake_collision

    ;drawing head in the new position
    call draw_head
tutaj:
    call draw_point
skok:
    mov bx, cs:x_head
    cmp bx, cs:x_point
    jne tutaj2
    mov bx, cs:y_head
    cmp bx, cs:y_point
    jne tutaj2
    ;mov cs:koniec, 1 
    ;----POINT----
    inc cs:tail_size
    mov ax, cs:x_point
    mov bx, cs:y_point
    mov cs:x, ax
    mov cs:y, bx
    mov al, cs:green
    mov cs:color, al
    call draw_square

    call find_new_point
tutaj2:
    pop cx
    pop es
    pop bx
    pop ax
    ; skok do oryginalnego podprogramu obsługi przerwania
    ; zegarowego
    jmp dword PTR cs:wektor8
    ; zmienne procedury
    wektor8 dd ?
clock_interrupt ENDP

find_new_point PROC
    push bx
    push ax
start_looking:
    call random           ; Wygeneruj nowe wartości x_point i y_point
    mov bx, cs:tail_size  ; Liczba elementów w tablicy
    shl bx, 1             ; Rozmiar w bajtach (każda wartość 16-bitowa)

check_all:
    mov ax, cs:x_point
    cmp ax, cs:x_tail[bx-2] ; Porównaj x_point z wartością w x_tail
    jne next_element        ; Jeśli różne, sprawdź kolejny element
    mov ax, cs:y_point
    cmp ax, cs:y_tail[bx-2] ; Porównaj y_point z wartością w y_tail
    jne next_element        ; Jeśli różne, sprawdź kolejny element
    inc cs:random_factor
    jmp start_looking
next_element:
    sub bx, 2               ; Przejdź do poprzedniego elementu
    cmp bx, 0               ; Czy są jeszcze elementy do sprawdzenia?
    jge check_all           ; Jeśli tak, kontynuuj sprawdzanie

    pop ax
    pop bx
    ret                     ; Zakończ i zwróć nowe wartości

find_new_point ENDP

random proc
    push ax
    push cx
    push dx
    ; --- Uzyskanie pseudolosowej liczby ---
    mov ah, 0           ; Funkcja BIOS: odczyt czasu
    int 1Ah             ; Wynik w rejestrach CX:DX (CX - godzina, DX - licznik)
    xor ax, dx          ; Mieszanie bitów (prosta metoda pseudolosowości)
    xor ax, cs:random_factor

    ; --- Ograniczenie do przedziału 0–40 ---
    mov cx, 40          ; Górna granica +1 (0–40)
    xor dx, dx          ; Wyzerowanie DX
    div cx              ; AX / CX, reszta w DX
    mov ax, dx          ; Przenieś resztę (DX) do AX

    ; --- Przemnożenie przez 8 ---
    shl ax, 3           ; Przesunięcie w lewo o 3 bity (AX = AX * 8)
    mov cs:x_point, ax

     mov ah, 0           ; Funkcja BIOS: odczyt czasu
    int 1Ah             ; Wynik w rejestrach CX:DX (CX - godzina, DX - licznik)
    xor ax, dx          ; Mieszanie bitów (prosta metoda pseudolosowości)

    ; --- Ograniczenie do przedziału 0–25 ---
    mov cx, 25          ; Górna granica (25 + 1)
    xor dx, dx          ; Wyzerowanie DX
    div cx              ; AX / CX, reszta w DX
    mov ax, dx          ; Przenieś resztę (DX) do AX (0–25)

    ; --- Przemnożenie przez 8 ---
    shl ax, 3           ; Przesunięcie w lewo o 3 bity (AX = AX * 8)
    mov cs:y_point, ax 

    pop dx
    pop cx
    pop ax
    ret                 ; Zakończenie funkcji, wynik w AX
random endp

check_wall_collision PROC
    cmp x_head, 0
    jl zakoncz
    cmp x_head, 320
    je zakoncz
    cmp y_head, 0
    jl zakoncz
    cmp y_head, 200
    je zakoncz
    jmp no_col
zakoncz:
    mov cs:if_ended, 1
no_col:
    ret
check_wall_collision ENDP

check_snake_collision PROC
    push bx
    push ax

    mov bx, cs:tail_size  ; Liczba elementów w tablicy
    shl bx, 1             ; Rozmiar w bajtach (każda wartość 16-bitowa)

check:
    mov ax, cs:x_head
    cmp ax, cs:x_tail[bx-2] ; Porównaj x_point z wartością w x_tail
    jne next        ; Jeśli różne, sprawdź kolejny element
    mov ax, cs:y_head
    cmp ax, cs:y_tail[bx-2] ; Porównaj y_point z wartością w y_tail
    jne next        ; Jeśli różne, sprawdź kolejny element
    mov cs:if_ended, 1
    jmp done
next:
    sub bx, 2               ; Przejdź do poprzedniego elementu
    cmp bx, 0               ; Czy są jeszcze elementy do sprawdzenia?
    jg check           ; Jeśli tak, kontynuuj sprawdzanie
done:
    pop ax
    pop bx
    ret          

check_snake_collision ENDP


move_right PROC
    add cs:x_head,8
    ret
move_right ENDP

move_left PROC
    sub cs:x_head,8
    ret
move_left ENDP

move_right_point PROC
    add cs:x_point,8
    ret
move_right_point ENDP

move_left_point PROC
    sub cs:x_point,8
    ret
move_left_point ENDP

move_up PROC
    sub cs:y_head,8
    ret
move_up ENDP

move_down PROC
    add cs:y_head,8
    ret
move_down ENDP

point PROC
    inc cs:tail_size
point ENDP

draw_square PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    ; Ustaw segment pamięci wideo
    mov ax, 0A000h     
    mov es, ax

    ; Setting color
    mov al, cs:color

    ; Rysowanie kwadratu - pętla zewnętrzna dla wierszy
    mov bx, cs:y          ; BX = aktualna współrzędna Y (wiersz)
    mov di, cs:x          ; DI = początkowa współrzędna X
    mov dx, cs:unit           ; DX = liczba wierszy (wysokość kwadratu)
    dec dx
outer_loop:
    push dx             ; Zachowaj licznik wierszy
    push bx             ; Zachowaj bieżący wiersz

    ; Oblicz adres początkowy wiersza
    mov ax, bx          ; AX = aktualna współrzędna Y
    mov bx, 320         ; Szerokość ekranu w pikselach
    mul bx              ; AX = Y * 320
    add ax, di          ; Dodaj X do adresu
    mov bx, ax          ; BX = początkowy adres w pamięci wideo

    ; Rysowanie wiersza - pętla wewnętrzna dla pikseli
    mov dx, cs:unit          ; DX = liczba pikseli w wierszu (szerokość kwadratu)
    dec dx
inner_loop:
    mov al, cs:color
    mov es:[bx], al     ; Narysuj piksel w pamięci wideo
    inc bx              ; Przesuń do następnego piksela
    dec dx              ; Zmniejsz licznik pikseli
    jnz inner_loop      ; Jeśli są jeszcze piksele, kontynuuj

    pop bx              ; Przywróć współrzędną Y
    inc bx              ; Przejdź do następnego wiersza
    pop dx              ; Przywróć licznik wierszy
    dec dx              ; Zmniejsz licznik wierszy
    jnz outer_loop      ; Jeśli są jeszcze wiersze, kontynuuj

    ; Przywróć rejestry
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret
draw_square ENDP

draw_point PROC
    push bx
    push ax

    mov cs:color, 4 ; red
    mov bx, cs:x_point
    mov ax, cs:y_point
    mov cs:x, bx
    mov cs:y, ax
    call draw_square

    pop ax
    pop bx
    ret
draw_point ENDP

draw_head PROC
    push bx
    push ax

    mov al, cs:light_green
    mov cs:color, al 
    mov bx, cs:x_head
    mov ax, cs:y_head
    mov cs:x, bx
    mov cs:y, ax
    call draw_square

    pop ax
    pop bx
    ret
draw_head ENDP

delete_square PROC
    push bx
    push ax

    mov cs:color, 0 ; black
    call draw_square

    pop ax
    pop bx
    ret
delete_square ENDP


; INT 10H, funkcja nr 0 ustawia tryb sterownika graficznego
zacznij:
    mov ah, 0
    mov al, 13H ; nr trybu
    int 10H
    mov bx, 0
    mov es, bx ; zerowanie rejestru ES
    mov eax, es:[32] ; odczytanie wektora nr 8
    mov cs:wektor8, eax; zapamiętanie wektora nr 8
    ; adres procedury 'linia' w postaci segment:offset
    mov ax, SEG clock_interrupt
    mov bx, OFFSET clock_interrupt
    cli ; zablokowanie przerwań
    ; zapisanie adresu procedury 'linia' do wektora nr 8
    mov es:[32], bx
    mov es:[34], ax
    sti ; odblokowanie przerwań

    call draw_head

    call draw_point
czekaj:
    cmp cs:if_ended, 1
    je quit
    mov ah, 1 ; sprawdzenie czy jest jakiś znak
    int 16h ; w buforze klawiatury
    jz czekaj

    mov ah, 0
    int 16h

    cmp al, 27
    je quit
    cmp al, 'w'
    je kierunek_gora
    cmp al, 's'
    je kierunek_dol
    cmp al, 'd'
    je kierunek_prawo
    cmp al, 'a'
    je kierunek_lewo
    jmp czekaj
kierunek_gora:
    mov cs:direction, 2
    jmp czekaj

kierunek_dol:
    mov cs:direction, 3
    jmp czekaj

kierunek_lewo:
    mov cs:direction, 1
    jmp czekaj

kierunek_prawo:
    mov cs:direction, 0
    jmp czekaj

quit:
    mov ah, 0 ; funkcja nr 0 ustawia tryb sterownika
    mov al, 3H ; nr trybu
    int 10H
; odtworzenie oryginalnej zawartości wektora nr 8
    mov eax, cs:wektor8
    mov es:[32], eax

; zakończenie wykonywania programu
    mov ax, 4C00H
    int 21H

instructions ENDS

stosik SEGMENT stack
dw 256 dup (?)
stosik ENDS
END zacznij