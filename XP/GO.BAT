echo off
mfxddn
mld midi,itvtimer,ff >nul
if '%1'=='' goto nulparam
mip %1 >nul
goto go
:nulparam
mip sora88 >nul
:go
xp
mfxddn /r
