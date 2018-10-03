
NO_PARAM		equ		0
VALUE_PARAM		equ		1
STR_PARAM		equ		2
PM_PARAM		equ		3
ONOFF_PARAM		equ		4
TF_PARAM		equ		5

;option����macro
option		macro	opt_str,type,next_labels,error_labels
			local	_options
.data
_options	db		opt_str,NULL
.code
			mov		ax,cs
			mov		es,ax
			mov		bx,offset _options
			mov		al,type
			mov		ah,0
			int		51h
			shr		cx,1
			jnb		next_labels
			shr		dx,1
			jb		error_labels
			endm

;�t�@�C���ǂݍ���
fload		macro	filename
			local	_fname
.data
_fname		db		filename,NULL
.code
			mov		ax,cs
			mov		es,ax
			mov		bx,offset _fname
			mov		ah,01h
			int		51h
			endm

;�t�@�C���ǂݍ��� + �풓
floadstay	macro	filename
			local	_fname
.data
_fname		db		filename,NULL
.code
			mov		ax,cs
			mov		es,ax
			mov		bx,offset _fname
			mov		ah,02h
			int		51h
			endm

;�풓�����������̉��
free_memory	macro	seg
			mov		ax,seg
			mov		es,ax
			mov		ah,49h
			int		21h
			endm
