section .data
format_string db "I wanna decimal: %d, hex: %x, oct: %o, binary: %b", 0x0a, '$'

dec:		  db "dec"
chr :		  db "chr"
oct :		  db "oct"
hex :		  db "hex"
bin :          db "bin"
str: 		  db "str"

WRITE64 equ 0x01
STDOUT  equ 0x01
EXIT  	equ 0x3C

section .text



global _start

_start:			mov rsi, format_string
				call format_parser

				mov rax, EXIT
				xor rdi, rdi
				syscall


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
;Entry:			RSI - format string
;
;Exit:			
;Destr:			R8B RDX RDI RAX RCX R10
;Note:			uses CLD
;==============================================================
format_parser:
				xor cx, cx
				inc cx
				neg cx
				mov r8b, '$'				
				mov ah, '%'
				mov rdi, rsi

				cld
.parsing_string:
				lodsb
				cmp al, r8b
				jz .end_of_format_string

				cmp al, ah
				jnz .not_format_symbol

				mov r10, rsi

				print_before_format_symbol

				mov r11b, [r10]
				inc r10

				call select_substitution_and_print

				mov rdi, r10
				mov rsi, r10
				mov ah, '%'

.not_format_symbol:
				LOOP .parsing_string
				

.end_of_format_string:
				
				print_before_format_symbol

				ret



;==============================================================
;Entry:			R11B - format symbol
;				
;
;==============================================================
select_substitution_and_print:
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

.string:		call string_format
				jmp .format_defined

.binary			call bin_format
				jmp .format_defined

.octal			call oct_format
				jmp .format_defined
				
.hexadecimal	call hex_format
				jmp .format_defined

.decimal		call dec_format
				jmp .format_defined

.format_defined:
				



				ret

dec_format:		
				mov rax, WRITE64
				mov rdi, STDOUT
				mov rsi, dec
				mov rdx, 3
				syscall

				ret

bin_format:		
				mov rax, WRITE64
				mov rdi, STDOUT
				mov rsi, bin
				mov rdx, 3
				syscall

				ret

hex_format:		
				mov rax, WRITE64
				mov rdi, STDOUT
				mov rsi, hex
				mov rdx, 3
				syscall

				ret

oct_format:		
				mov rax, WRITE64
				mov rdi, STDOUT
				mov rsi, oct
				mov rdx, 3
				syscall

				ret

char_format:
				mov rax, WRITE64
				mov rdi, STDOUT
				mov rsi, chr
				mov rdx, 3
				syscall
				ret

string_format:
				mov rax, WRITE64
				mov rdi, STDOUT
				mov rsi, str
				mov rdx, 3
				syscall

				ret
