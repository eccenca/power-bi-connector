@echo off

set SOURCES_PATH=%~1
if "%SOURCES_PATH%"=="" set SOURCES_PATH=CMEMPowerBIConnector

set TARGET_PATH=%~2
if "%TARGET_PATH%"=="" set TARGET_PATH=target

set FILE_PREFIX=%~3
if "%FILE_PREFIX%"=="" set FILE_PREFIX=eccenca-PowerBIConnector

:: set version
for /f %%i in ('git describe --always --dirty') do set VERSION=%%i

mkdir %TARGET_PATH%

:: escape spaces for Compress-Archive command
set TARGET_PATH=%TARGET_PATH: =` % 
set TARGET_PATH=%TARGET_PATH:~0,-1%

powershell Compress-Archive %TARGET_PATH%\%FILE_PREFIX%-%VERSION%.zip -Force -Path "%SOURCES_PATH%\*.png",^
	"%SOURCES_PATH%\*.pqm",^
	"%SOURCES_PATH%\*.resx",^
	"%SOURCES_PATH%\*.pq",^
	"%SOURCES_PATH%\*.m",^
	"%SOURCES_PATH%\*.json",^
	"%SOURCES_PATH%\*.xml"

:: undo escape spaces
set TARGET_PATH=%TARGET_PATH:` = % 
set TARGET_PATH=%TARGET_PATH:~0,-1%

echo %TARGET_PATH%\%FILE_PREFIX%-%VERSION%.zip

:: rename file
move "%TARGET_PATH%\%FILE_PREFIX%-%VERSION%.zip" "%TARGET_PATH%\%FILE_PREFIX%-%VERSION%.mez"

echo Zipped '%SOURCES_PATH%/*' as '%TARGET_PATH%/%FILE_PREFIX%-%VERSION%.mez'

:: releave variables
set SOURCES_PATH=
set TARGET_PATH=
set FILE_PREFIX=
set VERSION=
