;==============================================================================
; MFXDDN timer driver module
;                                                       Interval timer driver DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			dosseg
			.186
			.model  tiny
			.code

include         stdio.inc
include         ddn.inc

DOSV                    =               TRUE
LOCAL_STACKSIZE         =               512                             ; Local Stack size

; 参考文献/杉浦明美,柴崎忠夫:"DOS/Vプログラミング技法",翔泳社 1993
if      DOSV    eq              TRUE
CTL8259         equ             20h
DTA8259         equ             02h
CTL8253         equ             43h
DTA82530        equ             40h
TIMER_MASK      equ             01h
EOI                     equ             20h
else                            ; 一応98でも動作するようにしとこっと(ｳﾁで動作確認)
CTL8259         equ             00h
DTA8259         equ             02h
CTL8253         equ             77h
DTA82530        equ             71h
TIMER_MASK      equ             01h
EOI                     equ             20h
endif

CYCLE           equ             128
;
;
;TCONST          equ             42667
;
;60*CYCLE*1000/(TEMPO*TIMEBASE*55)より
;60*1024*1000/55 = 1117090.909 = 1117091 = 110ba3H
;
;IF CYCLE==64 THEN
;TCONST_H        equ             0001h
;TCONST_L        equ             4d55h+1b00h
TCONST_H        equ             0002h
TCONST_L        equ             5a55h
;IF CYCLE==32 THEN
;TCONST_H		equ				0000h
;TCONST_L		equ				3000h
;

			org             100h
start:
			jmp             short com_start

;------------------------------------------------------------------------------
; ドライバーステータステーブル ddn.inc に準拠
;
DRVIDNUM                equ                     1011h
org     DRVTYPE 
				dtype           dw      TIMER_DEVICE
org     DRVID                                   ;       '----･----+----･',--h
				did                     db      'ITVALTIMERPC/AT',00h
org     DRVINIT
				dinit           dw      offset driver_init
org     DRVEND
				dend            dw      offset driver_end
org     DRVPLAY
				dplay           dw      NULL
org     DRVSTOP
				dstop           dw      NULL
org     DRVINT
				dint            dw      NULL
org     DRVCH
				dch                     db      ?
org     DRVUSECH
				dusech          db      ?
org     DRVVERINT
				dverint         db      1
org     DRVVERREAL
				dverreal        db      10
org     DRVINSTMSG
				dw                      offset dinstmsg
org     DRVUSEMSG
				dw                      offset dusemsg
org     DRVFUNC
;----------------- controll ---------------- no ----- comment -----------------
				dw      offset NULL                             ; 0h    ECM機能
				dw      offset init_timer               ; 1h    タイマー初期化
				dw      offset set_tempo                ; 2h    テンポの設定
				dw      offset timer_start              ; 3h    タイマー始動
				dw      offset timer_stop               ; 4h    タイマー停止
				dw      offset set_timebase             ; 5h    タイムベース設定
;------------------------------------------------------------------------------
.data

				even
TEMPO                   dw              ?                                       ; テンポ
TIMEBASE                dw              1                                       ; タイムベース
TEMPO_CLK_CONST dw      ?
TEMPO_CLK               dw      ?
REINT_FLAG              db      FALSE



			even
call_kernel             db              FALSE
ncount                  db              ?
counter                 db              ?

ddn_interrupt           label   dword           ; 常時割り込みジャンプ先
ddn_interrupt_ofs       dw      ?
ddn_interrupt_seg       dw      ?

int08_vector            label   dword           ; もとのタイマ割り込み
int08_offset            dw              0
int08_segment           dw              0

			even
timer_switch            db              0                       ; タイマー状態(ON/OFF)
timer_reint             dw              FALSE           ; タイマー割り込み再入チェック
timer_reint_all         dw              FALSE

dinstmsg        db      'PC/AT(DOS/V) Interval timer driver version 0.50',CR
			db      'copyright (c) 1995 ABA / T.Kobayashi and Interfair'
			db      ' All Rights Reserved.',CR,'$'
dusemsg         db      'Interval Timer を使用して演奏します。$'


.code

;------------------------------------------------------------------------------
;ＤＯＳ割り込み時に表示するメッセージ
com_start       proc
			mov             ax,cs
			mov             ds,ax
			_puts   'Usage : mld.exe itvtimv.xdv'
			_exit   NULL
com_start       endp

;------------------------------------------------------------------------------
;タイマー割り込み開始(kernel呼び出しok)
timer_on        proc
			mov             cs:[call_kernel],TRUE
			ret
timer_on        endp

;------------------------------------------------------------------------------
;タイマー割り込み禁止(kernel呼び出し不可)
timer_off       proc
			mov             cs:[call_kernel],FALSE
			ret
timer_off       endp

;------------------------------------------------------------------------------
;常駐時に実行するドライバー初期化
driver_init     proc    far
			pushf
			cli

			call    timer_off

			in              al,DTA8259
			or              al,TIMER_MASK
			out             DTA8259,al
			sti

			mov             ax,3508h
			int             21h
			mov             [int08_offset],bx
			mov             [int08_segment],es
			mov             dx,offset interrupt_tmdev
			mov             ax,2508h
			int             21h

			mov             al,36h
			out             CTL8253,al
			mov             cx,CYCLE
			mov             [ncount],cl
			xor             ax,ax
			mov             [counter],al
			mov             dx,1
			div             cx
			out             DTA82530,al
			mov             al,ah
			out             DTA82530,al
			
			cli
			in              al,DTA8259
			and             al,not TIMER_MASK
			out             DTA8259,al
			sti

			_puts   'int 08h をフックしました。'
			mov             ax,1            ; タイマーは１個ということで...
			popf
			ret
driver_init     endp

;------------------------------------------------------------------------------
;ドライバー解放終了初期化
driver_end      proc    far                     ; DDN 呼出なので FAR CALL
			cli
			in              al,DTA8259
			or              al,TIMER_MASK
			out             DTA8259,al
			sti
			
			lds             dx,int08_vector
			mov             ax,2508h
			int             21h
			
			mov             al,36h
			out             CTL8253,al
			xor             ax,ax
			out             DTA82530,al
			mov             al,ah
			out             DTA82530,al

			cli
			in              al,DTA8259
			and             al,not TIMER_MASK
			out             DTA8259,al
			sti
			ret
driver_end      endp

;------------------------------------------------------------------------------
;割り込み処理           たいまわりこみでここにくるのぉ。
interrupt_tmdev         proc
			pushf
			cmp             cs:[call_kernel],FALSE
			jz              reinterrupting

			dec             cs:[TEMPO_CLK]
			jnz             reinterrupting
			cmp             cs:[REINT_FLAG],FALSE
			jz              call_kernel_main
			mov             cs:[TEMPO_CLK],1                ; ごまかし
			jmp             reinterrupting
	call_kernel_main:
			mov             cs:[REINT_FLAG],TRUE

			push			ax
			mov				cs:[STACK_SS],ss
			mov				cs:[STACK_SP],sp
			mov				ax,cs
			mov				ss,ax
			mov				sp,offset LOCAL_STACK-2
			push_all
			mov             ax,cs
			mov             ds,ax
			mov             ax,[TEMPO_CLK_CONST]
			mov             [TEMPO_CLK],ax
			call    dword ptr cs:[ddn_interrupt]
			mov             cs:[REINT_FLAG],FALSE
			pop_all
			mov				ax,cs:[STACK_SS]
			mov				ss,ax
			mov				sp,cs:[STACK_SP]
			pop				ax
	reinterrupting:
if	DOSV	eq	TRUE
			dec             cs:[counter]
			jnz             not_systemcall

			push			ax
			mov             al,cs:[ncount]
			mov             cs:[counter],al
			pop             ax
			popf
			jmp             dword ptr cs:[int08_vector]
endif
		not_systemcall:
			cli
			push			ax
			mov             al,EOI
			out             CTL8259,al
			pop             ax
			popf
			iret
interrupt_tmdev         endp

;------------------------------------------------------------------------------
;テンポ設定
set_tempo_main          proc
			mov             ax,[TEMPO]
			mov             bx,[TIMEBASE]
			mul             bx
			
			mov             bx,ax
			mov             dx,TCONST_H
			mov             ax,TCONST_L
			div             bx
			or				ax,ax
			jnz				stm_ok
			mov				ax,1
	stm_ok:
			mov             [TEMPO_CLK_CONST],ax
			mov				[TEMPO_CLK],ax
			ret
set_tempo_main          endp

;---------------------------- Timer Function  proc.(00) タイマー初期化
;       es:bx  = MFXDDN 割り込み先アドレス
;ret@ax
;       NULL    初期化完了
;       ?               初期化できなかった
;
init_timer      proc    far
			mov             [ddn_interrupt_ofs],bx
			mov             [ddn_interrupt_seg],es
			mov             ax,NULL
			ret
init_timer      endp

;---------------------------- Timer Function  proc.(01) テンポ設定
;       bx     = テンポ(1..65535)
;
set_tempo       proc    far
			mov     [TEMPO],bx
			call    set_tempo_main
			ret
set_tempo       endp

;---------------------------- Timer Function  proc.(02) タイマー始動
;
timer_start     proc    far
			mov             [call_kernel],TRUE
			mov             [TEMPO_CLK],1
			ret
timer_start     endp

;---------------------------- Timer Function  proc.(03) タイマー停止
;
timer_stop      proc    far
			mov             [call_kernel],FALSE
			ret
timer_stop      endp

;---------------------------- Timer Function  proc.(04) タイムベース
;
set_timebase    proc    far
			mov             [TIMEBASE],bx
			call    set_tempo_main
			ret
set_timebase    endp

STACK_SP			dw		?
STACK_SS			dw		?
LOCAL_STACK_MAIN	dw		LOCAL_STACKSIZE dup(0)
LOCAL_STACK			label	word

			db		'Special Thanx to M.Yoshinaga(yoshix)',CR
			db		'TakoHG-R         M.Isogai',CR

			end             start

