@echo off
echo Making all model libraries.
echo [8m Builting Small model... [m
touch sysdir.inc
make -Dmemorymodel=1
echo [8m Builting Medium model... [m
touch sysdir.inc
make -Dmemorymodel=2
echo [8m Builting Compact model... [m
touch sysdir.inc
make -Dmemorymodel=3
echo [8m Builting Large model... [m
touch sysdir.inc
make -Dmemorymodel=4
echo [8m Builting Huge model... [m
touch sysdir.inc
make -Dmemorymodel=5
