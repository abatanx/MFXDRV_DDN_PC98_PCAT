;==============================================================================
; PCM86 (C)はぜがわまき mfxdrv/ddn 組み込みドライバ
;==============================================================================

version_int		equ		0
version_real	equ		30
version_release	equ		' '

version			equ		'0'+version_int,'.','0'+version_real/10,'0'+version_real mod 10,version_release

STATUS_DRVTYPE	equ		NORMAL_DEVICE
STATUS_DRVID	equ		'PCM86          ',00h
STATUS_DRVCH	equ		3
STATUS_DRVUSECH	equ		3

PCM86			equ		0F4h

global	func_ecm				:far
global	func_note_off			:far
global	func_note_on			:far
global	func_poly_keypress		:far
global	func_bank_select		:far
global	func_modulation			:far
global	func_pol_time			:far
global	func_data_entry			:far
global	func_volume				:far
global	func_panpot				:far
global	func_expression			:far
global	func_hold1				:far
global	func_poltament			:far
global	func_sostenuto			:far
global	func_soft				:far
global	func_pol_ctrl			:far
global	func_effect1			:far
global	func_effect3			:far
global	func_nrpn				:far
global	func_rpn				:far
global	func_prog_chg			:far
global	func_ch_presser			:far
global	func_pitchbend			:far
global	func_all_soundoff		:far
global	func_all_resetctrler	:far
global	func_all_noteoff		:far
global	func_omni_off			:far
global	func_omni_on			:far
global	func_mono				:far
global	func_poly				:far
global	func_active_sence		:far
global	func_exclusive			:far
global	func_vibrato			:far
global	func_master_volume		:far

global	pcm_entry_init			:near
global	dusech					:byte
