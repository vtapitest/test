# Script simplificado para preparar un paquete offline para instalación en Linux
# Los scripts de instalación ya están creados en scripts/offline/

param(
    [switch]$SkipDependencies,
    [switch]$SkipDocker,
    [switch]$SkipBuild
)

Write-Host "=== Preparando paquete offline para CyberSec Tasks ===" -ForegroundColor Green
Write-Host "Destino: Instalación en Linux sin conexión a internet" -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "package.json")) {
    Write-Host "Error: Este script debe ejecutarse desde la raíz del proyecto CyberSec Tasks" -ForegroundColor Red
    exit 1
}

# Crear directorio para el paquete
$PACKAGE_DIR = "cybersec-tasks-offline"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "`nCreando directorio del paquete..." -ForegroundColor Yellow
if (Test-Path $PACKAGE_DIR) {
    Write-Host "Eliminando paquete anterior..." -ForegroundColor Yellow
    Remove-Item -Path $PACKAGE_DIR -Recurse -Force
}
New-Item -Path $PACKAGE_DIR -ItemType Directory -Force | Out-Null

# Instalar dependencias si es necesario
if (-not $SkipDependencies) {
    if (-not (Test-Path "node_modules") -or -not (Test-Path "node_modules/react")) {
        Write-Host "`nInstalando dependencias de Node.js..." -ForegroundColor Yellow
        npm ci
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error al instalar dependencias" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "`nDependencias ya instaladas, omitiendo..." -ForegroundColor Green
    }
}

# Construir la aplicación Next.js
if (-not $SkipBuild) {
    Write-Host "`nConstruyendo la aplicación Next.js..." -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al construir la aplicación" -ForegroundColor Red
        exit 1
    }
}

# Copiar archivos del proyecto
Write-Host "`nCopiando archivos del proyecto..." -ForegroundColor Yellow

# Directorios principales
$directories = @("app", "components", "lib", "public", "docs")
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "  - Copiando $dir..." -ForegroundColor Gray
        Copy-Item -Path $dir -Destination $PACKAGE_DIR -Recurse
    }
}

# Copiar .next (aplicación construida)
if (Test-Path ".next") {
    Write-Host "  - Copiando aplicación construida (.next)..." -ForegroundColor Gray
    Copy-Item -Path ".next" -Destination $PACKAGE_DIR -Recurse
}

# Copiar node_modules
Write-Host "  - Copiando node_modules (esto puede tardar)..." -ForegroundColor Gray
Copy-Item -Path "node_modules" -Destination $PACKAGE_DIR -Recurse

# Archivos individuales
$files = @(
    "package.json",
    "package-lock.json",
    "next.config.mjs",
    "tsconfig.json",
    "tailwind.config.ts",
    "postcss.config.js",
    "init-db.sql",
    "sample-tasks.sql"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  - Copiando $file..." -ForegroundColor Gray
        Copy-Item -Path $file -Destination $PACKAGE_DIR
    }
}

# Copiar archivos Docker
if (Test-Path "docker-compose.offline.yml") {
    Copy-Item -Path "docker-compose.offline.yml" -Destination "$PACKAGE_DIR/docker-compose.yml"
} else {
    Copy-Item -Path "docker-compose.yml" -Destination $PACKAGE_DIR
}

if (Test-Path "Dockerfile.offline") {
    Copy-Item -Path "Dockerfile.offline" -Destination "$PACKAGE_DIR/Dockerfile"
} else {
    Copy-Item -Path "Dockerfile" -Destination $PACKAGE_DIR
}

# Copiar scripts de instalación para Linux
Write-Host "`nCopiando scripts de instalación..." -ForegroundColor Yellow
$offlineScripts = @(
    "scripts/offline/install.sh",
    "scripts/offline/init-app.sh",
    "scripts/offline/restart.sh",
    "scripts/offline/backup-db.sh",
    "scripts/offline/restore-db.sh"
)

foreach ($script in $offlineScripts) {
    if (Test-Path $script) {
        $scriptName = Split-Path $script -Leaf
        Write-Host "  - Copiando $scriptName..." -ForegroundColor Gray
        Copy-Item -Path $script -Destination $PACKAGE_DIR
    }
}

# Copiar README específico para instalación offline
if (Test-Path "scripts/offline/README-OFFLINE.md") {
    Copy-Item -Path "scripts/offline/README-OFFLINE.md" -Destination "$PACKAGE_DIR/README.md"
}

# Descargar y guardar imágenes Docker
if (-not $SkipDocker) {
    Write-Host "`nDescargando imágenes Docker..." -ForegroundColor Yellow
    
    # Crear directorio para imágenes
    New-Item -Path "$PACKAGE_DIR/docker-images" -ItemType Directory -Force | Out-Null
    
    # Lista de imágenes a descargar
    $images = @(
        @{Name="bitnami/node:18"; File="node.tar"},
        @{Name="bitnami/postgresql:15"; File="postgresql.tar"}
    )
    
    foreach ($image in $images) {
        Write-Host "  - Descargando $($image.Name)..." -ForegroundColor Gray
        docker pull $image.Name
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  - Guardando $($image.Name)..." -ForegroundColor Gray
            docker save $image.Name -o "$PACKAGE_DIR/docker-images/$($image.File)"
        } else {
            Write-Host "  ! Error al descargar $($image.Name)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`nOmitiendo descarga de imágenes Docker..." -ForegroundColor Yellow
}

# Crear archivo de información del paquete
$packageInfo = @"
CyberSec Tasks - Offline Package
================================
Fecha de creación: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Versión de Node.js: $(node --version)
Versión de npm: $(npm --version)
Sistema operativo: $($PSVersionTable.OS)

Este paquete contiene todo lo necesario para instalar
CyberSec Tasks en un entorno Linux sin conexión a internet.

Consulta README.md para instrucciones de instalación.
"@
Set-Content -Path "$PACKAGE_DIR/PACKAGE_INFO.txt" -Value $packageInfo

# Comprimir el paquete
Write-Host "`nComprimiendo el paquete..." -ForegroundColor Yellow

$outputFile = "cybersec-tasks-offline-$TIMESTAMP"

# Intentar usar 7-Zip para crear un archivo tar.gz
if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Usando 7-Zip para crear archivo tar.gz..." -ForegroundColor Gray
    7z a -ttar "$outputFile.tar" $PACKAGE_DIR | Out-Null
    7z a -tgzip "$outputFile.tar.gz" "$outputFile.tar" | Out-Null
    Remove-Item -Path "$outputFile.tar" -Force
    $finalFile = "$outputFile.tar.gz"
} else {
    Write-Host "7-Zip no encontrado, creando archivo ZIP..." -ForegroundColor Yellow
    Compress-Archive -Path $PACKAGE_DIR -DestinationPath "$outputFile.zip" -Force
    $finalFile = "$outputFile.zip"
    Write-Host "`nNOTA: Se recomienda instalar 7-Zip para crear archivos tar.gz compatibles con Linux" -ForegroundColor Yellow
}

# Obtener información del archivo final
$fileInfo = Get-Item $finalFile
$fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

# Mostrar resumen
Write-Host "`n=== Paquete offline creado exitosamente ===" -ForegroundColor Green
Write-Host "Archivo: $($fileInfo.Name)" -ForegroundColor Cyan
Write-Host "Tamaño: $fileSizeMB MB" -ForegroundColor Cyan
Write-Host "Ubicación: $($fileInfo.FullName)" -ForegroundColor Cyan

Write-Host "`nPara instalar en Linux sin conexión:" -ForegroundColor Yellow
Write-Host "1. Transfiere el archivo al servidor Linux" -ForegroundColor White
Write-Host "2. Descomprime el archivo:" -ForegroundColor White
if ($finalFile.EndsWith(".tar.gz")) {
    Write-Host "   tar -xzf $($fileInfo.Name)" -ForegroundColor Gray
} else {
    Write-Host "   unzip $($fileInfo.Name)" -ForegroundColor Gray
}
Write-Host "3. Navega al directorio:" -ForegroundColor White
Write-Host "   cd cybersec-tasks-offline" -ForegroundColor Gray
Write-Host "4. Ejecuta el script de instalación:" -ForegroundColor White
Write-Host "   chmod +x install.sh && ./install.sh" -ForegroundColor Gray
Write-Host "5. Inicializa la aplicación:" -ForegroundColor White
Write-Host "   chmod +x init-app.sh && ./init-app.sh" -ForegroundColor Gray

# Limpiar directorio temporal
Write-Host "`nLimpiando archivos temporales..." -ForegroundColor Yellow
Remove-Item -Path $PACKAGE_DIR -Recurse -Force

Write-Host "`n✅ Proceso completado" -ForegroundColor Green
