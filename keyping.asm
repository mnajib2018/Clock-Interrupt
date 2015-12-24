;Muhammad Najib
;KeyPing.asm
;LAB6
;November 2,2015
;The program installs Clock and Keyboard
;interrupts to print clock on the screen

.model tiny
.stack 200h
.386

.code

ORG 100h

start:
	jmp setup

right_shift	EQU 01h
left_shift	EQU 02h
HANDLER	    EQU 09h
TIME_HANDLE EQU 01Ch
mystring   BYTE  "Clock Already installed",0
Empty_String BYTE "        ",0
Tick_Counter BYTE 0
Tick_Limit EQU 18
ClockHandle_CallCount WORD 0
Clock_Printed BYTE 0
SECONDS BYTE  00h
MINUTES BYTE  00h
HOURS   BYTE  00h
UNINSTALL BYTE 0

getcursor PROC
;PRE:takes ah as the function number
;POST: return row and col in dh and dl
	push ax
	push bx

	mov ah,3
	mov bh,0
	int 10h

	pop ax
	pop bx
	ret
getcursor ENDP

movecursor PROC
;PRE:Takes ah as the function number,bh as page number
;and dh and dl as row and col respectively
;POST: moves the cursor ahead by one col
	push ax
	push bx
	push cx
	push dx

	call getcursor
	mov ah,2
	mov bh,0
	inc dl
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax
	ret
movecursor ENDP

setcursor PROC
;PRE: Takes ah as function number, bh as video mode
;POST: sets the cursor at position dh,dl
	push ax
	push bx
	push cx
	push dx

	mov ah,2
	mov bh,0
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax
	ret
setcursor ENDP

get_time_handler PROC
;PRE:Initialise es to zero
;POST:ax as OFFSET of Time Handle
;and dx as SEG of Time Handle
	pushf
	CLI

	xor ax,ax
	mov es,ax
	mov ax,WORD ptr es:[4*TIME_HANDLE]
	mov dx,WORD ptr es:[4*TIME_HANDLE+2]

	STI
	popf
	ret
get_time_handler ENDP

getkey_handler PROC
;PRE:Initialize es to zero
;POST:moves OFFSET of keyboard interrupt in ax
;and SEG of keyboard interrupt in dx
	pushf
	CLI
	xor ax,ax
	mov es,ax
	mov ax,WORD ptr es:[4*HANDLER]
	mov dx,WORD ptr es:[4*HANDLER+2]
	STI
	popf
	ret
getkey_handler ENDP

install_timehandle PROC
;PRE: Takes the SEG and Offset of our interrupt function
;POST: Places the Offset and SEG of our function
;in interrupt no 1Ch  
	pushf
	CLI
	mov ax,OFFSET cs:[Clock_Interrupt]
	mov dx,SEG cs:[Clock_Interrupt]
	mov word ptr es:[4*Time_Handle],ax
	mov word ptr es:[4*Time_Handle+2],dx
	STI
	popf
	ret
install_timehandle ENDP

installkey_handler PROC
;PRE: Takes the SEG and OFFSET of our function 
;and places it in ax and dx
;POST: Places OFFSET and SEG in interrupt 09h
	pushf
	CLI
	mov ax, OFFSET cs:[int9_handler]
	mov dx, SEG cs:[int9_handler]
	mov word ptr es:[4*HANDLER],ax
	mov word ptr es:[4*HANDLER+2],dx
	STI
	popf
	ret
installkey_handler ENDP

printmystring PROC
;PRE: ax takes the offset of the string to be printed
;al holds the ascii value,bx video mode,ah function code,
;cx holds the no of times to print
;POST; String is printed at the cursor position
	push ax
	push bx
	push cx
	push si
	mov si,ax
P1:
	mov al,byte ptr [si]
	mov bx,0
	mov ah,0Ah
	mov bh,00h
	mov cx,1h
	int 10h	
	call movecursor
	inc si	
	cmp byte ptr [si],0
	ja P1

	pop si
	pop cx
	pop bx
	pop ax
	ret
printmystring ENDP

Write_Hex PROC
;PRE:ax holds the number to be printed
;POST: the hex value is printed on to the screen
	push ax
	push bx
	push cx
	push dx

;push the value on stack and shift right by four
;to output the left digit first
;add 30h to get ASCII value
	push ax
	mov cl,4
	shr al,cl
	add al,30h
	mov bh,00h	
	mov cx,1
	mov ah,0Ah
	int 10h

;move cursor to print the next digit
	call movecursor

;Take ax value from stack and use and operation
;to get the right digit. Add 30h and output the value
	pop ax
	and al,0Fh
	add al,30h
	mov cx,1
	mov bh,00h
	mov ah,0Ah
	int 10h
	
	pop dx
	pop cx
	pop bx
	pop ax	
	ret
Write_Hex ENDP

Get_System_Time PROC
;PRE:cx holds the value of the hours and mins
;dx holds the value of seconds
;ah holds the function code and 1Ah is the DOS function
;POST: variable of each time unit hold their respective values
	push ax
	push bx
	push cx
	push dx

	mov cx,0	
	mov dx,0
	mov ah,02h	
	int 1Ah
	mov cs:[HOURS],ch
	mov cs:[MINUTES],cl
	mov cs:[SECONDS],dh
	pop dx
	pop cx
	pop bx
	pop ax
	ret
Get_System_Time ENDP

printcolon PROC
;PRE:al holds the ASCII value of colon, cx holds the no of times to print
;bh video mode and ah the function code
;POST:Colon gets printed on the screen
	push ax
	push bx
	push cx

	mov al,3Ah
	mov cx,1
	mov bh,00h
	mov ah,0Ah
	int 10h

	pop ax
	pop bx
	pop cx
	ret
printcolon ENDP

cursor_row BYTE 0
cursor_col BYTE 0

Print_Clock PROC
;PRE: Takes HOURS, MINUTES and SECONDS as variables for time 
;POST: Prints the clock 
	push ax
	push bx
	push cx
	push dx

;Get cursor position and save it; 
	call getcursor
	mov cs:[cursor_row],dh
	mov cs:[cursor_col],dl

;Set cursor to clock position
	mov dh,0
	mov dl,71
	call setcursor

;Write down each time variable seperated by colons
	mov ax,0
	mov al, cs:[HOURS]
	call Write_Hex
	call movecursor

	call printcolon
	call movecursor
	mov al,cs:[MINUTES]
	call Write_Hex
	call movecursor

	call printcolon
	call movecursor
	mov al,cs:[SECONDS]
	call Write_Hex
	call movecursor

;Move cursor back to original position
	mov dh, cs:[cursor_row]
	mov dl, cs:[cursor_col]
	call setcursor

	pop dx
	pop cx
	pop bx
	pop ax
	ret
Print_Clock ENDP

Clock_Interrupt PROC
;PRE: Takes the Tick_Counter value
;POST: Prints the clock on 18th tick
	cli
	pushf
	push es
	push ax
	push di

;Move the code segment in data segment
	mov ax,cs
	mov ds,ax

;Increment Total Ticks since last sec and also overall
	inc cs:[ClockHandle_CallCount]
	inc cs:[Tick_Counter]

;Get system time 18 times per second
	call Get_System_Time
	cmp cs:Tick_Counter,18
	jb done
;if 18 ticks print the clock if shifts pressed and reset variables
	mov cs:[Tick_Counter],0
	cmp cs:[Clock_Printed],0
	je done
	call Print_Clock

done:
	pop di
	pop ax
	pop es
	popf
	jmp cs:[OldClock_Vector]
	sti

	OldClock_Vector DWORD ?
Clock_Interrupt ENDP

printspace PROC
;PRE: al is space, ah function code,
;bh video mode and cx no of times to print
	push cx

	mov al,20h
	mov ah,0Ah
	mov bh,00h
	mov cx,1
	int 10h

	pop cx
	ret
printspace ENDP

remove_clock PROC
;PRE: takes cx as no of spaces to print
;dx as cursor position
;POST: prints the space 8 times
	mov cx,8	
	mov dh,0
	mov dl,71
	call setcursor
R1:
	call printspace
	call movecursor
	dec cx
	cmp cx,0
	jg R1

	ret
remove_clock ENDP

initial_row BYTE 0
initial_col BYTE 0
 
int9_handler PROC FAR
	cli 
	pushf
	push es
	push ax
	push di

;Point ES:DI to DOS KEYBOARD FLAGS
L1:	mov ax,40h
	mov es,ax
	mov di,17h
	mov ah,es:[di]
	
;TEST if Ctrl and Alt pressed
;Disable Shift Keys if pressed
;Enable if pressed again
R1: 
	test ah,04h
	jz L2
	test ah,08h
	jz L2

;If UNINSTALL is 0, disable shifts
;If it is 1, enable shift
	cmp cs:[UNINSTALL],0
	ja R2
	mov cs:[UNINSTALL],1
	jmp L5
R2:
	mov cs:[UNINSTALL],0

;Test for the shift keys and if Alt/Ctrl were pressed
L2:	test ah,right_shift
	jz L5
	test ah,left_shift
	jz L5
	cmp cs:[UNINSTALL],0
	ja L5
	
L3:    	cmp cs:[Clock_Printed],1
	jb L4
	mov cs:[Clock_Printed],0

;If shift keys were pressed a second time
;Remove the clock
;Get cursor position, save it and remove clock
	call getcursor
	mov cs:[initial_row],dh
	mov cs:[initial_col],dl
	mov dh,0h
	mov dl,71
        call remove_clock
;restore cursor position
	mov dh,cs:[initial_row]
	mov dl,cs:[initial_col]
	call setcursor

	jmp L5

L4:	mov cs:[Clock_Printed],1

L5:	
	pop di
	pop ax
	pop es
	popf
	jmp cs:[old_interrupt9]
	sti
old_interrupt9 DWORD ?

int9_handler ENDP
end_ISR label BYTE

;end of tsr prog
;main function part of the program
;get interrupts, save them and 
;install our own interrupts
setup:
	
GET_TIME_HANDLE:
	call get_time_handler

CHECK_IF_INSTALLED:
	cmp ax, OFFSET cs:[Clock_Interrupt]
	jne SAVE_TIME_HANDLE
	mov ax,OFFSET cs:[mystring]
	call printmystring
	call movecursor
	jmp Exitit_Program

SAVE_TIME_HANDLE:
	mov WORD ptr cs:[OldClock_Vector],ax
	mov WORD ptr cs:[OldClock_Vector+2],dx

INSTALL_TIME_HANDLE:
	call install_timehandle

SAVE_KEY_HANDLE:
	call getkey_handler	
	mov WORD ptr cs:[old_interrupt9],ax	
	mov WORD ptr cs:[old_interrupt9+2],dx      

INSTALL_KEY_HANDLE:
	call installkey_handler

Exitit_Program:
	mov ax,3100h		;Terminate and Stay Resident
	mov dx,0		
	mov dx,OFFSET end_ISR	;point to end of TSR code
	shr dx,4		;divide by 16
	inc dx			;round up to next paragraph
	int 21h			;Wake_DOS
END start


















































 


