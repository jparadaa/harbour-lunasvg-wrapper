@echo off

if not defined DevEnvDir (       
    call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x86_x64
)

rem ==== Eliminación segura de archivos previos ====
if exist generate_svg.exe del generate_svg.exe
if exist generate_svg.exp del generate_svg.exp
if exist generate_svg.lib del generate_svg.lib
rem ===============================================

c:\harbour\bin\hbmk2 generate_svg.hbp -comp=msvc64

IF ERRORLEVEL 1 GOTO COMPILEERROR


@cls
generate_svg.exe

GOTO EXIT

:COMPILEERROR

echo *** Error 

pause

:EXIT