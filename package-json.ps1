# Script para descargar módulos de Node.js usando Docker
Write-Host "Descargando módulos de Node.js usando Docker..." -ForegroundColor Green

# Verificar que Docker está instalado
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker no está instalado o no está en el PATH." -ForegroundColor Red
    Write-Host "Por favor, instala Docker Desktop para Windows: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Crear directorio temporal para los archivos
$tempDir = ".\temp-docker"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force

# Copiar package.json al directorio temporal
Write-Host "Copiando package.json al directorio temporal..." -ForegroundColor Yellow
Copy-Item -Path ".\package.json" -Destination "$tempDir\package.json" -Force
if (Test-Path ".\package-lock.json") {
    Copy-Item -Path ".\package-lock.json" -Destination "$tempDir\package-lock.json" -Force
}

# Crear Dockerfile temporal
@"
FROM node:20

WORKDIR /app
COPY package.json .
COPY package-lock.json* .
RUN npm install --no-audit --no-fund
"@ | Out-File -FilePath "$tempDir\Dockerfile" -Encoding utf8

# Construir imagen Docker
Write-Host "Construyendo imagen Docker para instalar dependencias..." -ForegroundColor Yellow
docker build -t temp-node-modules $tempDir

# Crear contenedor temporal y copiar node_modules
Write-Host "Extrayendo node_modules del contenedor Docker..." -ForegroundColor Yellow
docker create --name temp-node-container temp-node-modules
docker cp temp-node-container:/app/node_modules $tempDir/node_modules
docker rm temp-node-container

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

# Limpiar recursos
Write-Host "Limpiando recursos temporales..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force
docker rmi temp-node-modules -f

# Mostrar información del archivo creado
if (Test-Path ".\node_modules.tar.gz") {
    $size = (Get-Item ".\node_modules.tar.gz").Length / 1MB
    Write-Host "¡Listo! Archivo node_modules.tar.gz creado: $([math]::Round($size, 2)) MB" -ForegroundColor Green
} elseif (Test-Path ".\node_modules.zip") {
    $size = (Get-Item ".\node_modules.zip").Length / 1MB
    Write-Host "¡Listo! Archivo node_modules.zip creado: $([math]::Round($size, 2)) MB" -ForegroundColor Green
    Write-Host "Nota: Se ha creado un archivo ZIP en lugar de tar.gz debido a limitaciones de PowerShell." -ForegroundColor Yellow
}

Write-Host "Proceso completado." -ForegroundColor Green
