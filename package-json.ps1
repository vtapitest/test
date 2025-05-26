# Script para descargar módulos de Node.js usando Docker
Write-Host "Descargando módulos de Node.js usando Docker (versión corregida)..." -ForegroundColor Green

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

# Crear Dockerfile temporal con tu solución
@"
FROM node:20

WORKDIR /app
COPY package.json .
COPY package-lock.json* .

# Actualizar npm a la versión específica que funciona
RUN npm install -g npm@11.4.1

# Instalar dependencias y verificar que node_modules existe
RUN npm install --no-audit --no-fund && \
    ls -la /app && \
    ls -la /app/node_modules || echo "node_modules no se creó correctamente"

# Crear un archivo de marcador para verificar la ubicación
RUN echo "node_modules_exists" > /app/node_modules_marker.txt
"@ | Out-File -FilePath "$tempDir\Dockerfile" -Encoding utf8

# Construir imagen Docker
Write-Host "Construyendo imagen Docker para instalar dependencias..." -ForegroundColor Yellow
docker build -t temp-node-modules $tempDir

# Crear contenedor temporal
Write-Host "Creando contenedor temporal..." -ForegroundColor Yellow
docker create --name temp-node-container temp-node-modules

# Verificar la estructura del contenedor
Write-Host "Verificando estructura del contenedor..." -ForegroundColor Yellow
docker exec -it temp-node-container ls -la /app || Write-Host "No se puede ejecutar comandos en el contenedor" -ForegroundColor Red

# Intentar encontrar node_modules en diferentes ubicaciones
Write-Host "Buscando node_modules en el contenedor..." -ForegroundColor Yellow
$locations = @("/app/node_modules", "/node_modules", "/usr/local/lib/node_modules")
$foundLocation = $null

foreach ($location in $locations) {
    Write-Host "Verificando $location..." -ForegroundColor Cyan
    docker cp temp-node-container:$location $tempDir/node_modules 2>$null
    if ($LASTEXITCODE -eq 0 -and (Test-Path "$tempDir\node_modules") -and (Get-ChildItem "$tempDir\node_modules" | Measure-Object).Count -gt 0) {
        $foundLocation = $location
        Write-Host "¡node_modules encontrado en $location!" -ForegroundColor Green
        break
    }
}

# Si no se encontró en las ubicaciones comunes, usar un enfoque alternativo
if (-not $foundLocation) {
    Write-Host "No se encontró node_modules en las ubicaciones comunes." -ForegroundColor Yellow
    Write-Host "Intentando enfoque alternativo: exportar todo el contenedor..." -ForegroundColor Yellow
    
    # Crear un script para encontrar node_modules
    @"
#!/bin/sh
find / -name "node_modules" -type d 2>/dev/null
"@ | Out-File -FilePath "$tempDir\find-modules.sh" -Encoding utf8
    
    # Copiar el script al contenedor
    docker cp "$tempDir\find-modules.sh" temp-node-container:/find-modules.sh
    
    # Hacer el script ejecutable y ejecutarlo
    docker exec temp-node-container chmod +x /find-modules.sh
    $moduleLocations = docker exec temp-node-container /find-modules.sh
    
    # Intentar copiar desde cada ubicación encontrada
    foreach ($location in $moduleLocations) {
        $location = $location.Trim()
        if (-not [string]::IsNullOrEmpty($location)) {
            Write-Host "Intentando copiar desde $location..." -ForegroundColor Cyan
            docker cp "temp-node-container:$location" "$tempDir\node_modules" 2>$null
            if ($LASTEXITCODE -eq 0 -and (Test-Path "$tempDir\node_modules") -and (Get-ChildItem "$tempDir\node_modules" | Measure-Object).Count -gt 0) {
                $foundLocation = $location
                Write-Host "¡node_modules encontrado en $location!" -ForegroundColor Green
                break
            }
        }
    }
}

# Verificar si se encontró node_modules
if (-not $foundLocation -or -not (Test-Path "$tempDir\node_modules") -or (Get-ChildItem "$tempDir\node_modules" | Measure-Object).Count -eq 0) {
    Write-Host "Error: No se pudo encontrar o copiar node_modules desde el contenedor." -ForegroundColor Red
    
    # Enfoque de último recurso: exportar todo el contenedor
    Write-Host "Último intento: exportando todo el contenedor..." -ForegroundColor Yellow
    docker export temp-node-container -o "$tempDir\container.tar"
    
    # Extraer el contenedor completo
    if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) {
        7z x "$tempDir\container.tar" -o"$tempDir\container-extract" "*/node_modules/*" -r
    } elseif (Get-Command "tar.exe" -ErrorAction SilentlyContinue) {
        mkdir -p "$tempDir\container-extract"
        tar -xf "$tempDir\container.tar" -C "$tempDir\container-extract" --wildcards "*/node_modules/*"
    } else {
        Write-Host "Error: No se puede extraer el contenedor sin 7z o tar." -ForegroundColor Red
        exit 1
    }
    
    # Buscar node_modules en la extracción
    $extractedModules = Get-ChildItem "$tempDir\container-extract" -Recurse -Directory -Filter "node_modules" | Select-Object -First 1
    if ($extractedModules) {
        Copy-Item -Path $extractedModules.FullName -Destination "$tempDir\node_modules" -Recurse -Force
        Write-Host "node_modules encontrado en la extracción del contenedor." -ForegroundColor Green
    } else {
        Write-Host "Error: No se pudo encontrar node_modules en ninguna parte." -ForegroundColor Red
        exit 1
    }
}

# Limpiar contenedor
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
