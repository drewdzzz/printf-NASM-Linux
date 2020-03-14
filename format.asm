section .data

BUFFER_SIZE	equ	255 				;must be more than 32 bits!!

buffer  	times BUFFER_SIZE db '$'

STDOUT 		equ 0x01	
EXIT		equ	0x3C
NEW_LINE	equ	0x0A



section .text

;==============================================================
;Enter:		RSI - address of buffer
;			RDX - length of buffer
;Exit:		RSI - address of place in buffer after all the insignificant zeroes
;			RDX - new length of buffer
;			AL  - = '0'
;			ES  - = DS	
;Destr:		RAX RCX
;==============================================================
%macro skip_zero_rsi 0
				mov eax, ds
				mov es, eax
				mov al, '0'
				mov rcx, rdx
				dec rcx
%%skipping:	
				cmp al, [rsi]
				jnz %%break
				inc rsi
				dec rdx
				loop %%skipping
%%break:

%endmacro

global _start

_start:			mov r8d, 186
				call dec_format
				mov rax, 0x01
				mov rdi, STDOUT
				syscall

				mov rax, EXIT
				xor rdi, rdi
				syscall



;==============================================================
;Entry:			requires buffer and const BUFFER_SIZE
;				R8D	- int value
;Exit: 			RDX - length of buffer
;				RSI - ptr to number in buffer
;				ES  = DS
;Dуstr:			RCX, R10B, R8D, RAX
;==============================================================
hex_format:
				mov rsi, buffer
				add rsi, BUFFER_SIZE
				mov rcx, 8			; 4*2: 4 bytes and in one byte we can find 2 hex digits
				mov al, 0x0F
				xor rdx,rdx

.hex_format_loop:
				dec rsi
				inc rdx

				mov r10b, r8b
				shr r8d, 4

				and r10b, al
				cmp r10b, 10
				jae .need_letter
				add r10b, '0'
				mov [rsi], r10b
				jmp .number				               ;Что лучше? Два раза записать в память, или 2 джампа (один из них обязательно сработает)
.need_letter:
				add r10b, 'A' - 10
				mov [rsi], r10b

.number:
				LOOP .hex_format_loop

				skip_zero_rsi						;Скипаем все незначащие нули

				ret



;==============================================================
;Entry:			requires buffer and const BUFFER_SIZE
;				R8D	- int value
;Exit: 			RDX - length of buffer
;				RSI - ptr to number in buffer
;				ES  = DS
;
;Destr:			RCX RAX	R8D	R10B		
;==============================================================
bin_format:
				mov rsi, buffer
				add rsi, BUFFER_SIZE
				xor rdx, rdx
				mov al, 1
				mov rcx, 32			;Int is a number with 32 bits

.bin_format_loop:
				dec rsi
				inc rdx

				mov r10b, r8b
				shr r8d, 1

				and r10b, al
				add r10b, '0'
				mov [rsi], r10b
				LOOP .bin_format_loop

				skip_zero_rsi						;Пропускаем все незначащие нули

				ret


;==============================================================
;Entry:			requires buffer and const BUFFER_SIZE
;				R8D	- int value
;Exit: 			RDX - length of buffer
;				RSI - ptr to number in buffer
;				ES  = DS
;
;Destr:			RCX RAX	R8D	R10B		
;==============================================================
oct_format:
				mov rsi, buffer
				add rsi, BUFFER_SIZE
				xor rdx, rdx
				mov al, 7
				mov rcx, 11			;11 octal digits in 4 bytes

.oct_format_loop:
				dec rsi
				inc rdx

				mov r10b, r8b
				shr r8b, 3

				and r10b, al
				add r10b, '0'
				mov [rsi], r10b
				LOOP .oct_format_loop

				skip_zero_rsi

				ret


;==============================================================
;Entry:			requires buffer and const BUFFER_SIZE
;				R8D	- int value
;Exit: 			RDX - length of buffer
;				RSI - ptr to number in buffer
;				ES  = DS
;
;Destr:			RCX RAX	R8D	R10B R9B		
;==============================================================
dec_format:
				mov rsi, buffer
				add rsi, BUFFER_SIZE
				xor r10b, r10b
				mov r9d, 10
				mov rcx, 9
				mov eax, r8d

.dec_format_loop:
				dec rsi
				inc r10b

				xor edx, edx
				div r9d

				add edx, '0'
				mov [rsi], dl 
				LOOP .dec_format_loop

				xor rdx, rdx
				mov dl, r10b

				skip_zero_rsi

				ret



