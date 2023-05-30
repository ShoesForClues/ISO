@echo off
set default_directory=%cd%
cd /d %~dp0

where >nul 2>nul luajit

if %errorlevel% equ 0 (
	luajit iso.lua %*
) else (
	echo Error: Lua is not installed
)

cd /d %default_directory%