# Crear carpeta para archivos
New-Item -Path ".\docker-offline" -ItemType Directory -Force

# Descargar imagen base de Node.js
docker pull bitnami/node:20

# Construir la imagen principal usando buildx (evita problemas de shell)
docker buildx build --platform linux/amd64 -t cybersec-app:latest .

# Descargar imágenes base adicionales
docker pull bitnami/postgresql:15
docker pull bitnami/nginx:1.25

# Guardar todas las imágenes
docker save -o .\docker-offline\node.tar bitnami/node:20
docker save -o .\docker-offline\cybersec-app.tar cybersec-app:latest
docker save -o .\docker-offline\postgresql.tar bitnami/postgresql:15
docker save -o .\docker-offline\nginx.tar bitnami/nginx:1.25

# Copiar docker-compose.yml
Copy-Item -Path ".\docker-compose.yml" -Destination ".\docker-offline\docker-compose.yml"

# Crear script de inicio para Linux
@"
#!/bin/bash
echo "Cargando imágenes Docker..."
docker load -i node.tar
docker load -i cybersec-app.tar
docker load -i postgresql.tar
docker load -i nginx.tar
echo "Imágenes cargadas correctamente."
echo "Iniciando contenedores..."
docker-compose up -d
echo "Aplicación iniciada correctamente."
"@ | Out-File -FilePath ".\docker-offline\start.sh" -Encoding utf8

# Comprimir archivos
Compress-Archive -Path ".\docker-offline\*" -DestinationPath "cybersec-offline.zip" -Force

Write-Host "Paquete listo para transferir a Linux" -ForegroundColor Green
Write-Host "En Linux, ejecuta: bash start.sh" -ForegroundColor Yellow
