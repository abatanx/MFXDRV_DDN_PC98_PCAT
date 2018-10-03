;
; Timer Driver Standerd I/O Header file.
;

init_timer	macro
			local	end_macro
			mov		al,[timer_drv]
			mov		ah,1
			mov		[timer_status],TIMER_OFF
			call	call_driver
	end_macro:
			endm

timer_settempo	macro	tempo
			local	end_macro
			mov		al,[timer_drv]
			mov		ah,2
			mov		bx,tempo
			call	call_driver
	end_macro:
			endm

timer_start	macro
			local	end_macro
			mov		al,[timer_drv]
			mov		ah,3
			call	call_driver
			mov		[timer_status],TIMER_ON
	end_macro:
			endm

timer_virtual_start	macro
			mov		[timer_status],TIMER_ON
			endm

timer_stop	macro
			local	end_macro
			mov		al,[timer_drv]
			mov		ah,4
			call	call_driver
			mov		[timer_status],TIMER_OFF
	end_macro:
			endm

set_timebase macro
			local	end_macro
			mov		al,[timer_drv]
			mov		ah,5
			call	call_driver
	end_macro:
			endm
