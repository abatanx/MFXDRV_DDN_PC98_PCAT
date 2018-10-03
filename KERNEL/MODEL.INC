COMTYPE		equ		1
LIBTYPE		equ		2

_near		=		0
_far		=		1

IF	PROGMODE	EQ	COMTYPE
MEMORYMODEL	=	0
ENDIF

			.186
IF	MEMORYMODEL	eq	0
			jumps
			dosseg
			.model	tiny
	calltype	=	_near
ENDIF

comment~
IF	MEMORYMODEL	eq	1
			.model	small,C
	calltype	=	_near
ENDIF
IF	MEMORYMODEL	eq	2
			.model	medium,C
	calltype	=	_far
ENDIF
IF	MEMORYMODEL	eq	3
			.model	compact,C
	calltype	=	_near
ENDIF
IF	MEMORYMODEL	eq	4
			.model	large,C
	calltype	=	_far
ENDIF
IF	MEMORYMODEL	eq	5
			.model	huge,C
	calltype	=	_far
ENDIF
~
