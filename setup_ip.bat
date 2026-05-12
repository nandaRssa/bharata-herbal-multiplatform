@echo off
chcp 65001 >nul

echo ============================================
echo   Auto IP Setup untuk Bharata Herbal
echo ============================================
echo.

REM Find active network adapter IP (preferring common hotspot patterns)
for /f "tokens=1-4 delims=. " %%a in ('"getmac /fo csv /nh | findstr -i ethernet wifi mobile hotspot"') do (
    for /f "tokens=2 delims=:" %%i in ('"netsh interface ipv4 show addresses ^| findstr /i %%c"') do (
        set "DETECTED_IP=%%i"
    )
)

REM Alternative: Get default gateway IP pattern (common for mobile hotspot)
for /f "tokens=2 delims=:" %%i in ('"ipconfig ^| findstr /i \"IPv4.*172\\|192\\|10\\.\" ^| findstr /v \"169\\.254\""') do (
    echo Found IP: %%i
    set "DETECTED_IP=%%i"
)

REM If still empty, use default route
if "%DETECTED_IP%"=="" (
    for /f "tokens=3" %%a in ('"route print ^| findstr 0.0.0.0"') do (
        for /f "tokens=1" %%i in ('"netsh interface ipv4 show addresses ^| findstr %%a"') do (
            set "DETECTED_IP=%%i"
        )
    )
)

if "%DETECTED_IP%"=="" (
    echo ERROR: Tidak bisa mendeteksi IP. Pastikan terhubung ke hotspot.
    echo Tekan sembarang tombol untuk exit...
    pause >nul
    exit /b 1
)

echo.
echo IP Terdeteksi: %DETECTED_IP%
echo.

REM Update api_config.dart
set "CONFIG_FILE=%~dp0bharata_herbal_mobile\lib\config\api_config.dart"
set "TEMP_FILE=%~dp0api_config_temp.dart"

echo Membuat backup config...
copy "%CONFIG_FILE%" "%CONFIG_FILE%.bak" >nul

echo Updating api_config.dart...
(
    echo class ApiConfig {
    echo   static const String baseUrl = 'http://%DETECTED_IP%:8000/api';
    echo   static const String baseImageUrl = 'http://%DETECTED_IP%:8000/foto_bharata';
    echo }
) > "%TEMP_FILE%"

move /Y "%TEMP_FILE%" "%CONFIG_FILE%" >nul

echo.
echo ============================================
echo   BERHASIL!
echo ============================================
echo.
echo Config updated dengan IP: %DETECTED_IP%
echo.
echo Jalankan perintah berikut:
echo.
echo   1. cd C:\xampp\htdocs\BharataHerbal_PABP\bhrata-herbal-mobile
echo   2. php artisan serve --host=0.0.0.0 --port=8000
echo.
echo Untuk Web Admin di browser:
echo   http://%DETECTED_IP%:8000/admin
echo.
echo Tekan sembarang tombol untuk exit...
pause >nul