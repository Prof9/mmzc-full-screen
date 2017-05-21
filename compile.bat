@echo off
rmdir /S /Q out >nul
rmdir /S /Q temp >nul
mkdir temp >nul
if errorlevel 1 goto :error
mkdir out >nul
if errorlevel 1 goto :error

echo Extracting ROM...
tools\ndstool.exe -x mmzc-us.nds -9 temp\arm9.bin -7 temp\arm7.bin -d temp\data -y temp\overlay -h temp\header.bin -y9 temp\y9.bin -y7 temp\y7.bin -t temp\banner.bin
if errorlevel 1 goto :error

echo Pre-processing files...
tools\armips.exe pre.asm
if errorlevel 1 goto :error

echo Decompressing files...
tools\blz.exe -d temp\arm9.dec
if errorlevel 1 goto :error
tools\blz.exe -d temp\overlay\overlay_0001.bin
if errorlevel 1 goto :error
tools\blz.exe -d temp\overlay\overlay_0002.bin
if errorlevel 1 goto :error
tools\blz.exe -d temp\overlay\overlay_0003.bin
if errorlevel 1 goto :error
tools\blz.exe -d temp\overlay\overlay_0004.bin
if errorlevel 1 goto :error

echo Patching files...
tools\armips.exe patch.asm
if errorlevel 1 goto :error

echo Compressing files...
copy /Y temp\arm9.dec temp\arm9.bin
if errorlevel 1 goto :error
tools\blz.exe -eo9 temp\arm9.bin
if errorlevel 1 goto :error
tools\blz.exe -eo temp\overlay\overlay_0001.bin
if errorlevel 1 goto :error
tools\blz.exe -eo temp\overlay\overlay_0002.bin
if errorlevel 1 goto :error
tools\blz.exe -eo temp\overlay\overlay_0003.bin
if errorlevel 1 goto :error
tools\blz.exe -eo temp\overlay\overlay_0004.bin
if errorlevel 1 goto :error

echo Post-processing files...
tools\armips.exe post.asm
if errorlevel 1 goto :error

echo Creating ROM...
tools\ndstool.exe -c out\mmzc-us.nds -9 temp\arm9.bin -7 temp\arm7.bin -d temp\data -y temp\overlay -h temp\header.bin -y9 temp\y9.bin -y7 temp\y7.bin -t temp\banner.bin
if errorlevel 1 goto :error

echo Done.
exit /b 0

:error
pause