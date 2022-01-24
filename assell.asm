dseg	segment
	;d1, d2, h0, sn ,sd.
	
	d1a dw ?
	d1b dw ?		; a is the least significant word, b is the most significant word.
	d2a dw ?		
	d2b dw ?		
	h0a dw ?		
	h0b dw ?		
	sna dw ?		
	snb dw ?
	sda dw ?
	sdb dw ?
	
	aradius dw 200		
	bradius dw 100
	xdynamic dw ?
	ydynamic dw ?
	
	a2a dw ?
	a2b dw ?
	eighta2a dw ?
	eighta2b dw ?
	b2a dw ?
	b2b dw ?
	eightb2a dw ?
	eightb2b dw ?
	
	placeholder1a dw ?
	placeholder1b dw ?
	placeholder2a dw ?
	placeholder2b dw ?
	
	eightba2a dw ?
	eightba2b dw ?
	
	center0 dw 320 		; Center of the board
	center1 dw 240
	
	dseg	ends
	
sseg segment stack

	dw 20h dup(?)

sseg ends
		
	
cseg	segment
assume	cs:cseg,	ds:dseg

Drawpixel macro
		mov ah, 0ch
		mov al, 15
		mov bh, 0
		
		mov cx, center0
		mov dx, center1
		add cx, xdynamic
		sub dx, ydynamic
		int 10h
		
		mov cx, center0
		mov dx, center1
		add cx, xdynamic
		add dx, ydynamic
		int 10h
		
		mov cx, center0
		mov dx, center1
		sub cx, xdynamic
		add dx, ydynamic
		int 10h
		
		mov cx, center0
		mov dx, center1
		sub cx, xdynamic
		sub dx, ydynamic
		int 10h
endm

TakeInput macro Shoov, Skip, CheckUpper, GoOn
		mov cx, 0		
Shoov:	mov bx, 0
		mov ah, 1h
		int 21h		; Read character from keyboard
		cmp al, 0dh		; Checking whether the character is 'enter'
		jz Skip
		cmp al, 30h
		jnb CheckUpper
		
		mov ah, 2h						; This segment is dedicated to deleting an invalid character.
		mov dl, 8h 	; backspace
		int 21h
		mov dl, 20h	; space
		int 21h
		mov dl, 8h
		int 21h
		jmp Shoov
		
CheckUpper:	cmp al, 39h
		jna GoOn		; Checking whether it's in the bounds of 0-9, i.e whether it's a number.
		
		mov ah, 2h						; This segment is dedicated to deleting an invalid character.
		mov dl, 8h 	; backspace
		int 21h
		mov dl, 20h	; space
		int 21h
		mov dl, 8h
		int 21h
		jmp Shoov
		
GoOn:	sub al, 30h
		mov bl, al
		mov ax, 10
		mul cx			; ax = 10*cx
		mov cx, ax
		add cx, bx		; cx = cx + bx = cx + al
		jmp Shoov
endm

ShowRadius macro
		mov dl, 'R'
		int 21h
		mov dl, 'a'
		int 21h
		mov dl, 'd'
		int 21h
		mov dl, 'i'
		int 21h
		mov dl, 'u'
		int 21h
		mov dl, 's'
		int 21h
		mov dl, 3ah		; 3ah = :
		int 21h
		mov dl, 20h		; space
		int 21h
endm

arithmetic32 macro	Upper1, Lower1, Upper2, Lower2, addorsub, adcorsbb		; Result: Upper2 = Upper2 +- Upper1, Lower2 = Lower2 +- Lower1. Upper2/Lower2 are the destinations. Take everything from dseg
		mov bx, Upper1
		mov ax, Lower1
		addorsub Upper2, bx
		addorsub Lower2, ax
		adcorsbb Upper2, 0
endm



Start:	mov ax, dseg
		mov ds, ax
		
		; Getting user input
	
	
		; Message for choosing aradius
		
Restart:	mov ah, 2h
		mov dl, 'H'
		int 21h
		mov dl, 'o'
		int 21h
		mov dl, 'r'
		int 21h
		mov dl, 'i'
		int 21h
		mov dl, 'z'
		int 21h
		mov dl, 'o'
		int 21h
		mov dl, 'n'
		int 21h
		mov dl, 't'
		int 21h
		mov dl, 'a'
		int 21h
		mov dl, 'l'
		int 21h
		mov dl, 20h		; 20h = space
		int 21h
		ShowRadius
		
		
		mov dl, 0ah		; 0ah = newline				This segment is dedicated to deleting the DosBox feed and positioning the cursor
		mov cl, 24
Clear:	int 21h
		loop Clear
		mov ah, 2
		mov bh, 0
		mov dh, 0
		mov dl, 19
		int 10h			; Jump to the 20th character, where the user will input the number
		
		
		TakeInput Shoov1, Vertical, CheckUpper1, GoOn1
				
				
		; Message for choosing bradius
		
Vertical:	mov aradius, cx
			mov ah, 2
			mov dl, 0ah
			int 21h
		
		mov dl, 'V'
		int 21h
		mov dl, 'e'
		int 21h
		mov dl, 'r'
		int 21h
		mov dl, 't'
		int 21h
		mov dl, 'i'
		int 21h
		mov dl, 'c'
		int 21h
		mov dl, 'a'
		int 21h
		mov dl, 'l'
		int 21h
		mov dl, 20h		; 20h = space
		int 21h
		ShowRadius
		
								
		TakeInput Shoov2, Done, CheckUpper2, GoOn2
				
		
Done:	mov bradius, cx

		;Setting video mode
		mov ah, 0
		mov al, 12h
		int 10h

		
		; This part is where all of the precalculations are done.
		
		
		;Calculating d1
		mov ax, bradius
		mov bx, 3
		mul bx	; ax = 3b. No need to use the upper 16-bit number.
		mov bx, bradius
		shl bx, 2	; bx = 4b
		mul bx		; ax = 12*b^2
		mov d1b, dx
		mov d1a, ax
		
		;Calculating sn & b2 & 8b2
		mov ax, bradius
		mov bx, bradius
		mul bx			; dx:ax = b^2
		mov snb, dx
		mov sna, ax
		mov b2b, dx	
		mov b2a, ax
		mov ax, bradius			;This sort of thing is the same as multiplying by 8. bx already has a value of bradius.
		shl ax, 2
		shl bx, 1
		mul bx
		mov eightb2b, dx
		mov eightb2a, ax
		
		;Calculating a2 & 8a2
		mov ax, aradius
		mov bx, aradius
		mul bx			;dx:ax = a^2
		mov a2b, dx
		mov a2a, ax
		mov ax, aradius
		mov bx, aradius			;This sort of thing is the same as multiplying by 8.
		shl ax, 2		;ax = 4a
		shl bx, 1		;bx = 2a
		mul bx			;dx:ax = 8a^2
		mov eighta2b, dx
		mov eighta2a, ax
		
		
		;Calculating d2
		mov ax, eighta2a
		mov bx, eighta2b
		mov placeholder1a, ax
		mov placeholder1b, bx	;placeholder1 = 8a^2
		
		mov ax, bradius
		mov bx, aradius
		mul bx		; ax = a*b. No need to pay attention to dx, because a*b should fit in 16 bits.
		mov cx, ax	; cx = a*b
		mov ax, aradius
		shl ax, 3	; ax = 8a
		mul cx		; dx:ax = 8b*a^2
		
		mov eightba2b, dx
		mov eightba2a, ax
		
		sub placeholder1b, dx
		sub placeholder1a, ax	; placeholder1 - placeholder2 = 8a^2 - 8*b*a^2
		sbb placeholder1b, 0
		mov ax, placeholder1a
		mov bx, placeholder1b
		mov d2a, ax
		mov d2b, bx
		
		;Calculating sd
		mov ax, bradius
		mov bx, aradius
		mul bx		;ax = a*b. It is assumed that this fits in 16 bits.
		mul bx		;dx:ax = b*a^2
		mov placeholder1b, dx
		mov placeholder1a, ax		; placeholder1 = b*a^2
		
		mov ax, aradius
		mov bx, aradius
		mul bx		; dx:ax = a^2
		shr dx, 1
		rcr ax, 1	; dx:ax = 1/2*a^2
		
		sub placeholder1b, dx
		sub placeholder1a, ax
		sbb placeholder1b, 0		; placeholder1 = b*a^2 - 1/2*a^2
		mov ax, placeholder1a
		mov bx, placeholder1b
		mov sdb, bx
		mov sda, ax
		
		;Calculating h0
		mov ax, bradius
		mov bx, bradius
		shl ax, 1
		shl bx, 1	; Multiplication by 2
		mul bx		; dx:ax = 4b^2
		mov placeholder1b, dx
		mov placeholder1a, ax	; placeholder1 = 4b^2
		
		mov bx, eightba2b
		mov ax, eightba2a
		shr bx, 1
		rcr ax, 1	; bx:ax = 4b*a^2
		
		sub placeholder1b, bx
		sub placeholder1a, ax
		sbb placeholder1b, 0	; placeholder1 = 4b^2 - 4b*a^2
		
		mov bx, a2b
		mov ax, a2a
		add placeholder1b, bx
		add placeholder1a, ax
		adc placeholder1b, 0	; placeholder1 = 4b^2 + a^2 - 4b*a^2
		mov bx, placeholder1b
		mov ax, placeholder1a
		mov h0b, bx
		mov h0a, ax
		jmp StartAlgorithm
		
																Restart3:	jmp Restart		
			
		; The algorithm
		
StartAlgorithm:			
		mov ax, aradius
		mov bx, bradius
		mov xdynamic, 0
		mov ydynamic, bx	; Initializing x and y
		
		; Coloring the edges
		mov ah, 0ch
		mov al, 15
		mov bh, 0
		mov cx, center0
		mov dx, center1
		add cx, aradius
		dec cx
		int 10h
		mov cx, center0
		sub cx, aradius
		inc cx
		int 10h
		mov cx, center0
		add dx, bradius
		int 10h
		mov dx, center1
		sub dx, bradius
		int 10h
		
		
snsmallerthansd:	mov bx, snb
		mov ax, sna
		mov dx, sdb
		mov cx, sda
		cmp bx, dx
		jg snbiggerthansd1
		jl Continue
		cmp ax, cx
		jae snbiggerthansd1	; Checking whether sn < sd
		
Continue:	mov bx, h0b
		add bx, 0
		js h0isnegative			; Checking whether h0 > 0
		
		dec ydynamic			; y--
		
		arithmetic32 d2b, d2a, h0b, h0a, add, adc	; h0 += d2
				arithmetic32 a2b, a2a, sdb, sda, sub, sbb	; sd -= a^2
				arithmetic32 eighta2b, eighta2a, d2b, d2a, add, adc	; d2 += 8a^2
		
		h0isnegative:	inc xdynamic	; x++

		arithmetic32 d1b, d1a, h0b, h0a, add, adc	; h0 += d1
		
		jmp Next1
				
										snbiggerthansd1:	inc ydynamic
															jmp snbiggerthansd
																				
										Restart2:	jmp Restart3					
															
Next1:	arithmetic32 b2b, b2a, snb, sna, add, adc	; sn += b^2
		arithmetic32 eightb2b, eightb2a, d1b, d1a, add, adc	; d1 += 8b^2
		
				
		; Coloring the pixel
		Drawpixel
		
		jmp snsmallerthansd 	; Coming back to the start of the loop, and checking whether sn < sd.
								
									Restart1: jmp Restart2		
								
snbiggerthansd:	cmp ydynamic, 1
		je Sof1				; Checking whether y > 0.
		
		mov bx, h0b
		add bx, 0
		jns h0ispositive		
		
		inc xdynamic	; x++
		
		arithmetic32 d1b, d1a, h0b, h0a, add, adc	; h0 += d1
		arithmetic32 eightb2b, eightb2a, d1b, d1a, add, adc	; d1 += 8b^2
		
		
h0ispositive:	dec ydynamic	; y--
		
		arithmetic32 d2b, d2a, h0b, h0a, add, adc	; h0 += d2
		arithmetic32 eighta2b, eighta2a, d2b, d2a, add, adc	; d2 += 8a^2
		jmp Next2
								
										Sof1:	jmp Sof
										Restart0: jmp Restart1										
		; Coloring the pixel
Next2:	Drawpixel
		
		jmp snbiggerthansd


	

Sof:	mov ah, 1h		; Restarting the program if the user presses 'escape'.
		int 21h
		cmp al, 1bh		; escape
		jz Restart0
		
		
Testo:	int 3
cseg	ends
end		Start