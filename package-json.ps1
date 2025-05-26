# Script simplificado para generar node_modules.tar.gz
Write-Host "=== Generando node_modules.tar.gz ===" -ForegroundColor Green

# Crear directorio temporal limpio
$tempDir = ".\temp-npm"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force

# Copiar archivos necesarios
Write-Host "Copiando package.json..." -ForegroundColor Yellow
Copy-Item -Path ".\package.json" -Destination "$tempDir\package.json" -Force
if (Test-Path ".\package-lock.json") {
    Copy-Item -Path ".\package-lock.json" -Destination "$tempDir\package-lock.json" -Force
}

# Convertir la ruta a formato que Docker entienda en Windows
$dockerPath = (Resolve-Path $tempDir).Path.Replace('\', '/')
if ($dockerPath -match '^([A-Za-z]):(.*)$') {
    $dockerPath = "/$($matches[1].ToLower())$($matches[2])"
}

# Ejecutar npm install directamente con volumen montado
Write-Host "Instalando dependencias con Docker..." -ForegroundColor Yellow
docker run --rm -v "${dockerPath}:/app" -w /app node:20 bash -c "npm install -g npm@11.4.1 && npm install --no-audit --no-fund"

# Verificar si se creó node_modules
if (-not (Test-Path "$tempDir\node_modules")) {
    Write-Host "Error: node_modules no se creó." -ForegroundColor Red
    Write-Host "Intentando con sintaxis alternativa de volumen..." -ForegroundColor Yellow
    
    # Intentar con sintaxis alternativa para Windows
    $fullPath = (Get-Item $tempDir).FullName
    docker run --rm -v "${fullPath}:/app" -w /app node:20 bash -c "npm install -g npm@11.4.1 && npm install --no-audit --no-fund"
}

# Verificar nuevamente
if (-not (Test-Path "$tempDir\node_modules")) {
    Write-Host "Error: No se pudo crear node_modules." -ForegroundColor Red
    exit 1
}

Write-Host "node_modules creado correctamente. Comprimiendo..." -ForegroundColor Green

# Comprimir node_modules
if (Get-Command "tar.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Usando tar para comprimir..." -ForegroundColor Cyan
    tar -czf "node_modules.tar.gz" -C "$tempDir" "node_modules"
} else {
    Write-Host "tar no encontrado. Usando PowerShell para comprimir..." -ForegroundColor Cyan
    Compress-Archive -Path "$tempDir\node_modules" -DestinationPath "node_modules.zip" -Force
}

# Limpiar
Write-Host "Limpiando archivos temporales..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force

# Mostrar resultado
if (Test-Path "node_modules.tar.gz") {
    $size = (Get-Item "node_modules.tar.gz").Length / 1MB
    Write-Host "¡Éxito! node_modules.tar.gz creado: $([math]::Round($size, 2)) MB" -ForegroundColor Green
} elseif (Test-Path "node_modules.zip") {
    $size = (Get-Item "node_modules.zip").Length / 1MB
    Write-Host "¡Éxito! node_modules.zip creado: $([math]::Round($size, 2)) MB" -ForegroundColor Green
}
