# Script para descargar módulos de Node.js y crear node_modules.tar.gz
Write-Host "Descargando módulos de Node.js desde package.json..." -ForegroundColor Green

# Crear directorio temporal para la instalación
$tempDir = ".\temp-npm-modules"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force

# Copiar package.json al directorio temporal
Copy-Item -Path ".\package.json" -Destination "$tempDir\package.json" -Force
if (Test-Path ".\package-lock.json") {
    Copy-Item -Path ".\package-lock.json" -Destination "$tempDir\package-lock.json" -Force
}

# Cambiar al directorio temporal
Push-Location $tempDir

try {
    # Instalar dependencias
    Write-Host "Instalando dependencias en carpeta temporal..." -ForegroundColor Yellow
    npm install --no-audit --no-fund

    # Volver al directorio original
    Pop-Location

    # Comprimir node_modules usando el método disponible
    Write-Host "Comprimiendo node_modules en .tar.gz..." -ForegroundColor Yellow

    # Método 1: Usando 7-Zip
    if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) {
        Write-Host "Usando 7-Zip para comprimir..." -ForegroundColor Cyan
        
        # Crear archivo tar
        7z a -ttar ".\temp-node_modules.tar" "$tempDir\node_modules"
        
        # Comprimir archivo tar con gzip
        7z a -tgzip ".\node_modules.tar.gz" ".\temp-node_modules.tar"
        
        # Limpiar archivo temporal
        Remove-Item -Path ".\temp-node_modules.tar" -Force
    }
    # Método 2: Usando tar nativo de Windows 10/11
    elseif (Get-Command "tar.exe" -ErrorAction SilentlyContinue) {
        Write-Host "Usando tar nativo de Windows..." -ForegroundColor Cyan
        
        # Usar tar nativo de Windows 10/11
        tar -czf "node_modules.tar.gz" -C "$tempDir" "node_modules"
    }
    # Método 3: Alternativa con PowerShell
    else {
        Write-Host "Usando PowerShell para comprimir (creará un ZIP)..." -ForegroundColor Cyan
        
        # Comprimir con PowerShell (creará un ZIP en lugar de tar.gz)
        Compress-Archive -Path "$tempDir\node_modules\*" -DestinationPath ".\node_modules.zip" -Force
    }

    # Mostrar información del archivo creado
    if (Test-Path ".\node_modules.tar.gz") {
        $size = (Get-Item ".\node_modules.tar.gz").Length / 1MB
        Write-Host "¡Listo! Archivo node_modules.tar.gz creado: $([math]::Round($size, 2)) MB" -ForegroundColor Green
    } elseif (Test-Path ".\node_modules.zip") {
        $size = (Get-Item ".\node_modules.zip").Length / 1MB
        Write-Host "¡Listo! Archivo node_modules.zip creado: $([math]::Round($size, 2)) MB" -ForegroundColor Green
        Write-Host "Nota: Se ha creado un archivo ZIP en lugar de tar.gz debido a limitaciones de PowerShell." -ForegroundColor Yellow
    }
}
catch {
    # En caso de error, volver al directorio original
    Pop-Location
    Write-Host "Error: $_" -ForegroundColor Red
}
finally {
    # Limpiar directorio temporal
    if (Test-Path $tempDir) {
        Write-Host "Limpiando archivos temporales..." -ForegroundColor Yellow
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

Write-Host "Proceso completado." -ForegroundColor Green
