@echo off
rem Windows version of tv.sh: set up Aurora on an Android TV over ADB (Wi-Fi).
rem
rem   tv.bat pair ^<tv-ip:pairing-port^> ^<code^>
rem   tv.bat connect ^<tv-ip:port^>
rem   tv.bat info
rem   tv.bat audit
rem   tv.bat debloat
rem   tv.bat restore
rem   tv.bat install ^<apk^>
rem   tv.bat set-home
rem   tv.bat disable ^<package^>
rem   tv.bat enable ^<package^>

setlocal
set "HERE=%~dp0"
set "LIST=%HERE%packages-to-remove.txt"
set "ACT=com.riturajpatna.tvlauncher/.MainActivity"
set "CMD=%~1"

where adb >nul 2>nul
if errorlevel 1 (
  echo adb not found. Install Android platform-tools and add it to PATH.
  exit /b 1
)

if "%CMD%"=="" goto help
if /i "%CMD%"=="pair" goto pair
if /i "%CMD%"=="connect" goto connect
if /i "%CMD%"=="info" goto info
if /i "%CMD%"=="audit" goto audit
if /i "%CMD%"=="debloat" goto debloat
if /i "%CMD%"=="restore" goto restore
if /i "%CMD%"=="install" goto install
if /i "%CMD%"=="set-home" goto sethome
if /i "%CMD%"=="disable" goto disable
if /i "%CMD%"=="enable" goto enable
goto help

:pair
adb pair %2 %3
goto :eof

:connect
adb connect %2
adb devices
goto :eof

:info
echo Model:
adb shell getprop ro.product.brand
adb shell getprop ro.product.model
echo Android version:
adb shell getprop ro.build.version.release
echo Current Home app:
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
goto :eof

:audit
adb shell pm list packages -s > "%HERE%audit-system.txt"
adb shell pm list packages -3 > "%HERE%audit-user.txt"
echo Wrote audit-system.txt and audit-user.txt in %HERE%
goto :eof

:debloat
adb shell pm list packages --user 0 > "%TEMP%\aurora-installed.txt"
for /f "usebackq eol=# tokens=*" %%P in ("%LIST%") do (
  findstr /c:"package:%%P" "%TEMP%\aurora-installed.txt" >nul && (
    echo Removing %%P
    adb shell pm uninstall -k --user 0 %%P
  ) || echo Skipping %%P - not installed
)
goto :eof

:restore
for /f "usebackq eol=# tokens=*" %%P in ("%LIST%") do (
  echo Restoring %%P
  adb shell pm install-existing --user 0 %%P
)
goto :eof

:install
adb install -r %2
goto :eof

:sethome
adb shell cmd package set-home-activity --user 0 %ACT%
echo If Home still opens the old launcher, see README - Making Aurora the Home app.
goto :eof

:disable
adb shell pm disable-user --user 0 %2
goto :eof

:enable
adb shell pm enable %2
goto :eof

:help
echo Usage: tv.bat pair ^| connect ^| info ^| audit ^| debloat ^| restore ^| install ^| set-home ^| disable ^| enable
goto :eof
