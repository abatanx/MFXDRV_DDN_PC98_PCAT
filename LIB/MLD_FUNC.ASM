;/////////////////////////////////////////////////////////////////////////////;
;MLDファンクション関係
;/////////////////////////////////////////////////////////////////////////////;

include		ddnmodel.inc
include		ddndef.inc
include		ddn.inc

			.code

IF	CODESIZE	eq	c_near
extrn		ddn_get_option_parameter:near
extrn		ddn_load_file_main:near
extrn		ddn_load_file_stay_main:near
ELSE
extrn		ddn_get_option_parameter:far
extrn		ddn_load_file_main:far
extrn		ddn_load_file_stay_main:far
ENDIF

data_seg	dw	?
mesg_sw		dw	?

int51		label	dword
int51_ofs	dw	?
int51_seg	dw	?
int29		label	dword
int29_ofs	dw	?
int29_seg	dw	?

ax_entry	dw	?
bx_entry	dw	?
cx_entry	dw	?
dx_entry	dw	?
es_entry	dw	?

xdv			label	dword
xdv_ofs		dw	?
xdv_seg		dw	?

bp_stack		dw	?

int_table	dw		offset get_option_param
			dw		offset load_file
			dw		offset load_file_stay

; 割り込みベクタを設定
ddn_int51_start	proc	mesg:word
			public	ddn_int51_start
			mov		cs:[data_seg],ds
			mov		ax,mesg
			mov		cs:[mesg_sw ],ax
			push	ds
			push	es
			mov		ax,3551h
			int		21h
			mov		cs:[int51_ofs],bx
			mov		cs:[int51_seg],es
			mov		ax,cs
			mov		ds,ax
			mov		dx,offset ddn_int51_main
			mov		ax,2551h
			int		21h

			mov		ax,3529h
			int		21h
			mov		cs:[int29_ofs],bx
			mov		cs:[int29_seg],es
			mov		ax,cs
			mov		ds,ax
			mov		dx,offset ddn_int29_main
			mov		ax,2529h
			int		21h

			pop		es
			pop		ds
			ret
ddn_int51_start	endp

; 割り込みベクタを戻す
ddn_int51_end		proc
			public	ddn_int51_end
			push	ds
			push	es
			lds		dx,cs:[int51]
			mov		ax,2551h
			int		21h
			lds		dx,cs:[int29]
			mov		ax,2529h
			int		21h
			pop		es
			pop		ds
			ret
ddn_int51_end		endp


; 割り込みメイン(INT 51H)
ddn_int51_main	proc
			mov		cs:[ax_entry],ax
			mov		cs:[bx_entry],bx
			mov		cs:[cx_entry],cx
			mov		cs:[dx_entry],dx
			mov		cs:[es_entry],es
			push_all
			push	cs
			pop		ds
			
			push	ax
			push	bx
			xor		bx,bx
			mov		bl,ah
			shl		bx,1
			add		bx,offset int_table
			mov		dx,[bx]
			pop		bx
			pop		ax

			call	dx
			pop_all
			mov		ax,cs:[ax_entry]
			mov		bx,cs:[bx_entry]
			mov		cx,cs:[cx_entry]
			mov		dx,cs:[dx_entry]
			mov		es,cs:[es_entry]
		err_funcout:
			iret
ddn_int51_main	endp

; 割り込みメイン(INT 29H)
ddn_int29_main	proc
			cmp		cs:[mesg_sw],1
			jz		dim_end
			pushf
			call	dword ptr cs:[int29]
	dim_end:
			iret
ddn_int29_main	endp

; XDVドライバーのタイプ
ddn_check_xdv_driver	proc	seg_p:word
			public	ddn_check_xdv_driver
			mov		cs:[bp_stack],bp
			mov		bp,sp
			mov		ax,seg_p
			mov		es,ax
			mov		ax,es:[DRVTYPE]
			mov		bp,cs:[bp_stack]
			ret
ddn_check_xdv_driver	endp

; XDVドライバー実行
ddn_run_xdv_driver	proc	seg_p:word
			public	ddn_run_xdv_driver
			mov		cs:[bp_stack],bp
			mov		bp,sp
			mov		ax,seg_p
			push_all
			mov		es,ax
			mov		ax,word ptr es:[DRVINIT]
			mov		cs:[xdv_ofs ],ax
			mov		cs:[xdv_seg ],es
			mov		cs:[data_seg],ds
			mov		ax,es
			mov		ds,ax
			mov		dx,word ptr es:[DRVINSTMSG]
			mov		ax,0900h
			int		21h

			call	dword ptr cs:[xdv]
			mov		cs:[ax_entry],ax
			pop_all
			mov		bp,cs:[bp_stack]
			mov		ax,cs:[ax_entry]
			ret
ddn_run_xdv_driver	endp

; XDVをMFXDDNに渡す
ddn_regist_xdv_driver	proc	seg_p:word
			public	ddn_regist_xdv_driver
			mov		cs:[bp_stack],bp
			mov		bp,sp
			mov		es,seg_p
			mov		ah,00h
			int		50h
			mov		bp,cs:[bp_stack]
			ret
ddn_regist_xdv_driver	endp

; オプションのチェック (int 51h ah=00h )
get_option_param	proc
			mov		cs:[cx_entry],1
			mov		cs:[dx_entry],0
			xor		ah,ah
			push	ax
			push	ax
			push	es
			push	bx
			mov		ds,cs:[data_seg]
			call	ddn_get_option_parameter
			add		sp,6
			cmp		ax,-1
			jz		chk1
			or		ax,ax
			jz		chk2
			jmp		normal
;おぷしょんエラーかちぇっく～
		chk1:
			cmp		dx,-1
			jnz		normal
			mov		cs:[dx_entry],1		; えらー
			jmp		normal
;おぷしょんないかちぇっく～
		chk2:
			cmp		dx,-1
			jnz		normal
			mov		cs:[cx_entry],0		; ない～
	normal:
			pop		cx
			cmp		cx,2
			jz		str_ret
	num_ret:
			mov		cs:[ax_entry],ax
			ret
	str_ret:
			mov		cs:[bx_entry],ax
			mov		cs:[es_entry],dx
			ret
get_option_param	endp


; ファイルの読み込み (int 51h ah=01h )
load_file	proc
			mov		ds,cs:[data_seg]
			push	es
			push	bx
			call	ddn_load_file_main
			add		sp,4
			mov		bx,ax
			or		bx,dx
			jz		lf_err
			mov		cs:[es_entry],dx
			mov		cs:[ax_entry],0
			jmp		lf_end
	lf_err:
			mov		cs:[ax_entry],EOF
	lf_end:
			ret
load_file	endp

; ファイルの読み込み with 常駐 (int 51h ah=02h )
load_file_stay	proc
			mov		ds,cs:[data_seg]
			push	es
			push	bx
			call	ddn_load_file_stay_main
			add		sp,4
			mov		bx,ax
			or		bx,dx
			jz		lfs_err
			mov		cs:[es_entry],dx
			mov		cs:[ax_entry],0
			jmp		lfs_end
	lfs_err:
			mov		cs:[ax_entry],EOF
	lfs_end:
			ret
load_file_stay	endp



end
