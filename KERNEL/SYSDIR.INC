# 
# システムディレクトリ共通INCLUDEファイル
# makefile copyright (c) 1994 by ABA  all rights reserved.
#                                                               Interfair 1994.

#
# 各御家庭の環境に合わせて、以下を設定してね～。
#

prog		= b:					# 開発用ドライブ
									# このファイルがあるドライブです。
tmp			= k:					# 作業用ドライブ
lib			= a:\turboc\lib			# TCCのLIBが格納されているPATH
junktest	= b:\mfxddn\test		# ファイル生成後にコピーする場所

#
# lib      は、kernelの場合、とくに必要はありません。
# junktest は、ファイル作成後、勝手にコピーする場所です。
#
