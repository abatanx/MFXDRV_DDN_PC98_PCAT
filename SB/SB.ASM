;==============================================================================
; MFXDDN sound driver module
;                       YAMAHA YM3812 FM(OPL2) driver (Sound Braster) for DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.186
			.model  tiny
			.code

include         stdio.inc
include         ddn.inc
include         option.inc
include         usertool.inc
include         sb.inc
include         sbfunc.inc
include         sbterm.inc

			.code
			assume  cs:@code,ds:@code
			org             100h
start:
			jmp             near ptr com_start

;------------------------------------------------------------------------------
; ÉhÉâÉCÉoÅ[ÉXÉeÅ[É^ÉXÉeÅ[ÉuÉã ddn.inc Ç…èÄãí
;
org     DRVTYPE 
				dtype           dw      NORMAL_DEVICE
org     DRVID
				did                     db      'OPL2           ',00h
org     DRVINIT
				dinit           dw      offset driver_init
org     DRVEND
				dend            dw      offset driver_end
org     DRVPLAY
				dplay           dw      offset driver_play
org     DRVSTOP
				dstop           dw      offset driver_stop
org     DRVINT
				dint            dw      NULL
org     DRVCH
				dch                     db      MAXCHANNEL
org     DRVUSECH
				dusech          db      MAXCHANNEL
org     DRVVERINT
				dverint         db      ver_int
org     DRVVERREAL
				dverreal        db      ver_real
org     DRVINSTMSG
				dw                      offset dinstmsg
org     DRVUSEMSG
				dw                      offset dusemsg
org     DRVFUNC 
;----------------- controll ---------------------------------------------------
				dw                      offset opl2_ecm
				dw                      offset opl2_note_off
				dw                      offset opl2_note_on
				dw                      offset opl2_poly_keypress
				dw                      offset opl2_bank_select
				dw                      offset opl2_modulation
				dw                      offset opl2_pol_time
				dw                      offset opl2_data_entry
				dw                      offset opl2_volume
				dw                      offset opl2_panpot
				dw                      offset opl2_expression
				dw                      offset opl2_hold1
				dw                      offset opl2_poltament
				dw                      offset opl2_sostenuto
				dw                      offset opl2_soft
				dw                      offset opl2_pol_ctrl
				dw                      offset opl2_effect1
				dw                      offset opl2_effect3
				dw                      offset opl2_nrpn
				dw                      offset opl2_rpn 
				dw                      offset opl2_prog_chg
				dw                      offset opl2_ch_presser
				dw                      offset opl2_pitchbend
				dw                      offset opl2_all_soundoff
				dw                      offset opl2_all_resetctrler
				dw                      offset opl2_all_noteoff
				dw                      offset opl2_omni_off
				dw                      offset opl2_omni_on
				dw                      offset opl2_mono
				dw                      offset opl2_poly
				dw                      offset opl2_active_sence
				dw                      offset opl2_exclusive
				dw                      offset opl2_vibrato
				dw                      offset opl2_master_volume
;------------------------------------------------------------------------------
				even
.data

even
volume_buf              db              MAXCHANNEL dup(?)
exp_buf                 db              MAXCHANNEL dup(?)
velo_buf                db              MAXCHANNEL dup(?)
notestatus              db              MAXCHANNEL dup(?)
mastervol               db              ?
volumerevision  db              ?
pitch                   dw              MAXCHANNEL dup(?)
fnumber1                db              MAXCHANNEL dup(?)
fnumber2                db              MAXCHANNEL dup(?)
KSLTL                   db              MAXCHANNEL dup(?)
lfo                     MODTABLE        MAXCHANNEL dup(?)
volumedown              db              0

if	DOSV	eq	TRUE
SBBASE                  dw              220h
else
SBBASE					dw				20d2h
endif

OPL2PORT1               dw              ?
OPL2PORT2               dw              ?
OPL2MIXER1              dw              ?
OPL2MIXER2              dw              ?

CHTBL                   db              0,1,2, 8 , 9,10, 16,17,18
;                                       3,4,5, 11,12,13, 19,20,21
even
soundtblmax             dw                      ?
soundtbl                OPL2TONE        MAXSOUND dup(?)

if	DOSV	eq		TRUE
dinstmsg    db      'PC/AT Sound Blaster(YM3812) driver version '
else
dinstmsg	db		'[32mPC98 [33mSound Blaster(YM3812) driver[m version '
endif
			db      '0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db      'copyright (c) 1995 ABA / T.Kobayashi and Interfair '
			db      'All Rights Reserved.',CR,'$'
dusemsg         db      'OPL2 ÇëÄçÏÇ∑ÇÈÇÀÅ[ ver.'
			db      '0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db      '$'
.code

;------------------------------------------------------------------------------
crlf            proc
			mov             ah,02h
			mov             dl,0dh
			int             21h
			mov             ah,02h
			mov             dl,0ah
			int             21h
			ret
crlf            endp

;------------------------------------------------------------------------------
;èÌéûäÑÇËçûÇ›ïîï™
driver_timer_interrupt  proc    far
			ret
driver_timer_interrupt  endp

;------------------------------------------------------------------------------
;ÉtÉ@ÉìÉNÉVÉáÉìÉGÉâÅ[
opl2_func_error proc    far
			ret
opl2_func_error endp

;------------------------------------------------------------------------------
; OPL2èâä˙âªÇ…Ç·ÇÃÅB
init_opl2       proc
			mov             cx,MAXCHANNEL
			xor             ah,ah
	de_loop:
			push    ax
			call    init_opl2sound
			pop             ax
			inc             ah
			loop    de_loop

			ret
init_opl2       endp

;------------------------------------------------------------------------------
;ÉhÉâÉCÉoÅ[âï˙èIóπèâä˙âª
driver_end      proc    far                             ; MLD åƒÇ—èoÇµÇÕ FAR ÇæÇÊÅB
			call    init_opl2
			ret
driver_end      endp

;------------------------------------------------------------------------------
;èÌíìéûÇ…é¿çsÇ∑ÇÈÉhÉâÉCÉoÅ[èâä˙âª
driver_init     proc    far                             ; MLD åƒÇ—èoÇµÇÕ FAR ÇæÇÊÅB

;ÉIÉvÉVÉáÉìÉ`ÉFÉbÉN=====
; /io=xxxxh
			option  'io',VALUE_PARAM,@fast11,error_opt
			mov             SBBASE,ax
@fast11:
			mov             ax,SBBASE
			mov             OPL2PORT1,SB_OPL2PORT1
			add             OPL2PORT1,ax
			mov             OPL2PORT2,SB_OPL2PORT2
			add             OPL2PORT2,ax
			mov             OPL2MIXER1,SB_OPL2MIXERPORT1
			add             OPL2MIXER1,ax
			mov             OPL2MIXER2,SB_OPL2MIXERPORT2
			add             OPL2MIXER2,ax

			_put    'Sound Braster BASE adr = '
			puthex_16reg    SBBASE
			_puts   'H'

			_put    'FM(OPLx) DATA/STATUS   = '
			puthex_16reg    OPL2PORT1
			_puts   'H'
			_put    'FM(OPLx) ADDRESS       = '
			puthex_16reg    OPL2PORT2
			_puts   'H'

			_put    'FM(OPLx) MIXER DATA    = '
			puthex_16reg    OPL2MIXER2
			_puts   'H'
			_put    'FM(OPLx) MIXER REGISTER= '
			puthex_16reg    OPL2MIXER1
			_puts   'H'

; /v=xxx
			option  'v',VALUE_PARAM,@mv,error_opt
			cmp             ax,128
			jb              vol_ok
			_puts   '/v=xxx ÇÃéwíËÇ™ïsê≥Ç≈Ç∑(0Å`127)ÅB'
			jmp             @fast1
vol_ok:
			mov             [volumedown],al
			_puts   'OPL2ÇÃâπó Çê›íËÇµÇ‹ÇµÇΩÅB'

; /mv
	@mv:
			option  'mv',VALUE_PARAM,@fmv,error_opt
			cmp             ax,256
			jb              master_vol_ok
			_puts   '/mv=xxx ÇÃéwíËÇ™ïsê≥Ç≈Ç∑(00hÅ`0ffh)ÅB'
			jmp             @fmv
master_vol_ok:
			mov				bl,al
			mov             bh,22h
			call    write_opl2mixreg
			_puts   'MIXER:MASTER VOLUME Çê›íËÇµÇ‹ÇµÇΩÅB'

; /fmv
	@fmv:
			option  'fmv',VALUE_PARAM,@fast1,error_opt
			cmp             ax,256
			jb              fm_vol_ok
			_puts   '/fmv=xxx ÇÃéwíËÇ™ïsê≥Ç≈Ç∑(00hÅ`0ffh)ÅB'
			jmp             @fast1
fm_vol_ok:
			mov				bl,al
			mov             bh,26h
			call    write_opl2mixreg
			_puts   'MIXER:FM VOLUME Çê›íËÇµÇ‹ÇµÇΩÅB'

; /id=xxxx
	@fast1:
			option  'id',STR_PARAM,@fast,error_opt
			push    ds
			mov             ax,es
			mov             ds,ax
			mov             ax,cs
			mov             es,ax
			mov             si,bx
			mov             di,offset did
			
			mov             cx,15
			cld
			mov             al,' '
			rep             stosb
			
			mov             di,offset did
			mov             cx,15
	@@2loop:
			lodsb
			or              al,al
			jz              @@2end
			stosb
			loop    @@2loop
	@@2end:
			pop             ds
			_puts   'DRIVER-ID ÇïœçXÇµÇ‹ÇµÇΩÅB'
			jmp             @fast

	error_opt:
			_puts   'ÉpÉâÉÅÅ[É^Ç™à·Ç¢Ç‹Ç∑ÅB'
	@fast:
			call    check_opl2              ; OPL2É`ÉFÉbÉN
			jb              not_stay_opl2   ; OPL2Ç»ÇµÅBÇÆÅ[ÅB

if      FORCE   eq      FALSE
			mov             dx,SB_DSP_RESET
			add             dx,SBBASE
			mov             al,1
			_out            dx,al
			mov             cx,10000
			call    wa

			mov             dx,SB_DSP_RESET
			add             dx,SBBASE
			mov             al,0
			_out            dx,al
			mov             cx,10000
			call    wa

			mov             cx,10000
			mov             dx,SB_DSP_STATUS
			add             dx,SBBASE
	k_kp:
			in              al,dx
			jmp             $+2
			jmp             $+2
			jmp             $+2
			test    al,80h
			jnz             k_off
			loop    k_kp
			jmp             not_stay_opl2
	k_off:
			mov             dx,SB_DSP_READ
			add             dx,SBBASE
			in              al,dx
			cmp             al,0aah
			jnz             not_stay_opl2

			call    init_opl2

			mov             dx,SB_DSP_WRITESTATUS
			add             dx,SBBASE
	d1w:    in              al,dx
			test    al,80h
			jnz             d1w
endif
			mov             dx,SB_DSP_WRITE
			add             dx,SBBASE
			mov             al,0d1h
			_out    dx,al

			mov             bx,0120h
			call    write_opl2reg
			mov             bx,0800h
			call    write_opl2reg
	
			mov		cx,MAXCHANNEL
			xor		ah,ah
	eini:
			push	cx
			push	ax
			call	init_opl2sound
			pop		ax
			pop		cx
			inc		ah
			loop	eini

			mov             ax,MAXCHANNEL   ; Ç”Ç–Ç–Ç–Ç–
			ret
	not_stay_opl2:
			mov             ax,0
			ret
driver_init     endp

;OPL2ÇÃÉ`ÉFÉbÉN
check_opl2      proc
			mov             cx,10000                ; 1ñúâÒÇøÇ•Ç¡Ç≠Å`
	lp_co:
			mov             dx,OPL2PORT1
			in              al,dx
			cmp             al,0ffh
			jnz             stay_opl2
			loop    lp_co
if      FORCE   eq      FALSE
			stc
else
			clc
endif
			ret
	stay_opl2:
			clc
			ret
check_opl2      endp

;------------------------------------------------------------------------------
;ââëtäJénéûÇ…é¿çsÇ∑ÇÈÇ∆Ç±
driver_play     proc    far                     ; DDNåƒèoÇÕ FAR ÇæÇÊ
			call    init_opl2
			call    init_opl2buf
			ret
driver_play     endp

;------------------------------------------------------------------------------
;ââëtèIóπéûÇ…é¿çsÇ∑ÇÈÇ∆Ç±
driver_stop     proc    far                     ; DDNåƒèoÇÕ FAR ÇæÇÊ
            call    init_opl2
			ret
driver_stop     endp

;------------------------------------------------------------------------------
;ÇcÇnÇrÇ©ÇÁÇÃé¿çséûÇ…ï\é¶Ç∑ÇÈÉÅÉbÉZÅ[ÉW
com_start       proc
			_exit   NULL
com_start       endp

			end             start
