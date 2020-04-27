section .data

BUFFER_SIZE equ 100
buffer times BUFFER_SIZE db 0
symbols db "0123456789ABCDEF"

DETERMINATING_CHAR equ 0
WRITE64 equ 0x01
STDOUT  equ 0x01
EXIT  	equ 0x3C

section .text

;==============================================================
;Enter:			RDI - begin of the string
;				RSI - end of the string
;Exit:			RDX - length of the string
;				RAX - EXIT code
;				RDI - STDOUT code
;Destr:			R11 - because of syscall
;==============================================================
%macro 			print_before_format_symbol 0
				

				mov rdx, rsi
				sub rdx, rdi
				dec rdx					
				mov rsi, rdi
				mov rax, WRITE64
				mov rdi, STDOUT
				syscall
%endmacro


;==============================================================
;Enter:			RDI RSI RDX RCX R8 R9 - STDCALL first 6 arguments
;Destr:			RAX
;==============================================================
%macro 			push_arguments 0
				pop rax
				push r9
				push r8
				push rcx
				push rdx
				push rsi
				push rdi
				push rax
%endmacro

;==============================================================
;Destr			RAX RCX
;==============================================================
%macro 			pop_arguments 0
				pop rax
				times 6 pop rcx
				push rax
%endmacro


;==============================================================
;Entry:			STDCALL standard arguments
;
;Exit:			
;Destr:			RDX RDI RAX RCX RBX R10 R8 R9 RSI R11B
;Note:			uses CLD
;==============================================================
global NASM_PRINTF
NASM_PRINTF:	
				push_arguments

				push rbp

				mov rbp, rsp
				add rbp, 16
				mov rsi, [rbp]
				add rbp, 8
				xor cx, cx
				inc cx
				neg cx
				mov r8b, DETERMINATING_CHAR				
				mov ah, '%'
				mov rdi, rsi

				cld
.parsing_string:
				lodsb
				cmp al, r8b
				jz .end_of_format_string

				cmp al, ah
				jnz .not_format_symbol

				mov rbx, rsi

				print_before_format_symbol

				mov r11b, [rbx]
				inc rbx

				call select_substitution_and_print

				mov rdi, rbx
				mov rsi, rbx
				mov ah, '%'
				mov r8b, DETERMINATING_CHAR

.not_format_symbol:
				LOOP .parsing_string
				

.end_of_format_string:
				
				print_before_format_symbol

				pop rbp
				
				pop_arguments

				ret



;==============================================================
;Entry:			R11B - format symbol
;				
;Destr:			RAX RDI R8
;==============================================================
select_substitution_and_print:

				cmp r11b, '%'
				jz .percent

				mov r8, [rbp]
				add rbp, 8

				cmp r11b, 'd'
				jz .decimal

				cmp r11b, 'x'
				jz .hexadecimal

				cmp r11b, 'o'
				jz .octal

				cmp r11b, 'b'
				jz .binary

				cmp r11b, 's'
				jz .string

;IF r11b == 'c'	
				call char_format
				jmp .format_defined

.percent:		call percent_format		
				jmp .format_defined

.string:
				call string_format
				jmp .format_defined

.binary:		call bin_format
				jmp .format_defined

.octal:			call oct_format
				jmp .format_defined
				
.hexadecimal:	call hex_format
				jmp .format_defined

.decimal:		call dec_format


.format_defined:
				
				mov rax, WRITE64
				mov rdi, STDOUT
				syscall
				
				ret


;==============================================================
;Enter:			Requires buffer
;				R8B - symbol
;Exit:			RDX = 1
;				RSI - ptr to char in a buffer
;==============================================================
char_format:
				mov rsi, buffer
				mov [rsi], r8b
				xor rdx, rdx
				inc rdx

				ret



;==============================================================
;Enter			RDI - address of string
;				ES  - segment fo address
;Exit:			RDX
;Destr:			RDI
;==============================================================
%macro 			strlen 0
				
				xor al, al

				xor rcx, rcx
				dec rcx

				repne scasb
				neg rcx
				dec rcx
				mov rdx, rcx

%endmacro


;==============================================================
;Entry:		R8 - ADDRESS OF STRING
;
;Exit:		RCX - length of string
;			ES = DS
;			RSI - ptr to the string
;			RDX - length of string
;Destr:		ES RAX RDI
;Note:		using CLD 
;==============================================================
string_format:
				cld
				mov rsi, r8

				mov rdi, r8
				mov eax, ds
				mov es, eax
				
				strlen

				ret



;==============================================================
;Enter:		RSI - address of buffer
;			RDX - length of buffer
;Exit:		RSI - address of place in buffer after all the insignificant zeroes
;			RDX - new length of buffer
;			AL  = '0'
;			ES  = DS	
;Destr:		RAX RCX
;==============================================================
%macro 			skip_zero_rsi 0
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
				mov rcx, 8								;4*2: 4 bytes and in one byte we can find 2 hex digits
				mov al, 0x0F
				xor rdx,rdx
				mov r11b, 4
				
				call format_proccess					

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
				mov rcx, 32							;Int is a number with 32 bits
				mov r11b, 1

				call format_proccess

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
				mov r11b, 3

				call format_proccess

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


;==============================================================
;Enter:			requires buffer
;Exit:			RSI - ptr to '%' in a buffer
;				RDX = 1
;				R8B = '%'
;==============================================================
percent_format:
				mov rsi, buffer
				mov r8b, '%'
				mov [rsi], r8b
				xor rdx, rdx
				inc rdx

				ret



;==============================================================
;Enter:			RCX - max number of symbols
;				RSI - ptr right after buffer
;				AL  - mask for format
;				RDX - must be zero
;				R8D - formatiing value
;				R11B - size of mask
;				
;
;Exit:			RDX - length of formated string
;Destr:			R10B R9
;==============================================================
format_proccess:
				dec rsi
				inc rdx

				mov r9b, cl
				mov r10b, r8b
				mov cl, r11b
				shr r8d, cl

				and r10b, al

				mov cl, r9b

				mov r9, symbols
				and r10, 0xFFFF
				mov r9b, [r9 + r10]

				mov [rsi], r9b

				LOOP format_proccess

				skip_zero_rsi

				ret