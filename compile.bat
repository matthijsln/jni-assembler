@echo off
nasmw -f win32 -w+orphan-labels JNITest.asm
link /dll /def:JNITest.def /out:JNITest.dll /entry:DLLMain /merge:.data=.code /merge:.rdata=.code /merge:.text=.code /align:4096 /section:.code,erw /subsystem:windows JNITest.obj user32.lib ddraw.lib msvcrt.lib kernel32.lib