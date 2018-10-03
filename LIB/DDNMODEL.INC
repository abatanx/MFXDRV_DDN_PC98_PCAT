;---- memory model and CPU ----
;		jumps
		.186

c_near	equ		1
c_far	equ		2

if MEMORYMODEL eq 0
		.model	tiny,C
		CODESIZE	=	c_near
endif
if MEMORYMODEL eq 1
		.model	small,C
		CODESIZE	=	c_near
endif
if MEMORYMODEL eq 2
		.model	medium,C
		CODESIZE	=	c_far
endif
if MEMORYMODEL eq 3
		.model	compact,C
		CODESIZE	=	c_near
endif
if MEMORYMODEL eq 4
		.model	large,C
		CODESIZE	=	c_far
endif
if MEMORYMODEL eq 5
		.model	huge,C
		CODESIZE	=	c_far
endif

DDNVECT		=	50h

