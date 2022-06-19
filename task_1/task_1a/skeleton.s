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
    sub ecx, next_i - FileName  ; getting the location of FileName
	mov eax, ecx
    open eax, RDWR, 0777        ; opening file "ELFexec" to read & write with all permissions
	cmp eax, -1					; checking if open was succesful
	je _file_error				
	mov esi, eax				; esi = fd
	lea ebx, [ebp-BUFF_SIZE]		
	read esi, ebx, ELFHDR_size	;read first 4 bytes
	cmp dword[ebp-BUFF_SIZE], ELF_MAGIC		; check if file is elf
	jne	_error_not_elf
	write 1, OutStr, Failstr - OutStr 
	jmp VirusExit

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
	

get_my_loc:
	call next_i
next_i:
	pop ecx
	ret	
PreviousEntryPoint: dd VirusExit
virus_end:


