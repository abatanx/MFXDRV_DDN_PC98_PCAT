comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ÉÅÉÇÉäÅ[ä«óù
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

ddn_free_memory		proc	buffer:dword
		public	ddn_free_memory
		push	es
		mov		ax,word ptr buffer+2
		mov		es,ax
		mov		ah,49h
		int		21h
		pop		es
		jb		free_memory_error
		mov		ax,NULL
		ret
	free_memory_error:
		mov		ax,EOF
		ret
ddn_free_memory		endp

ddn_keep_highmemory	proc	bsize:dword
		public	ddn_keep_highmemory
		mov		ax,5801h
		mov		bx,2
		int		21h
		mov		ax,word ptr bsize
		mov		dx,word ptr bsize+2
	rept	4
		shr		dx,1
		rcr		ax,1
	endm
		mov		bx,ax
		inc		bx
	
		mov		ah,48h
		int		21h
		jb		size_error
		mov		dx,ax
		mov		ax,5801h
		mov		bx,0
		int		21h
		xor		ax,ax
		ret
	size_error:
		xor		dx,dx
		xor		ax,ax
		ret
ddn_keep_highmemory		endp

end
