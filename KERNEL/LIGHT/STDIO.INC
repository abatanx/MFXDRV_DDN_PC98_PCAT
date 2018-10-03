;
;    Standerd I/O include file (c) ABA / T.kobayashi and Interfair 1993.
;

CR		EQU		0DH,0AH
NULL	equ		0
EOF		equ		-1
EOL		equ		'$'
TAB		equ		09h

push_all macro
		pushf
		pusha
		push	ds
		push	es
		push	bp
		endm

pop_all macro
		pop		bp
		pop		es
		pop		ds
		popa
		popf
		endm

_exit	macro	ret_code
		mov		ah,4ch
		mov		al,ret_code
		int		21h
		endm

ifndef	MEMORYMODEL
_print	macro	msg
		mov		ah,09h
		mov		dx,offset msg
		int		21h
		endm
else
	if		MEMORYMODEL	eq	0
	_print	macro	msg
			mov		ah,09h
			mov		dx,offset msg
			int		21h
			endm
	else
	_print	macro	msg
			push	ds
			mov		ax,_DATA
			mov		ds,ax
			mov		ah,09h
			mov		dx,offset msg
			int		21h
			pop		ds
			endm
	endif
endif

_puts	macro	str
		local	message
	.data
message	db		str,0dh,0ah,'$'
	.code
		_print	message
		endm

_put	macro	str
		local	message
	.data
message	db		str,'$'
	.code
		_print	message
		endm


_local_on	macro
		push	ax
		mov		cs:[local_sp_old],sp
		mov		cs:[local_ss_old],ss
		mov		sp,offset local_stack-2
		mov		ax,cs
		mov		ss,ax
		endm

_local_off	macro
		mov		sp,cs:[local_sp_old]
		mov		ss,cs:[local_ss_old]
		pop		ax
		endm

