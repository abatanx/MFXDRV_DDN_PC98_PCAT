;/////////////////////////////////////////////////////////////////////////////;
;
;      Multi module music driver MFXDDN(tm) kernel system release 0.00 
;  MFXDDN(tm) Music driver For XMML , Deconcentrate Drivers Network System
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;
;/////////////////////////////////////////////////////////////////////////////;
;
; 割り込み部
;
IF	PROGMODE		eq	COMTYPE
MFXDRVDDN_KERNEL	equ	TRUE
include		model.inc
include		stdio.inc
include		ddn.inc
include		timerdrv.inc
.code
ENDIF

firstclock	db		?

;-------- ドライバ呼出
;ah		ファンクションナンバー
;al		ドライバテーブルの番号
;
call_driver	proc
			push	ds
			push	es
			push	bx
			push	ax
			mov		bx,cs
			mov		ds,bx

			xor		bx,bx
			mov		bl,al
			shl		bx,1
			mov		bx,[module_drv + bx]
			or		bx,bx
			jz		cd_erout
	cd_call:
			mov		es,bx
			xor		bx,bx
			mov		bl,ah
			shl		bx,1
			mov		bx,es:[DRVFUNC + bx]
			or		bx,bx
			jz		cd_erout
			mov		[driver_call_ofs],bx
			mov		[driver_call_seg],es
			mov		bx,es
			mov		ds,bx				; ds を ドライバーの seg にしとく。

			pop		ax
			pop		bx
			pop		es
			push_all
			call	dword ptr cs:[driver_call]
			pop_all
			pop		ds
			ret

	cd_erout:
			pop		ax
			pop		bx
			pop		es
			pop		ds
			ret

			even
driver_call		label	dword
driver_call_ofs	dw		?
driver_call_seg	dw		?

call_driver	endp


;\@KILL
			end
;\@END
