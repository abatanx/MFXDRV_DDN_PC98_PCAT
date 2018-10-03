;==============================================================================
; MFXDDN sound driver module
;		MIDI Interface driver for Sound Braster(MIDI I/F) DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc

include		sbmidi.inc
include		sbmdterm.inc
include		sbmdfunc.inc

.code
			org		100h
start:
			jmp		short com_start

;------------------------------------------------------------------------------
; ƒhƒ‰ƒCƒo[ƒXƒe[ƒ^ƒXƒe[ƒuƒ‹ ddn.inc ‚É€‹’
;
org	DRVTYPE	
				dtype		dw	NORMAL_DEVICE
org	DRVID
				did			db	'MIDI           ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	offset driver_end
org	DRVPLAY
				dplay		dw	offset driver_play
org	DRVSTOP
				dstop		dw	offset driver_stop
org	DRVINT
				dint		dw	NULL
org	DRVCH
				dch			db	16
org	DRVUSECH
				dusech		db	16
org	DRVVERINT
				dverint		db	ver_int
org	DRVVERREAL
				dverreal	db	ver_real
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC	
;----------------- controll ---------------------------------------------------
				dw			offset NULL
				dw			offset midi_note_off
				dw			offset midi_note_on
				dw			offset midi_poly_keypress
				dw			offset midi_bank_select
				dw			offset midi_modulation
				dw			offset midi_pol_time
				dw			offset midi_data_entry
				dw			offset midi_volume
				dw			offset midi_panpot
				dw			offset midi_expression
				dw			offset midi_hold1
				dw			offset midi_poltament
				dw			offset midi_sostenuto
				dw			offset midi_soft
				dw			offset midi_pol_ctrl
				dw			offset midi_effect1
				dw			offset midi_effect3
				dw			offset midi_nrpn
				dw			offset midi_rpn	
				dw			offset midi_prog_chg
				dw			offset midi_ch_presser
				dw			offset midi_pitchbend
				dw			offset midi_all_soundoff
				dw			offset midi_all_resetctrler
				dw			offset midi_all_noteoff
				dw			offset midi_omni_off
				dw			offset midi_omni_on
				dw			offset midi_mono
				dw			offset midi_poly
				dw			offset midi_active_sence
				dw			offset midi_exclusive
				dw			offset midi_vibrato
				dw			offset midi_master_volume
;------------------------------------------------------------------------------
.data
dinstmsg	db	'PC/AT Sound Braster MIDI interface driver for GS/GM module [mversion '
			db	'0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db	'copyright (c) 1995 ABA / T.Kobayashi and Interfair'
			db	' All Rights Reserved.',CR,'$'
dusemsg		db	'MIDI ‚Å‰‰‘t‰Â”\‚Å‚· MIDI.XDV ver.'
			db	'0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db	'$'

					even
MODULE				dw	GS_MODULE

progchg			dw	TRUE					; ƒvƒƒOƒ‰ƒ€ƒ`ƒFƒ“ƒWƒtƒ‰ƒO
volume_buf		dw	16 dup(?)				; ƒ{ƒŠƒ…[ƒ€ƒoƒbƒtƒ@
mastervol_buf	dw	?						; masterƒ{ƒŠƒ…[ƒ€ƒoƒbƒtƒ@
SBBASE			dw	220h
DSP_RESET		dw	226h
DSP_READ		dw	22ah
DSP_DATA		dw	22ch
DSP_COMMAND		dw	22ch
DSP_WSTATUS		dw	22ch
DSP_DSTATUS		dw	22eh

.code
;------------------------------------------------------------------------------
sbwait		proc
			push	cx
			mov		cx,100
	f:
			jmp		$+2
			loop	f
			pop		cx
			ret
sbwait		endp

;------------------------------------------------------------------------------
;‚c‚n‚rŠ„‚è‚İ‚É•\¦‚·‚éƒƒbƒZ[ƒW
com_start	proc
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;ƒhƒ‰ƒCƒo[‰ğ•úI—¹‰Šú‰»
driver_end	proc	far			; DDN ŒÄo‚È‚Ì‚Å FAR CALL
	DEND_NEXT:
			mov		al,0ffh
			call	midi_out
			ret
driver_end	endp

;------------------------------------------------------------------------------
;í’“‚ÉÀs‚·‚éƒhƒ‰ƒCƒo[‰Šú‰»
driver_init	proc	far
	; ƒf[ƒ^ƒoƒbƒtƒ@‚Ì‰Šú‰»
			call	init_databuf

;œƒIƒvƒVƒ‡ƒ“‚Ì‚¿‚¥‚Á‚­` =============================
;¦ USAGE
error_opt:
			option	'?',NO_PARAM,@@p,error_opt_error
error_opt_error:
			_print	usage
			mov		ax,NULL
			ret

;¦ /P ƒIƒvƒVƒ‡ƒ“‚Ìƒ`ƒFƒbƒN‚Å[[‚·B----------
	@@p:
			option	'p',NO_PARAM,@@io,error_opt
			mov		[progchg],FALSE
			_puts	'‚·‚×‚Ä Piano ‚Å‰‰‘t‚µ‚Ü‚·B'

;¦ /IO:xxxxH ƒIƒvƒVƒ‡ƒ“‚Ìƒ`ƒFƒbƒN‚Å[[‚·B----------
	@@io:
			option	'io',VALUE_PARAM,@@id,error_opt
			mov		[SBBASE],ax
			mov		[DSP_RESET],06h
			add		[DSP_RESET],ax
			mov		[DSP_READ],0ah
			add		[DSP_READ],ax
			mov		[DSP_COMMAND],0ch
			add		[DSP_COMMAND],ax
			mov		[DSP_DATA],0ch
			add		[DSP_DATA],ax
			mov		[DSP_WSTATUS],0ch
			add		[DSP_WSTATUS],ax
			mov		[DSP_DSTATUS],0eh
			add		[DSP_DSTATUS],ax
			_puts	'Sound Braster ‚Ì I/O ƒAƒhƒŒƒX‚ğ•ÏX‚µ‚Ü‚µ‚½B'

;¦ /ID ƒIƒvƒVƒ‡ƒ“‚Ìƒ`ƒFƒbƒN‚Å[[‚·B----------------
	@@id:
			option	'id',STR_PARAM,@@gm,error_opt
			push	ds
			mov		ax,es
			mov		ds,ax
			mov		ax,cs
			mov		es,ax
			mov		si,bx
			mov		di,offset did
			
			mov		cx,15
			cld
			mov		al,' '
			rep		stosb
			
			mov		di,offset did
			mov		cx,15
	@@2loop:
			lodsb
			or		al,al
			jz		@@2end
			stosb
			loop	@@2loop
	@@2end:
			pop		ds
			_puts	'DRIVER-ID ‚ğ•ÏX‚µ‚Ü‚µ‚½B'

; ¦ /GMƒIƒvƒVƒ‡ƒ“ƒ`ƒFƒbƒN
	@@gm:
			option	'gm',NO_PARAM,@@gs,error_opt
			mov		[MODULE],GM_MODULE
			_puts	'GM‰¹Œ¹‚ğg—p‚µ‚Ü‚·B'
			jmp		sbchk

; ¦ /GSƒIƒvƒVƒ‡ƒ“ƒ`ƒFƒbƒN ---------------------------
	@@gs:
			option	'gs',NO_PARAM,sbchk,error_opt
	set_gs:
			mov		[MODULE],GS_MODULE
			_puts	'GS‰¹Œ¹‚ğg—p‚µ‚Ü‚·B'
			jmp		sbchk

; Sound Braster check --------------------------------
	sbchk:
			_put    'Sound Braster BASE adr = '
			puthex_16reg    SBBASE
			_puts   'H'

			_put    'DSP RESET PORT    = '
			puthex_16reg    DSP_RESET
			_puts   'H'
			_put    'DSP READ  DATA    = '
			puthex_16reg    DSP_READ
			_puts   'H'
			_put    'DSP WRITE DATA    = '
			puthex_16reg    DSP_DATA
			_puts   'H'
			_put    'DSP WRITE COMMAND = '
			puthex_16reg    DSP_COMMAND
			_puts   'H'
			_put    'DSP WRITE STATUS  = '
			puthex_16reg    DSP_WSTATUS
			_puts   'H'
			_put    'DSP DATA  STATUS  = '
			puthex_16reg    DSP_DSTATUS
			_puts   'H'
			_puts	'Checking Sound Blaster...'

			mov		cx,10000
			mov		dx,DSP_RESET
			mov		al,01h
			out		dx,al
			call	sbwait

			mov		dx,DSP_RESET
			mov		al,00h
			out		dx,al
			call	sbwait

		fa:	
			push	cx
			mov		cx,30000
			mov		dx,DSP_DSTATUS
		ff:	
			in		al,dx
			test	al,80h
			jnz		skip_a
			call	sbwait
			loop	ff
			pop		cx
			jmp		DSP_ERROR

		skip_a:
			pop		cx
			mov		dx,DSP_READ
			in		al,dx
			cmp		al,0aah
			jz		DSP_OK
			loop	fa
	
	DSP_ERROR:
			_puts	'Sound Braster‚ª“‹Ú‚³‚ê‚Ä‚¢‚Ü‚¹‚ñB'
			mov		ax,NULL
			ret

	DSP_OK:
			mov		dx,DSP_WSTATUS
			in		al,dx
			test	al,80h
			jnz		DSP_OK

			mov		dx,DSP_COMMAND
			mov		al,34h
			out		dx,al

			_puts	'Sound Braster MIDI I/F(UART)‚ªg—p‰Â”\‚Å‚·B'
			mov		ax,16
			ret
driver_init	endp

;------------------------------------------------------------------------------
;‰‰‘tŠJn‚ÉÀs‚·‚é‚Æ‚±
driver_play	proc	far			; DDNŒÄo‚È‚Ì‚Å FAR CALL
			push	ds
			push	si
			mov		ax,cs
			mov		ds,ax
			call	init_databuf
			cmp		[MODULE],GM_MODULE
			jz		dp_gm_buf
			mov		si,offset gs_initialize
			jmp		gp_send_start
	dp_gm_buf:
			mov		si,offset gm_initialize
	gp_send_start:
			call	send_initialize
			mov		si,offset global_initialize
			call	send_initialize
			pop		si
			pop		ds
			ret
	.data
gs_initialize:
			db	0f0h, 41h, 10h, 42h, 12h, 40h, 00h, 7fh, 00h, 41h,0f7h	; GS ON
			db	0feh, 0feh
gm_initialize:
			db	0f0h, 7eh, 7fh, 09h, 01h, 0f7h							; GM ON
			db	0feh, 0feh
global_initialize:
			db	0b0h, 7bh, 00h,0b0h, 78h, 00h,0b0h, 79h, 00h
			db	0b1h, 7bh, 00h,0b1h, 78h, 00h,0b1h, 79h, 00h
			db	0b2h, 7bh, 00h,0b2h, 78h, 00h,0b2h, 79h, 00h
			db	0b3h, 7bh, 00h,0b3h, 78h, 00h,0b3h, 79h, 00h
			db	0b4h, 7bh, 00h,0b4h, 78h, 00h,0b4h, 79h, 00h
			db	0b5h, 7bh, 00h,0b5h, 78h, 00h,0b5h, 79h, 00h
			db	0b6h, 7bh, 00h,0b6h, 78h, 00h,0b6h, 79h, 00h
			db	0b7h, 7bh, 00h,0b7h, 78h, 00h,0b7h, 79h, 00h
			db	0b8h, 7bh, 00h,0b8h, 78h, 00h,0b8h, 79h, 00h
			db	0b9h, 7bh, 00h,0b9h, 78h, 00h,0b9h, 79h, 00h
			db	0bah, 7bh, 00h,0bah, 78h, 00h,0bah, 79h, 00h
			db	0bbh, 7bh, 00h,0bbh, 78h, 00h,0bbh, 79h, 00h
			db	0bch, 7bh, 00h,0bch, 78h, 00h,0bch, 79h, 00h
			db	0bdh, 7bh, 00h,0bdh, 78h, 00h,0bdh, 79h, 00h
			db	0beh, 7bh, 00h,0beh, 78h, 00h,0beh, 79h, 00h
			db	0bfh, 7bh, 00h,0bfh, 78h, 00h,0bfh, 79h, 00h
			db	0ffh
	.code
driver_play	endp

;------------------------------------------------------------------------------
;‰‰‘tI—¹‚ÉÀs‚·‚é‚Æ‚±
driver_stop	proc	far			; DDNŒÄo‚È‚Ì‚Å FAR CALL
			push	ds
			push	si
			mov		ax,cs
			mov		ds,ax
			call	init_databuf
			mov		si,offset global_initialize
			call	send_initialize
			pop		si
			pop		ds
			ret
driver_stop	endp

;------------------------------------------------------------------------------
;ã‚Ìƒf[ƒ^‚ğ‚²‚è‚²‚èo—Í‚·‚é‚Æ‚±
send_initialize		proc
			cld
	si_next_ent:
			lodsb
			cmp		al,0ffh
			jz		si_exit
			cmp		al,0feh
			jz		si_next_wait
			call	midi_out
			jmp		si_next_ent
	si_next_wait:
			mov		cx,4000
			push	dx
	si_w:
			mov		dx,cs:DSP_WSTATUS
			in		al,dx
			in		al,dx
			in		al,dx
			in		al,dx
			loop	si_w
			pop		dx
			jmp		si_next_ent
	si_exit:
			ret
send_initialize		endp

.data
usage		db	'Usage  ; ',CR
			db	'         mld.exe sbmidi.xdv [option...]',CR
optionlist	db	'Option ; ',CR
			db	'         /gs       GS‰¹Œ¹‚ğg—p‚µ‚Ü‚·',CR
			db	'         /gm       GM‰¹Œ¹‚ğg—p‚µ‚Ü‚·',CR
ifdef	PC98
			db	'         /io=xxxxH MPU ‚ÌI/OƒAƒhƒŒƒX‚ğw’è‚µ‚Ü‚·(DEF:220H)',CR
elif
			db	'         /io=xxxxH MPU ‚ÌI/OƒAƒhƒŒƒX‚ğw’è‚µ‚Ü‚·(DEF:E0D0H)',CRendif
			db	'         /id=xxxx  DRIVER-ID ‚ğ•ÏX‚µ‚Ü‚·(DEF:MIDI)',CR
			db	'         /p        Piano ‰‰‘tƒ‚[ƒh',CR
			db	'         /?        ƒIƒvƒVƒ‡ƒ“‚ğ•\¦‚µ‚Ü‚·',CR
			db	CR
			db	'$'

					end	start
