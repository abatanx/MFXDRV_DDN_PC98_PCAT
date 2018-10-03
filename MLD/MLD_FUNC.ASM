;/////////////////////////////////////////////////////////////////////////////;
;MLDファンクション関係
;/////////////////////////////////////////////////////////////////////////////;

			jumps
			dosseg
			.186
			.model	compact,C
include		..\kernel\stdio.inc
include		..\kernel\ddn.inc

			assume	cs:@code,ds:@data
			.code

data_seg	dw	?

int51		label	dword
int51_ofs	dw	?
int51_seg	dw	?

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

mfxddn_id	db		'MFXkernel',NULL

; PSP作成
make_psp	proc	segs:word
			public	make_psp
			mov		dx,segs
			mov		ah,26h
			int		21h
			ret
make_psp	endp

; 割り込みベクタを設定
int51_start	proc
			public	int51_start
			mov		cs:[data_seg],ds
			pusha
			push	ds
			push	es
			mov		ax,3551h
			int		21h
			mov		cs:[int51_ofs],bx
			mov		cs:[int51_seg],es
			mov		ax,cs
			mov		ds,ax
			mov		dx,offset int51_main
			mov		ax,2551h
			int		21h
			pop		es
			pop		ds
			popa
			ret
int51_start	endp

; 割り込みベクタを戻す
int51_end		proc
			public	int51_end
			push	ds
			push	es
			lds		dx,cs:[int51]
			mov		ax,2551h
			int		21h
			pop		es
			pop		ds
			ret
int51_end		endp


; 割り込みメイン
int51_main	proc
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
int51_main	endp

; XDVドライバーのタイプ
check_xdv_driver	proc	seg_p:word
			public	check_xdv_driver
			mov		cs:[bp_stack],bp
			mov		bp,sp
			mov		ax,seg_p
			mov		es,ax
			mov		ax,es:[DRVTYPE]
			mov		bp,cs:[bp_stack]
			ret
check_xdv_driver	endp

; XDVドライバー実行
run_xdv_driver	proc	seg_p:word
			public	run_xdv_driver
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
run_xdv_driver	endp

; XDVをMFXDDNに渡す
regist_xdv_driver	proc	seg_p:word
			public	regist_xdv_driver
			mov		cs:[bp_stack],bp
			mov		bp,sp
			mov		es,seg_p
			mov		ah,00h
			int		50h
			mov		bp,cs:[bp_stack]
			ret
regist_xdv_driver	endp

; オプションのチェック (int 51h ah=00h )
get_option_param	proc
extrn		get_option_parameter:near
			mov		cs:[cx_entry],1
			mov		cs:[dx_entry],0
			xor		ah,ah
			push	ax
			push	ax
			push	es
			push	bx
			mov		ds,cs:[data_seg]
			call	get_option_parameter
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
extrn		load_file_main:near
			mov		ds,cs:[data_seg]
			push	es
			push	bx
			call	load_file_main
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
extrn		load_file_stay_main:near
			mov		ds,cs:[data_seg]
			push	es
			push	bx
			call	load_file_stay_main
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