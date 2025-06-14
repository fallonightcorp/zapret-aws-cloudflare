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
powershell -ExecutionPolicy Bypass -File "%~dp0update-aws.ps1"

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

start "zapret_ALT6" /min "%BIN%winws.exe" --wf-tcp=80,443,444-65535 --wf-udp=443,444-65535,50000-50099,0-65535 ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-fake-discord=0x00 --dpi-desync-fake-stun=0x00 --dpi-desync-repeats=6 --new ^
--filter-tcp=443 --hostlist="%LISTS%list-discord.txt" --hostlist-domains=cdn.discordapp.com,gateway.discord.gg,images-ext-1.discordapp.net,media.discordapp.net --dpi-desync=fake --dpi-desync-fake-tls-mod=none --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,hopbyhop2 --new ^
--filter-udp=443 --hostlist="%LISTS%list-general.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --hostlist="%LISTS%list-general.txt" --dpi-desync=fake,split2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist-exclude="%LISTS%list-discord.txt" --hostlist="%LISTS%list-general.txt" --hostlist-domains=adguard.com,adguard-vpn.com,totallyacdn.com,whiskergalaxy.com,windscribe.com,windscribe.net,cloudflareclient.com,soundcloud.com,sndcdn.com,soundcloud.cloud --dpi-desync=split2 --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-repeats=2 --dpi-desync-fooling=badseq,hopbyhop2 --dpi-desync-split-seqovl-pattern="%BIN%tls_clienthello_www_google_com.bin" --new ^
--filter-tcp=443 --ipset-ip=162.159.36.1 --filter-l7=tls --dpi-desync=fake --dpi-desync-fake-tls=0x00 --dpi-desync-start=n2 --dpi-desync-cutoff=n3 --dpi-desync-fooling=md5sig --new ^
--filter-udp=0-65535 --filter-l7=wireguard --dpi-desync=fake --dpi-desync-fake-wireguard=0x00 --dpi-desync-cutoff=n2 --new ^
--filter-udp=444-65535 --ipset="%LISTS%list-aws-amazon.txt" --dpi-desync-ttl=8 --dpi-desync-repeats=20 --dpi-desync-fooling=none --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync=fake --dpi-desync-cutoff=n10

exit
