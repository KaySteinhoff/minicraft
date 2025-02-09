@echo off
cls
echo Assembling object files...
nasm src/main.asm -fwin32 -o obj/main.obj
echo Linking object files...
gcc obj/main.obj -nostdlib -L C:/MinGW/lib -lkernel32 -luser32 -lgdi32 -lopengl32 -mwindows -s -o test.exe
echo Done!
pause
