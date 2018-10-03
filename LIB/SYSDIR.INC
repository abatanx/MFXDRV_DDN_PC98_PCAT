# 
# システムディレクトリ共通INCLUDEファイル
# makefile copyright (c) 1994,95 by ABA  all rights reserved.
#                                                               Interfair 1994.

#
# 環境に合わせて、以下を設定してね☆
#

#
# ディレクトリ / メモリモデル設定
#
INCLUDE		= a:\msc\include		# C-Compiler の INCLUDEディレクトリ
lib			= a:\msc\lib			# ライブラリ生成後にコピーする場所
kernel		= b:\mfxddn\kernel		# MFXDRV/DDNソースの入ったディレクトリ
memmodel	= 2						# メモリーモデル
									#   (          1:small 2:medium
									#    3:compact 4:large 5:huge  )

#
# ----- コンパイル環境
#
# ★コンパイルオプションには、かならず《構造体のアラインメント = 1byte》
# に設定して下さい(MS-Cの場合は /Zp1, TCCはデフォルト)
#
CompilerSw	= C_MSC					#	Turbo-C:		C_TC
									#	Borland-C:		C_BC
									#	Microsoft-C:	C_MSC
Compiler	= cl					# コンパイラ
CompilerOpt = /Ox /G1 /Zl /c /Zp1 /D__DDN_BUILT__ /D$(CompilerSw) /I$(INCLUDE)
									# コンパイルオプション
TinyOpt     = /AS					# C compilerでの tiny 環境オプション
SmallOpt    = /AS					# C compilerでの small環境オプション
MediumOpt   = /AM					# C compilerでの meduim環境オプション
CompactOpt  = /AC					# C compilerでの compact環境オプション
LargeOpt    = /AL					# C compilerでの large環境オプション
HugeOpt     = /AH					# C compilerでの huge環境オプション

Assembler	= tasm					# アセンブラ
AssemblerOpt= /t /mx /m /z			# アセンブラオプション

Librarian	= tlib					# ライブラリアン

# ----- ライブラリ環境
Masterlib	= 1						# master.lib対応版の関数も作成する
									# 0:しない 1:する
Kernel		= 1						# MFXDRV/DDN カーネルのLIB版を作成する
									# 0:しない 1:する

# ※Master.lib 対応版を作成する場合、master.h が必要です。
# ※また、上のオプションのどちらかを [しない] にした場合、
#   ライブラリ作成時に Warning が発生しますが、無視して下さい。
#   もし、気になる場合は、object というファイルから、該当ファイルの
#   記述を削除して下さい。
