echo off
mfxddn
pcm86 -T -DF -DP -E -VP10
mld pcm86,itvtimer,ssg,opn,opna,ff
p86play -N -T100 bass.pc8
p86play -N -T101 snare.pc8
p86play -N -T102 cymbal.pc8
p86play -N -T103 hihat.pc8
mip sample
