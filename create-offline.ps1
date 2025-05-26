# Crear carpeta para archivos
New-Item -Path ".\docker-offline" -ItemType Directory -Force

# Descargar SOLO las imágenes base necesarias
Write-Host "Descargando imágenes base..." -ForegroundColor Cyan
docker pull bitnami/node:20
docker pull bitnami/postgresql:15
docker pull bitnami/nginx:1.25

# Guardar las imágenes base
Write-Host "Guardando imágenes base..." -ForegroundColor Cyan
docker save -o .\docker-offline\node.tar bitnami/node:20
docker save -o .\docker-offline\postgresql.tar bitnami/postgresql:15
docker save -o .\docker-offline\nginx.tar bitnami/nginx:1.25

# Copiar archivos del proyecto
Write-Host "Copiando archivos del proyecto..." -ForegroundColor Cyan
New-Item -Path ".\docker-offline\project" -ItemType Directory -Force

# Excluir directorios y archivos grandes/innecesarios
$exclude = @("node_modules", ".next", ".git", "docker-offline", "*.tar", "*.zip")

# Copiar todos los archivos excepto los excluidos
Get-ChildItem -Path .\ -Exclude $exclude | ForEach-Object {
    if ($_.PSIsContainer) {
        Copy-Item -Path $_.FullName -Destination ".\docker-offline\project\$($_.Name)" -Recurse -Force
    } else {
        Copy-Item -Path $_.FullName -Destination ".\docker-offline\project\" -Force
    }
}

# Crear script de configuración para Linux
@"
#!/bin/bash
echo "=== Configuración del entorno sin internet ==="

echo "Cargando imágenes Docker base..."
docker load -i node.tar
docker load -i postgresql.tar
docker load -i nginx.tar

echo "Cambiando al directorio del proyecto..."
cd ./project

echo "Construyendo la imagen de la aplicación en Linux..."
docker build -t cybersec-app:latest .

echo "Iniciando contenedores..."
docker-compose up -d

echo "=== Configuración completada ==="
echo "La aplicación debería estar disponible en http://localhost"
"@ | Out-File -FilePath ".\docker-offline\setup-linux.sh" -Encoding utf8

# Comprimir todo para transferencia
Write-Host "Comprimiendo paquete final..." -ForegroundColor Cyan
Compress-Archive -Path ".\docker-offline\*" -DestinationPath "cybersec-offline-complete.zip" -Force

Write-Host "¡Paquete listo para transferir a Linux!" -ForegroundColor Green
Write-Host "En Linux, ejecuta: bash setup-linux.sh" -ForegroundColor Yellow
