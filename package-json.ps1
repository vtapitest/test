# Script para instalar específicamente los módulos del package.json
Write-Host "Instalando módulos específicos del package.json..." -ForegroundColor Green

# Verificar que Docker está instalado
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker no está instalado o no está en el PATH." -ForegroundColor Red
    exit 1
}

# Crear directorio temporal
$tempDir = ".\temp-npm"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force

# Copiar solo package.json y package-lock.json
Write-Host "Copiando archivos de configuración..." -ForegroundColor Yellow
Copy-Item -Path ".\package.json" -Destination "$tempDir\package.json" -Force
if (Test-Path ".\package-lock.json") {
    Copy-Item -Path ".\package-lock.json" -Destination "$tempDir\package-lock.json" -Force
}

# Crear un Dockerfile simple y directo
@"
FROM node:20

WORKDIR /app
COPY package.json package.json
COPY package-lock.json* package-lock.json*

# Actualizar npm e instalar dependencias
RUN npm install -g npm@11.4.1 && \
    npm install && \
    echo "Verificando node_modules:" && \
    ls -la node_modules && \
    echo "Contando archivos en node_modules:" && \
    find node_modules -type f | wc -l

# Crear un archivo de verificación
RUN echo "Instalación completada" > installation_complete.txt
"@ | Out-File -FilePath "$tempDir\Dockerfile" -Encoding utf8

# Construir la imagen
Write-Host "Construyendo imagen Docker para instalar dependencias..." -ForegroundColor Yellow
docker build -t npm-modules-installer $tempDir

# Verificar si la construcción fue exitosa
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: La construcción de la imagen Docker falló." -ForegroundColor Red
    exit 1
}

# Crear un contenedor y montar un volumen para node_modules
Write-Host "Ejecutando contenedor para instalar dependencias..." -ForegroundColor Yellow
docker run --name npm-installer -v "${PWD}\$tempDir\node_modules:/app/node_modules" npm-modules-installer

# Verificar si el contenedor se ejecutó correctamente
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: La ejecución del contenedor falló." -ForegroundColor Red
    exit 1
}

# Verificar si node_modules se creó correctamente
if (-not (Test-Path "$tempDir\node_modules") -or (Get-ChildItem "$tempDir\node_modules" -Force | Measure-Object).Count -eq 0) {
    Write-Host "Error: node_modules no se creó correctamente." -ForegroundColor Red
    
    # Intentar copiar directamente desde el contenedor
    Write-Host "Intentando copiar node_modules directamente desde el contenedor..." -ForegroundColor Yellow
    docker cp npm-installer:/app/node_modules $tempDir
}

# Verificar nuevamente
if (-not (Test-Path "$tempDir\node_modules") -or (Get-ChildItem "$tempDir\node_modules" -Force | Measure-Object).Count -eq 0) {
    Write-Host "Error: No se pudo crear node_modules." -ForegroundColor Red
    exit 1
}

# Comprimir node_modules
Write-Host "Comprimiendo node_modules..." -ForegroundColor Yellow
if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) {
    # Usar 7-Zip
    7z a -ttar "$tempDir\node_modules.tar" "$tempDir\node_modules"
    7z a -tgzip "node_modules.tar.gz" "$tempDir\node_modules.tar"
    Remove-Item -Path "$tempDir\node_modules.tar" -Force
} elseif (Get-Command "tar.exe" -ErrorAction SilentlyContinue) {
    # Usar tar nativo
    tar -czf "node_modules.tar.gz" -C "$tempDir" "node_modules"
} else {
    # Usar PowerShell
    Compress-Archive -Path "$tempDir\node_modules\*" -DestinationPath "node_modules.zip" -Force
}

# Limpiar
Write-Host "Limpiando recursos..." -ForegroundColor Yellow
docker rm npm-installer -f
docker rmi npm-modules-installer -f
Remove-Item -Path $tempDir -Recurse -Force

# Verificar resultado
if (Test-Path "node_modules.tar.gz") {
    $size = (Get-Item "node_modules.tar.gz").Length / 1MB
    Write-Host "¡Éxito! node_modules.tar.gz creado: $([math]::Round($size, 2)) MB" -ForegroundColor Green
} elseif (Test-Path "node_modules.zip") {
    $size = (Get-Item "node_modules.zip").Length / 1MB
    Write-Host "¡Éxito! node_modules.zip creado: $([math]::Round($size, 2)) MB" -ForegroundColor Green
}
