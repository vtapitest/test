# Script para forzar la instalación con npm
Write-Host "Forzando instalación con npm..." -ForegroundColor Green

# Crear directorio temporal
$tempDir = ".\temp-npm-force"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force

# Copiar package.json
Copy-Item -Path ".\package.json" -Destination "$tempDir\package.json" -Force
if (Test-Path ".\package-lock.json") {
    Copy-Item -Path ".\package-lock.json" -Destination "$tempDir\package-lock.json" -Force
}

# Ejecutar npm con flags para ignorar errores
Write-Host "Ejecutando npm con flags para ignorar errores..." -ForegroundColor Yellow
docker run --rm -v "${PWD}\$tempDir:/app" -w /app node:20 bash -c "npm install -g npm@11.4.1 && npm install --force --legacy-peer-deps --no-fund --no-audit"

# Verificar node_modules
if (-not (Test-Path "$tempDir\node_modules")) {
    Write-Host "Error: node_modules no se creó con npm forzado." -ForegroundColor Red
} else {
    # Comprimir node_modules
    Write-Host "Comprimiendo node_modules..." -ForegroundColor Yellow
    if (Get-Command "tar.exe" -ErrorAction SilentlyContinue) {
        tar -czf "node_modules.tar.gz" -C "$tempDir" "node_modules"
    } else {
        Compress-Archive -Path "$tempDir\node_modules" -DestinationPath "node_modules.zip" -Force
    }
    
    Write-Host "¡Éxito! Dependencias instaladas forzadamente con npm." -ForegroundColor Green
}

# Limpiar
Remove-Item -Path $tempDir -Recurse -Force
