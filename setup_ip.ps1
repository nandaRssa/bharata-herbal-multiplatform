# Auto IP Setup - Bharata Herbal Mobile

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Auto IP Setup - Bharata Herbal Mobile" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$ipconfig = ipconfig | Out-String
$lines = $ipconfig.Split("`n")

$detectedIP = $null

foreach ($line in $lines) {
    if ($line -match "IPv4") {
        $ip = ($line -split ":" | Select-Object -Last 1).Trim()
        if ($ip -match "^\d+\.\d+\.\d+\.\d+$" -and $ip -notmatch "^169\.254") {
            if ($ip -match "^172\.|^192\.168\.|^10\.") {
                $detectedIP = $ip
                Write-Host "IP Found: $detectedIP" -ForegroundColor Yellow
                break
            }
        }
    }
}

if (-not $detectedIP) {
    Write-Host "ERROR: Tidak ada IP hotspot!" -ForegroundColor Red
    exit 1
}

Write-Host ""

$configPath = "C:\xampp\htdocs\BharataHerbal_PABP\bhrata-herbal-mobile\bharata_herbal_mobile\lib\config\api_config.dart"

$newUrl = "http://$detectedIP`:8000/api"
$newImageUrl = "http://$detectedIP`:8000/foto_bharata"

$content = "class ApiConfig {
  static const String baseUrl = '$newUrl';
  static const String baseImageUrl = '$newImageUrl';
}
"

Set-Content -Path $configPath -Value $content -Force

Write-Host "============================================" -ForegroundColor Green
Write-Host "  BERHASIL!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "IP: $detectedIP" -ForegroundColor Cyan
Write-Host "URL: $newUrl" -ForegroundColor White
Write-Host ""
Write-Host "Jalankan:" -ForegroundColor Yellow
Write-Host "  php artisan serve --host=0.0.0.0 --port=8000" -ForegroundColor White
Write-Host ""
Write-Host "Web: http://$detectedIP`:8000/admin" -ForegroundColor Cyan