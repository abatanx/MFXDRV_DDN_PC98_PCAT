echo off
mcv -c after.mid
lyric afterwd.lyr -o _after
ml after.sbj after.mbj afterwd.mbj
copy after.mud ..\test
cd ..\test
go after.mud
