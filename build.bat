@echo off

::#########################################################################::
::
:: # Description
:: Builds a .mez archive file from a Power BI Data Connector source folder.
::
:: # Syntax
:: build param1 param2
:: param1: Source folder
:: param2: Destination folder
::
:: # Example
:: Source folder:
::   "%USERPROFILE%\source\repos\CMEMPowerBIConnector\CMEMPowerBIConnector"
:: Destination folder:
::   "%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors"
:: Enter command:
::   build "%USERPROFILE%\source\repos\CMEMPowerBIConnector\CMEMPowerBIConnector"  "%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors"
:: Result:
::   %USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\CMEMPowerBIConnector.mez
::
:: # Links
:: https://docs.microsoft.com/en-us/power-query/samples/trippin/1-odata/readme#loading-your-extension-in-power-bi-desktop
::
::#########################################################################::



:: read filename
for %%a in (%1) do (
	set filename=%%~nxa
)
set destinationPathFileNoSuffix=%~2\%filename%

:: escape spaces for Compress-Archive command
set destinationPathFileNoSuffix=%destinationPathFileNoSuffix: =` % 
set destinationPathFileNoSuffix=%destinationPathFileNoSuffix:~0,-1%

powershell Compress-Archive %destinationPathFileNoSuffix%.zip -Force -Path "%~1\*.png", "%~1\*.pqm", "%~1\*.resx", "%~1\*.pq", "%~1\*.m", "%~1\*.json", "%~1\*.xml"

:: undo escape spaces
set destinationPathFileNoSuffix=%destinationPathFileNoSuffix:` = % 
set destinationPathFileNoSuffix=%destinationPathFileNoSuffix:~0,-1%

:: rename file
move "%destinationPathFileNoSuffix%.zip" "%destinationPathFileNoSuffix%.mez"

:: releave variables
set destinationPathFileNoSuffix=
set filename=
