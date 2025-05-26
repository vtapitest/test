# Script para instalar solo dependencias de producción
Write-Host "Instalando solo dependencias de producción..." -ForegroundColor Green

# Crear directorio temporal
$tempDir = ".\temp-npm-prod"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force

# Copiar package.json
Copy-Item -Path ".\package.json" -Destination "$tempDir\package.json" -Force
if (Test-Path ".\package-lock.json") {
    Copy-Item -Path ".\package-lock.json" -Destination "$tempDir\package-lock.json" -Force
}

# Ejecutar npm con --only=prod
Write-Host "Ejecutando npm con --only=prod..." -ForegroundColor Yellow
docker run --rm -v "${PWD}\$tempDir:/app" -w /app node:20 bash -c "npm install -g npm@11.4.1 && npm install --only=prod --no-fund --no-audit"

# Verificar node_modules
if (-not (Test-Path "$tempDir\node_modules")) {
    Write-Host "Error: node_modules no se creó con npm --only=prod." -ForegroundColor Red
} else {
    # Comprimir node_modules
    Write-Host "Comprimiendo node_modules..." -ForegroundColor Yellow
    if (Get-Command "tar.exe" -ErrorAction SilentlyContinue) {
        tar -czf "node_modules.tar.gz" -C "$tempDir" "node_modules"
    } else {
        Compress-Archive -Path "$tempDir\node_modules" -DestinationPath "node_modules.zip" -Force
    }
    
    Write-Host "¡Éxito! Dependencias de producción instaladas." -ForegroundColor Green
}

# Limpiar
Remove-Item -Path $tempDir -Recurse -Force
