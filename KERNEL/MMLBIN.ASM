;/////////////////////////////////////////////////////////////////////////////;
;
;      Multi module music driver MFXDDN(tm) kernel system release 0.00 
;  MFXDDN(tm) Music driver For XMML , Deconcentrate Drivers Network System
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;
;/////////////////////////////////////////////////////////////////////////////;
;
; トラック演奏部
;
IF	PROGMODE		EQ	COMTYPE
MFXDRVDDN_KERNEL	equ	TRUE
include		model.inc
include		stdio.inc
include		ddn.inc
include		timerdrv.inc
			.code
ENDIF

_fc			macro	func_no
			mov		ah,func_no
			mov		al,[si].driver_no
			mov		ch,[si].channel
			call	call_driver
			endm

_f			macro	func_no
			mov		ah,func_no
			mov		al,[si].driver_no
			call	call_driver
			endm

;-------- MML BIN ファンクション
			even
mmlbin_func	dw		offset mml_poly_keyplession			;A	0
			dw		offset mml_bank_select				;	1
			dw		offset mml_modulation				;	2
			dw		offset mml_poltament_time			;	3
			dw		offset mml_data_entry				;	4
			dw		offset mml_volume					;	5
			dw		offset mml_panpot					;	6
			dw		offset mml_expression				;	7
			dw		offset mml_hold1					;	8
			dw		offset mml_poltament				;	9
			dw		offset mml_sostenuto				;	A
			dw		offset mml_soft						;	B
			dw		offset mml_poltament_controll		;	C
			dw		offset mml_usual_effect1			;	D
			dw		offset mml_usual_effect3			;	E
			dw		offset mml_nrpn						;	F
			dw		offset mml_rpn						;B	0
			dw		offset mml_program_change			;	1
			dw		offset mml_channel_presser			;	2
			dw		offset mml_pitch_bend				;	3
			dw		offset mml_all_soundoff				;	4
			dw		offset mml_reset_allcontroller		;	5
			dw		offset mml_all_noteoff				;	6
			dw		offset mml_omni_off					;	7
			dw		offset mml_omni_on					;	8
			dw		offset mml_mono						;	9
			dw		offset mml_poly						;	A
			dw		offset mml_exclusive				;	B
			dw		offset mml_reserve					;	C
			dw		offset mml_reserve					;	D
			dw		offset mml_reserve					;	E
			dw		offset mml_reserve					;	F
			dw		offset mml_reserve					;C	0
			dw		offset mml_master_volume			;	1
			dw		offset mml_reserve					;	2
			dw		offset mml_reserve					;	3
			dw		offset mml_tempo					;	4
			dw		offset mml_reserve					;	5
			dw		offset mml_reserve					;	6
			dw		offset mml_reserve					;	7
			dw		offset mml_reserve					;	8
			dw		offset mml_reserve					;	9
			dw		offset mml_reserve					;	A
			dw		offset mml_reserve					;	B
			dw		offset mml_reserve					;	C
			dw		offset mml_reserve					;	D
			dw		offset mml_reserve					;	E
			dw		offset mml_reserve					;	F
			dw		offset mml_repeat_start				;D	0
			dw		offset mml_repeat_end				;	1
			dw		offset mml_repeat_exit				;	2
			dw		offset mml_reserve					;	3
			dw		offset mml_reserve					;	4
			dw		offset mml_reserve					;	5
			dw		offset mml_reserve					;	6
			dw		offset mml_reserve					;	7
			dw		offset mml_reserve					;	8
			dw		offset mml_reserve					;	9
			dw		offset mml_skip_start				;	A
			dw		offset mml_skip_end					;	B
			dw		offset mml_decompose_start			;	C
			dw		offset mml_decompose_end			;	D
			dw		offset mml_reserve					;	E
			dw		offset mml_reserve					;	F
			dw		offset mml_fadeout					;E	0
			dw		offset mml_ecm						;	1
			dw		offset mml_fine						;	2
			dw		offset mml_reserve					;	3
			dw		offset mml_reserve					;	4
			dw		offset mml_reserve					;	5
			dw		offset mml_reserve					;	6
			dw		offset mml_reserve					;	7
			dw		offset mml_reserve					;	8
			dw		offset mml_reserve					;	9
			dw		offset mml_reserve					;	A
			dw		offset mml_reserve					;	B
			dw		offset mml_reserve					;	C
			dw		offset mml_reserve					;	D
			dw		offset mml_reserve					;	E
			dw		offset mml_reserve					;	F

;-------- トラックコマンド解釈と、ドライバー呼出
;
track_function	proc
	tf_nextentry:
			mov		al,es:[di]
			inc		di
comment~
			cmp		[firstclock],0
			jz		debug_end
			push	ax
			push	bx
			mov		bl,al
			mov		ah,31h
			int		50h
			mov		ah,02h
			mov		dl,','
			int		21h
			pop		bx
			pop		ax
		debug_end:
~
			cmp		al,80h
			jb		mml_note_on			; ノートON		( 0..7fh )
			jz		mml_note_off		; ノートOFF		( 80h    )
			cmp		al,90h
			jz		mml_wait_step		; ウェイト		( 90h    )
			cmp		al,91h
			jz		mml_wait_step16		; ウェイト(16)	( 91h    )
			cmp		al,0f0h
			jae		mml_chg_channel		; チェンジチャンネル
			cmp		al,0a0h
			jb		tr_nextloop
			cmp		al,0efh
			jnbe	tr_nextloop
			sub		al,0a0h

			xor		ah,ah
			mov		bx,ax
			shl		bx,1
			mov		bx,[bx + mmlbin_func]
			push	es
			push	ds
			push	si
			call	bx					; ファンクション呼出
			pop		si
			pop		ds
			pop		es

			cmp		[timer_status],TIMER_OFF
			jz		mmlbin_return
			cmp		[si].use_flag,FALSE
			jz		mmlbin_return
	tr_nextloop:
			jmp		tf_nextentry

; NOTE ON -----
mml_note_on:
			mov		bh,al
			mov		bl,es:[di]
			or		bl,bl
			jz		mno_go		; note off
	note_on_true:
			mov		[si].note    ,al
			mov		[si].velocity,bl
			inc		[si].note_count
	note_on_next:
			mov		[si].velocity,bl
			inc		[si].note_total
			inc		di
			cmp		[si].note_seg,0
			jz		note_on_skip_buf
			push	es
			push	di
			mov		di,[si].note_ofs
			mov		es,[si].note_seg
			xor		ah,ah
			add		di,ax
			cmp		byte ptr es:[di],255
			jz		note_on_skip_buf2
			inc		byte ptr es:[di]
	note_on_skip_buf2:
			pop		di
			pop		es
	note_on_skip_buf:
			cmp		[skip_flag],TRUE
			jnz		note_on_not_skiping
			xor		ax,ax
			mov		al,bl
			shl		ax,1
			mov		bl,3
			div		bl
			inc		al
			mov		bl,al
	note_on_not_skiping:
			mov		ah,02h
			mov		al,[si].driver_no
			mov		ch,[si].channel
			call	call_driver
			jmp		tr_nextloop

; NOTE OFF -----
mml_note_off:
			mov		bh,es:[di]
	mno_go:
			inc		di
			mov		[si].note,0
			mov		[si].velocity,0
			cmp		[si].note_total,0
			jz		mno_already_zero
			dec		[si].note_total
	mno_already_zero:
			cmp		[si].note_seg,0
			jz		note_off_skip_buf
			push	es
			push	di
			mov		di,[si].note_ofs
			mov		es,[si].note_seg
			mov		al,bh
			xor		ah,ah
			add		di,ax
			cmp		byte ptr es:[di],0
			jz		note_off_skip_buf2
			dec		byte ptr es:[di]
	note_off_skip_buf2:
			pop		di
			pop		es
	note_off_skip_buf:
	
			mov		ah,01h
			mov		al,[si].driver_no
			mov		ch,[si].channel
			call	call_driver
			jmp		tr_nextloop

; チャンネルチェンジ -----
mml_chg_channel:
			and		al,0fh
			mov		[si].channel,al
			jmp		tr_nextloop

; WAIT STEP -----
mml_wait_step:
			mov		al,es:[di]
			xor		ah,ah
			inc		di
			mov		[si].steptime,ax
			mov		[si].mus_ofs ,di
			ret
; WAIT STEP(16bit) -----
mml_wait_step16:
			mov		ax,es:[di]
			add		di,2
			mov		[si].steptime,ax
			mov		[si].mus_ofs ,di
			ret
; 無条件RETURN -----
mmlbin_return:
			mov		[si].steptime,255
			mov		[si].mus_ofs ,di
			ret

track_function	endp

;---------------- MML reserve function
mml_reserve	proc
			ret
mml_reserve	endp
;---------------- [A0] Poly key plesser
mml_poly_keyplession	proc
			mov		bx,es:[di]
			xchg	bh,bl
			mov		[si].pkeypresser,bl
			add		di,2
			_fc		03h
			ret
mml_poly_keyplession	endp

;---------------- [A1] Bank Select
mml_bank_select	proc
			mov		bx,es:[di]
			mov		[si].bank,bx
			add		di,2
			_fc		04h
			ret
mml_bank_select	endp

;---------------- [A2] Modulation
mml_modulation	proc
			mov		bh,es:[di]
			mov		[si].modulation,bh
			inc		di
			_fc		05h
			ret
mml_modulation	endp

;---------------- [A3] Poltament time
mml_poltament_time	proc
			mov		bh,es:[di]
			inc		di
			_fc		06h
			ret
mml_poltament_time	endp

;---------------- [A4] Data Entry
mml_data_entry	proc
			mov		bh,es:[di]
			mov		bl,es:[di+1]
			add		di,2
			_fc		07h
			ret
mml_data_entry	endp

;---------------- [A5] Volume
mml_volume	proc
			mov		bh,es:[di]
			mov		[si].volume,bh
			inc		di
			_fc		08h
			ret
mml_volume	endp

;---------------- [A6] Panpot
mml_panpot	proc
			mov		bh,es:[di]
			mov		[si].panpot,bh
			inc		di
			_fc		09h
			ret
mml_panpot	endp

;---------------- [A7] Explession
mml_expression	proc
			mov		bh,es:[di]
			mov		[si].expression,bh
			inc		di
			_fc		0ah
			ret
mml_expression	endp

;---------------- [A8] Hold1
mml_hold1	proc
			mov		bh,es:[di]
			test	bh,11000000b
			jz		hold1_off
			mov		[si].hold1,TRUE
			jmp		hold1_exit
	hold1_off:
			mov		[si].hold1,FALSE
	hold1_exit:
			inc		di
			_fc		0bh
			ret
mml_hold1	endp

;---------------- [A9] Poltament
mml_poltament	proc
			mov		bh,es:[di]
			test	bh,11000000b
			jz		poltament_off
			mov		[si].poltament,TRUE
			jmp		poltament_exit
	poltament_off:
			mov		[si].poltament,FALSE
	poltament_exit:
			inc		di
			_fc		0ch
			ret
mml_poltament	endp

;---------------- [AA] sostenuto
mml_sostenuto	proc
			mov		bh,es:[di]
			test	bh,11000000b
			jz		sustenuto_off
			mov		[si].sustenuto,TRUE
			jmp		sustenuto_exit
	sustenuto_off:
			mov		[si].sustenuto,FALSE
	sustenuto_exit:
			inc		di
			_fc		0dh
			ret
mml_sostenuto	endp

;---------------- [AB] soft
mml_soft	proc
			mov		bh,es:[di]
			test	bh,11000000b
			jz		soft_off
			mov		[si].soft,TRUE
			jmp		soft_exit
	soft_off:
			mov		[si].soft,FALSE
	soft_exit:
			inc		di
			_fc		0eh
			ret
mml_soft	endp

;---------------- [AC] poltament contoroll
mml_poltament_controll	proc
			mov		bh,es:[di]
			mov		[si].poltctrl,bh
			inc		di
			_fc		0fh
			ret
mml_poltament_controll	endp

;---------------- [AD] usual effect1
mml_usual_effect1	proc
			mov		bh,es:[di]
			mov		[si].ueff1sendlv,bh
			inc		di
			_fc		10h
			ret
mml_usual_effect1	endp

;---------------- [AE] usual effect3
mml_usual_effect3	proc
			mov		bh,es:[di]
			mov		[si].ueff3sendlv,bh
			inc		di
			_fc		11h
			ret
mml_usual_effect3	endp

;---------------- [AF] NRPN
mml_nrpn	proc
			mov		bh,es:[di  ]
			mov		bl,es:[di+1]
			add		di,2
			_fc		12h
			ret
mml_nrpn	endp

;---------------- [B0] RPN
mml_rpn		proc
			mov		bh,es:[di  ]
			mov		bl,es:[di+1]
			add		di,2
			_fc		13h
			ret
mml_rpn		endp

;---------------- [B1] Program change
mml_program_change	proc
			mov		bh,es:[di]
			mov		[si].program,bh
			inc		di
			_fc		14h
			ret
mml_program_change	endp

;---------------- [B2] Channel Presser
mml_channel_presser	proc
			mov		bh,es:[di]
			mov		[si].chpresser,bh
			inc		di
			_fc		15h
			ret
mml_channel_presser	endp

;---------------- [B3] pitch bend
mml_pitch_bend	proc
			mov		bx,es:[di]
			mov		[si].pitchbend,bx
			add		di,2
			_fc		16h
			ret
mml_pitch_bend	endp

;---------------- [B4] all soundoff
mml_all_soundoff	proc
			mov		[si].note_total,0
			_fc		17h
			ret
mml_all_soundoff	endp

;---------------- [B5] reset all contoroller
mml_reset_allcontroller	proc
			mov		[si].note_total,0
			_fc		18h
			ret
mml_reset_allcontroller	endp

;---------------- [B6] all note off
mml_all_noteoff	proc
			mov		[si].note_total,0
			_fc		19h
			ret
mml_all_noteoff	endp

;---------------- [B7] OMNI OFF
mml_omni_off	proc
			_fc		1ah
			ret
mml_omni_off	endp

;---------------- [B8] OMNI ON
mml_omni_on	proc
			_fc		1bh
			ret
mml_omni_on	endp

;---------------- [B9] MONO
mml_mono	proc
			mov		bh,es:[di]
			inc		di
			_fc		1ch
			ret
mml_mono	endp

;---------------- [BA] POLY
mml_poly	proc
			_fc		1dh
			ret
mml_poly	endp

;---------------- [BB] exclusive
mml_exclusive	proc
			mov		cl,es:[di]
			xor		ch,ch
			inc		di
			mov		bx,di
			add		di,cx
			_f		1fh
			ret
mml_exclusive	endp
;---------------- [C1] master volume
mml_master_volume	proc
			xor		dx,dx
			mov		dl,es:[di]
			inc		di

			mov		al,dl
			mov		ah,byte ptr [volume_factor]
			mul		ah
			mov		dl,100
			div		dl
			mov		dx,ax
			cmp		dx,127
			jbe		mm_mvset_ok
			mov		dx,127
	mm_mvset_ok:
			mov		[mastervol],dx
			mov		cx,16
			xor		al,al
	mml_mvset:
			xor		bx,bx
			mov		bl,al
			shl		bx,1
			mov		bx,[bx+module_drv]
			or		bx,bx
			jz		mml_mvset2
			push	es
			mov		es,bx
			cmp		es:[DRVTYPE],word ptr NORMAL_DEVICE
			pop		es
			jnz		mml_mvset2
			mov		ah,21h
			mov		bh,dl
			call	call_driver
	mml_mvset2:
			inc		al
			loop	mml_mvset
			ret
mml_master_volume	endp
;---------------- [C4] tempo
mml_tempo	proc
			mov		cx,es:[di]
			add		di,2
			mov		[tempo],cx
			cmp		[play_skip_flag],FALSE
			jz		mt_skiping
			mov		cx,[play_skip_tempo]
	mt_skiping:
			timer_settempo	cx
			ret
mml_tempo	endp

;---------------- [D0] repeat start
mml_repeat_start	proc
			push	si
			mov		ax,type DDN_REPBUF
			mul		byte ptr [now_track]
			mov		bx,ax
			
			mov		si,offset repeat_buf
			mov		cx,[si+bx].rep_level
			cmp		cx,MAX_NEST
			jb		mrs_recrepeat
			inc		di
			jmp		mrs_exit			; 許容できないよー
		mrs_recrepeat:
			inc		[si+bx].rep_level
			shl		cx,1
			add		bx,cx
		
			xor		ax,ax
			mov		al,es:[di]
			inc		di
			mov		[si+bx].rep_count,ax
			mov		[si+bx].rep_address,di
		mrs_exit:
			pop		si
			ret
mml_repeat_start	endp

;---------------- [D1] repeat end
mml_repeat_end		proc
			push	si
			mov		ax,type DDN_REPBUF
			mul		byte ptr [now_track]
			mov		bx,ax
			push	bx
			
			mov		si,offset repeat_buf
			mov		cx,[si+bx].rep_level
			or		cx,cx
			jnz		mre_nz
			pop		bx
			pop		si						; 未登録～
			ret
	mre_nz:
			shl		cx,1
			add		bx,cx
			mov		ax,[si+bx-2].rep_count
			or		ax,ax					; 0 なら無限ループ
			jnz		mre_normal
			mov		di,[si+bx-2].rep_address
			pop		bx
			pop		si
			ret
	mre_normal:
			sub		ax,1
			jz		mre_end_count
			mov		[si+bx-2].rep_count,ax
			mov		[si+bx-2].rep_exitaddress,di
			mov		di,[si+bx-2].rep_address
			pop		bx
			pop		si
			ret
	mre_end_count:
			pop		bx
			dec		[si+bx].rep_level
			pop		si
			ret
mml_repeat_end		endp

;---------------- [D2] repeat exit
mml_repeat_exit		proc
			push	si
			mov		ax,type DDN_REPBUF
			mul		byte ptr [now_track]
			mov		bx,ax
			push	bx
			
			mov		si,offset repeat_buf
			mov		cx,[si+bx].rep_level
			or		cx,cx
			jnz		mrexit_nz
			pop		bx
			pop		si						; 未登録～
			ret
	mrexit_nz:
			shl		cx,1
			add		bx,cx
			mov		ax,[si+bx-2].rep_count
			or		ax,ax					; 0 なら無限ループ
			jnz		mrexit_normal
			pop		bx
			pop		si
			ret
	mrexit_normal:
			cmp		ax,1
			jz		mrexit_end_count
			pop		bx
			pop		si
			ret
	mrexit_end_count:
			mov		di,[si+bx-2].rep_exitaddress
			pop		bx
			dec		[si+bx].rep_level
			pop		si
			ret
mml_repeat_exit		endp

;---------------- [DA] Skip Start
mml_skip_start	proc
			mov		[skip_flag],TRUE
			ret
mml_skip_start	endp

;---------------- [DB] Skip End
mml_skip_end	proc
			mov		[skip_flag],FALSE
			ret
mml_skip_end	endp

;---------------- [DC] Start to decompose
mml_decompose_start	proc
			mov		ch,es:[di  ]
			mov		cl,es:[di+1]
			add		di,2
			xor		bx,bx
			mov		al,type DDN_DECOMPOSE
			mul		[now_track]
			mov		bx,ax
			add		bx,offset dec_buf
			mov		[bx].dec_flag,TRUE
			mov		[bx].dec_start_ch,ch
			mov		[bx].dec_end_ch,cl
			mov		[bx].dec_now_ch,ch
			ret
mml_decompose_start	endp

;---------------- [DC] Finish to decompose
mml_decompose_end	proc
			mov		al,type DDN_DECOMPOSE
			mul		[now_track]
			mov		bx,ax
			add		bx,offset dec_buf
			mov		[bx].dec_flag,FALSE
			ret
mml_decompose_end	endp

;---------------- [E0] fade out
mml_fadeout	proc
			mov		ah,14h
			xor		bx,bx
			mov		bl,es:[di]
			inc		di
			int		50h
			ret
mml_fadeout	endp

;---------------- [E1] ECM機能
mml_ecm		proc
			push	bp

			mov		bx,di					; bx=E1Hの次のPOINTER
			xor		dx,dx
			mov		dh,es:[di+2]			; dx=DRV-Type
			mov		ax,es:[di+3]			; ax=length
			add		di,5					; CONTROLL-ID部
			add		di,ax					; MESSAGE部のSKIP
			push	di

			xor		bp,bp
			mov		si,offset module_drv
			mov		cx,16
			cld
		mml_ecm_next:
			push	es
			lodsw
			or		ax,ax
			jz		mml_ecm_loop
			mov		es,ax
			cmp		es:[DRVTYPE],dx
			jnz		mml_ecm_loop
			mov		ax,bp
			mov		ah,00h
			pop		es
			call	call_driver
			jmp		mml_ecm_loop2
		mml_ecm_loop:
			pop		es
		mml_ecm_loop2:
			inc		bp
			loop	mml_ecm_next

			pop		di
			pop		bp
			ret
mml_ecm		endp

;---------------- [E2] fine of music play
mml_fine	proc
			mov		[si].use_flag,FALSE			; トラックを OFF にするだけ
			push	si
			
			mov		cx,MAXTRACK
			mov		si,offset track_buf
	mml_fine_next:
			cmp		[si].use_flag,TRUE			; まだ演奏中
			jz		mml_fine_end
			add		si,type DDN_CHBUF
			loop	mml_fine_next

			cmp		[infinity_play],TRUE
			jz		mml_infinity_play
			mov		ah,11h
			int		50h							; 演奏終了
			jmp		mml_fine_end
	mml_infinity_play:
			mov		ah,11h
			int		50h							; 演奏終了
			mov		ah,1ch
			int		50h							; 演奏さいかい
	mml_fine_end:
			pop		si

			ret
mml_fine	endp

;\@KILL
			end
;\@END
