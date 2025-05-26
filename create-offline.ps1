# Limpieza inicial
if (Test-Path ".\offline-package") {
    Remove-Item -Path ".\offline-package" -Recurse -Force
}
New-Item -Path ".\offline-package" -ItemType Directory -Force

# Descargar imágenes base
Write-Host "Descargando imágenes Docker..." -ForegroundColor Green
docker pull bitnami/node:20
docker pull bitnami/postgresql:15
docker pull bitnami/nginx:1.25

# Guardar imágenes
Write-Host "Guardando imágenes Docker..." -ForegroundColor Green
docker save -o .\offline-package\node.tar bitnami/node:20
docker save -o .\offline-package\postgresql.tar bitnami/postgresql:15
docker save -o .\offline-package\nginx.tar bitnami/nginx:1.25

# Instalar dependencias y generar node_modules.tar.gz
Write-Host "Instalando dependencias y generando node_modules.tar.gz..." -ForegroundColor Green

# Verificar si node_modules ya existe
if (-not (Test-Path ".\node_modules")) {
    Write-Host "Instalando dependencias con npm..." -ForegroundColor Yellow
    npm install
}

# Crear directorio temporal para node_modules
New-Item -Path ".\temp-modules" -ItemType Directory -Force

# Copiar node_modules al directorio temporal
Copy-Item -Path ".\node_modules" -Destination ".\temp-modules\" -Recurse -Force

# Comprimir node_modules usando 7-Zip (si está instalado)
if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Comprimiendo node_modules con 7-Zip..." -ForegroundColor Yellow
    7z a -ttar ".\temp-modules\node_modules.tar" ".\temp-modules\node_modules"
    7z a -tgzip ".\offline-package\node_modules.tar.gz" ".\temp-modules\node_modules.tar"
    Remove-Item -Path ".\temp-modules\node_modules.tar" -Force
} else {
    # Alternativa usando PowerShell (más lento pero no requiere 7-Zip)
    Write-Host "Comprimiendo node_modules con PowerShell..." -ForegroundColor Yellow
    Compress-Archive -Path ".\temp-modules\node_modules\*" -DestinationPath ".\offline-package\node_modules.zip" -Force
}

# Limpiar directorio temporal
Remove-Item -Path ".\temp-modules" -Recurse -Force

# Copiar archivos del proyecto
Write-Host "Copiando archivos del proyecto..." -ForegroundColor Green
New-Item -Path ".\offline-package\project" -ItemType Directory -Force

# Excluir archivos innecesarios
$exclude = @("node_modules", ".next", ".git", "offline-package")

# Copiar archivos
Get-ChildItem -Path .\ -Exclude $exclude | ForEach-Object {
    if ($_.PSIsContainer) {
        Copy-Item -Path $_.FullName -Destination ".\offline-package\project\$($_.Name)" -Recurse -Force
    } else {
        Copy-Item -Path $_.FullName -Destination ".\offline-package\project\" -Force
    }
}

# Crear script para Linux
@"
#!/bin/bash
echo "=== Configuración del entorno sin internet ==="

echo "Cargando imágenes Docker..."
docker load -i node.tar
docker load -i postgresql.tar
docker load -i nginx.tar

echo "Cambiando al directorio del proyecto..."
cd ./project

echo "Extrayendo node_modules preinstalado..."
if [ -f "../node_modules.tar.gz" ]; then
    mkdir -p node_modules
    tar -xzf ../node_modules.tar.gz -C .
elif [ -f "../node_modules.zip" ]; then
    mkdir -p node_modules
    unzip -q ../node_modules.zip -d ./node_modules
fi

echo "Construyendo la imagen de la aplicación..."
docker build -t cybersec-app:latest .

echo "Iniciando contenedores..."
docker-compose up -d

echo "=== Configuración completada ==="
echo "La aplicación debería estar disponible en http://localhost"
"@ | Out-File -FilePath ".\offline-package\setup.sh" -Encoding utf8

# Comprimir para transferencia
Write-Host "Comprimiendo paquete..." -ForegroundColor Green
Compress-Archive -Path ".\offline-package\*" -DestinationPath "offline-package.zip" -Force

Write-Host "¡LISTO!" -ForegroundColor Green
Write-Host "1. Transfiere 'offline-package.zip' al servidor Linux" -ForegroundColor Yellow
Write-Host "2. Descomprime el archivo en Linux" -ForegroundColor Yellow
Write-Host "3. Ejecuta: bash setup.sh" -ForegroundColor Yellow
