# 
# �V�X�e���f�B���N�g������INCLUDE�t�@�C��
# makefile copyright (c) 1994,95 by ABA  all rights reserved.
#                                                               Interfair 1994.

#
# ���ɍ��킹�āA�ȉ���ݒ肵�Ăˁ�
#

#
# �f�B���N�g�� / ���������f���ݒ�
#
INCLUDE		= a:\msc\include		# C-Compiler �� INCLUDE�f�B���N�g��
lib			= a:\msc\lib			# ���C�u����������ɃR�s�[����ꏊ
kernel		= b:\mfxddn\kernel		# MFXDRV/DDN�\�[�X�̓������f�B���N�g��
memmodel	= 2						# �������[���f��
									#   (          1:small 2:medium
									#    3:compact 4:large 5:huge  )

#
# ----- �R���p�C����
#
# ���R���p�C���I�v�V�����ɂ́A���Ȃ炸�s�\���̂̃A���C�������g = 1byte�t
# �ɐݒ肵�ĉ�����(MS-C�̏ꍇ�� /Zp1, TCC�̓f�t�H���g)
#
CompilerSw	= C_MSC					#	Turbo-C:		C_TC
									#	Borland-C:		C_BC
									#	Microsoft-C:	C_MSC
Compiler	= cl					# �R���p�C��
CompilerOpt = /Ox /G1 /Zl /c /Zp1 /D__DDN_BUILT__ /D$(CompilerSw) /I$(INCLUDE)
									# �R���p�C���I�v�V����
TinyOpt     = /AS					# C compiler�ł� tiny ���I�v�V����
SmallOpt    = /AS					# C compiler�ł� small���I�v�V����
MediumOpt   = /AM					# C compiler�ł� meduim���I�v�V����
CompactOpt  = /AC					# C compiler�ł� compact���I�v�V����
LargeOpt    = /AL					# C compiler�ł� large���I�v�V����
HugeOpt     = /AH					# C compiler�ł� huge���I�v�V����

Assembler	= tasm					# �A�Z���u��
AssemblerOpt= /t /mx /m /z			# �A�Z���u���I�v�V����

Librarian	= tlib					# ���C�u�����A��

# ----- ���C�u������
Masterlib	= 1						# master.lib�Ή��ł̊֐����쐬����
									# 0:���Ȃ� 1:����
Kernel		= 1						# MFXDRV/DDN �J�[�l����LIB�ł��쐬����
									# 0:���Ȃ� 1:����

# ��Master.lib �Ή��ł��쐬����ꍇ�Amaster.h ���K�v�ł��B
# ���܂��A��̃I�v�V�����̂ǂ��炩�� [���Ȃ�] �ɂ����ꍇ�A
#   ���C�u�����쐬���� Warning ���������܂����A�������ĉ������B
#   �����A�C�ɂȂ�ꍇ�́Aobject �Ƃ����t�@�C������A�Y���t�@�C����
#   �L�q���폜���ĉ������B
