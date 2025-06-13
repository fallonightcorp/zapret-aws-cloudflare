@echo off
chcp 65001 > nul
:: Set UTF-8 encoding for cmd.exe

cd /d "%~dp0"

:: Call other service scripts to check status and updates
call service.bat status_zapret
call service.bat check_updates
echo:

:: Set paths for binaries and lists
set "BIN=%~dp0bin\"
set "LISTS=%~dp0lists\"

:: === AWS IP UPDATE ===
set "listPath=lists\list-aws-amazon.txt"
set ipCountBefore=0
set ipCountAfter=0
set ipDelta=0

:: Check if the list file exists and is not empty
if exist "%listPath%" (
    for /f %%A in ('find /c /v "" ^< "%listPath%"') do set ipCountBefore=%%A
)

:: If the file is empty or doesn't exist, set current IP count to 0
if not defined ipCountBefore set ipCountBefore=0
echo [INFO] Updating Amazon AWS IP list... (current: %ipCountBefore%)

:: Call Python script to update AWS IP list with timeout
start /wait /min "" python "%~dp0update-aws.py"

:: Check if the update was successful or timed out
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to update IP list. Timeout or another issue occurred.
) else (
    :: Count IPs after update
    if exist "%listPath%" (
        for /f %%A in ('find /c /v "" ^< "%listPath%"') do set ipCountAfter=%%A
    )

    :: If file is still empty after update, set after count to 0
    if not defined ipCountAfter set ipCountAfter=0
    set /a ipDelta=%ipCountAfter% - %ipCountBefore%

    echo [INFO] Updated IPs: was %ipCountBefore%, now %ipCountAfter%, added %ipDelta%
    echo.
)

:: === User Selection for Strategy ===
:MENU
echo Select a strategy:
echo [1] Strategy 1 (Fixed TTL (Protective))
echo [2] Strategy 2 (Auto TTL (Fastest))
set /p choice=Enter your choice (1 or 2): 

:: Check valid
if "%choice%"=="1" (
    echo [INFO] Using Strategy 1
    set strategy=--filter-udp=444-65535 --ipset="%LISTS%list-aws-amazon.txt" --dpi-desync-ttl=8 --dpi-desync-repeats=20 --dpi-desync-fooling=none --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync=fake --dpi-desync-cutoff=n10
) else if "%choice%"=="2" (
    echo [INFO] Using Strategy 2
    set strategy=--filter-udp=444-65535 --ipset="%LISTS%list-aws-amazon.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=10 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www.google_com.bin" --dpi-desync-cutoff=n2
) else (
    echo [ERROR] Invalid choice! Please select a valid option.
    goto MENU
)

:: === Launching Application with Parameters ===
start "zapret_ALT4" /min "%BIN%winws.exe" --wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 --hostlist="%LISTS%list-general.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-udp=50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-tcp=80 --hostlist="%LISTS%list-general.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist="%LISTS%list-general.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls="%BIN%tls_clienthello_www_google_com.bin" --new ^
--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls="%BIN%tls_clienthello_www_google_com.bin"
%strategy%

exit
