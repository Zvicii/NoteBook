echo off

set PATH_TO_DUMPS="%LOCALAPPDATA%\CrashDumps"
mkdir %PATH_TO_DUMPS%
echo Your memory dumps will be created in %PATH_TO_DUMPS%

@REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v "DumpFolder" /t REG_EXPAND_SZ /d %PATH_TO_DUMPS% /f
@REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v "DumpCount" /t REG_DWORD /d "10" /f
@REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v "DumpType" /t REG_DWORD /d "2" /f

