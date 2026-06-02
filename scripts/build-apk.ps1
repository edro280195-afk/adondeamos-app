# Build script para Adondeamos APK
# Ejecutar desde la raíz del proyecto Flutter:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-apk.ps1

param(
    [string]$ApiUrl = "https://adondeamos-api.onrender.com",
    [switch]$SplitAbi = $false,
    [switch]$AppBundle = $false
)

$ErrorActionPreference = "Stop"
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $projectDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ADONDEAMOS — Build APK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  API URL : $ApiUrl" -ForegroundColor Gray
Write-Host ""

# Verificar keystore
$keyProps = Join-Path $projectDir "android\key.properties"
if (-not (Test-Path $keyProps)) {
    Write-Host "ERROR: No se encontro android\key.properties" -ForegroundColor Red
    Write-Host ""
    Write-Host "Ejecuta primero este comando para generar el keystore:" -ForegroundColor Yellow
    Write-Host '  keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storetype JKS' -ForegroundColor White
    Write-Host ""
    Write-Host "Luego edita android\key.properties con las contraseñas reales." -ForegroundColor Yellow
    exit 1
}

Write-Host "Keystore encontrado. Iniciando build..." -ForegroundColor Green
Write-Host ""

Push-Location $projectDir

try {
    $dartDefines = "--dart-define=API_BASE_URL=$ApiUrl"

    if ($AppBundle) {
        Write-Host "Construyendo App Bundle (.aab)..." -ForegroundColor Green
        flutter build appbundle --release $dartDefines
        Write-Host ""
        Write-Host "App Bundle generado en:" -ForegroundColor Green
        Write-Host "  build\app\outputs\bundle\release\app-release.aab" -ForegroundColor White
    }
    elseif ($SplitAbi) {
        Write-Host "Construyendo APKs por arquitectura..." -ForegroundColor Green
        flutter build apk --release --split-per-abi $dartDefines
        Write-Host ""
        Write-Host "APKs generados en:" -ForegroundColor Green
        Get-ChildItem "build\app\outputs\flutter-apk\*.apk" | ForEach-Object {
            $sizeMB = [math]::Round($_.Length / 1MB, 1)
            Write-Host "  $($_.Name)  ($sizeMB MB)" -ForegroundColor White
        }
    }
    else {
        Write-Host "Construyendo APK universal..." -ForegroundColor Green
        flutter build apk --release $dartDefines
        $apk = Get-Item "build\app\outputs\flutter-apk\app-release.apk"
        $sizeMB = [math]::Round($apk.Length / 1MB, 1)
        Write-Host ""
        Write-Host "APK generado:" -ForegroundColor Green
        Write-Host "  $($apk.Name)  ($sizeMB MB)" -ForegroundColor White
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Listo." -ForegroundColor Cyan
