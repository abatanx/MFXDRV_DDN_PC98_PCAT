;
;    Standerd I/O include file (c) ABA / T.kobayashi and Interfair 1993.
;

CR		EQU		0DH,0AH
NULL	equ		0
EOF		equ		-1
EOL		equ		'$'
TAB		equ		09h

NOTINSTALLED		equ		0		// DDN/LIB がINSTALLされてない
NOTENOUGHMEMORY		equ		1		// メモリが足りない
FILENOTFOUND		equ		2		// ファイルが見つからない
NOTMUDFILE			equ		3		// MUD ファイルではない
VERSIONERROR		equ		4		// XMML3.00 ではない
DRIVERNOTFOUND		equ		5		// DRIVERが見つからない
MUDSIZEOVER			equ		6		// サイズが大きすぎる
COMPLETE			equ		7		// 演奏成功
COMPLETEEXEC		equ		8		// 実行成功
FAULTEXEC			equ		9		// 実行失敗

extrn	mfxddn_err,MFXDDN_Initialize:word

mfxddn_errset	macro	errcode
		mov		[mfxddn_err],errcode
		endm

;comment~
push_all macro
		pushf
		pusha
		push	ds
		push	es
		endm

pop_all macro
		pop		es
		pop		ds
		popa
		popf
		endm
;~

comment~
push_all macro
		pushf
		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		push	bp
		endm

pop_all macro
		pop		bp
		pop		es
		pop		ds
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		endm
~

_exit	macro	ret_code
		mov		ah,4ch
		mov		al,ret_code
		int		21h
		endm

_print	macro	msg
		mov		ah,09h
		mov		dx,offset msg
		int		21h
		endm

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
		mov		sp,offset local_stack
		mov		ax,cs
		mov		ss,ax
		endm

_local_off	macro
		mov		sp,cs:[local_sp_old]
		mov		ss,cs:[local_ss_old]
		pop		ax
		endm

