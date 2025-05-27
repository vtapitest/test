# Script para preparar un paquete offline que se instalará en Linux
Write-Host "=== Preparando paquete offline para CyberSec Tasks (para instalación en Linux) ===" -ForegroundColor Green

# Crear directorio para el paquete
$PACKAGE_DIR = "cybersec-tasks-offline"
if (Test-Path $PACKAGE_DIR) {
    Remove-Item -Path $PACKAGE_DIR -Recurse -Force
}
New-Item -Path $PACKAGE_DIR -ItemType Directory -Force | Out-Null

# Instalar dependencias si no existen
if (-not (Test-Path "node_modules")) {
    Write-Host "Instalando dependencias..." -ForegroundColor Yellow
    npm install
}

# Copiar archivos del proyecto
Write-Host "Copiando archivos del proyecto..." -ForegroundColor Yellow
Copy-Item -Path "app", "components", "lib", "public", "scripts", "docs" -Destination $PACKAGE_DIR -Recurse -ErrorAction SilentlyContinue
if (Test-Path ".next") {
    Copy-Item -Path ".next" -Destination $PACKAGE_DIR -Recurse
}
Copy-Item -Path "package.json", "package-lock.json", "next.config.mjs", "init-db.sql", "sample-tasks.sql" -Destination $PACKAGE_DIR
Copy-Item -Path "docker-compose.offline.yml" -Destination "$PACKAGE_DIR/docker-compose.yml"
Copy-Item -Path "Dockerfile.offline" -Destination "$PACKAGE_DIR/Dockerfile"

# Copiar node_modules
Write-Host "Copiando node_modules..." -ForegroundColor Yellow
Copy-Item -Path "node_modules" -Destination $PACKAGE_DIR -Recurse

# Descargar imágenes Docker
Write-Host "Descargando imágenes Docker..." -ForegroundColor Yellow
docker pull bitnami/node:18
docker pull bitnami/postgresql:15
docker pull bitnami/python:3.11

# Guardar imágenes Docker
Write-Host "Guardando imágenes Docker..." -ForegroundColor Yellow
New-Item -Path "$PACKAGE_DIR/docker-images" -ItemType Directory -Force | Out-Null
docker save bitnami/node:18 -o "$PACKAGE_DIR/docker-images/node.tar"
docker save bitnami/postgresql:15 -o "$PACKAGE_DIR/docker-images/postgresql.tar"
docker save bitnami/python:3.11 -o "$PACKAGE_DIR/docker-images/python.tar"

# Crear script de instalación para Linux
$installScript = @"
#!/bin/bash
set -e

echo "=== Instalando CyberSec Tasks en entorno Linux sin conexión ==="

# Verificar que Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Error: Docker no está instalado. Por favor, instala Docker antes de continuar."
    exit 1
fi

# Verificar que Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose no está instalado. Por favor, instala Docker Compose antes de continuar."
    exit 1
fi

# Cargar imágenes Docker
echo "Cargando imágenes Docker..."
docker load < docker-images/node.tar
docker load < docker-images/postgresql.tar
docker load < docker-images/python.tar

# Construir imagen de la aplicación
echo "Construyendo imagen de la aplicación..."
docker build -t cybersec-app:offline .

# Crear directorios para volúmenes si no existen
mkdir -p ./postgres_data

# Asignar permisos adecuados a los directorios de volúmenes
# El usuario 1001 es el usuario no root que usa Bitnami en sus imágenes
echo "Configurando permisos para volúmenes..."
chmod -R 777 ./postgres_data

# Iniciar contenedores
echo "Iniciando contenedores..."
docker-compose up -d

# Esperar a que la base de datos esté lista
echo "Esperando a que la base de datos esté lista..."
sleep 10

echo "=== Instalación completada ==="
echo "La aplicación estará disponible en http://localhost:3000"
echo ""
echo "Para verificar el estado de los contenedores, ejecuta:"
echo "docker-compose ps"
echo ""
echo "Para ver los logs de la aplicación, ejecuta:"
echo "docker-compose logs -f app"
echo ""
echo "Para detener la aplicación, ejecuta:"
echo "docker-compose down"
"@
Set-Content -Path "$PACKAGE_DIR/install.sh" -Value $installScript -Encoding UTF8

# Crear script para inicializar la base de datos
$initScript = @"
#!/bin/bash
set -e

echo "=== Inicializando base de datos ==="

# Ejecutar la inicialización de la API
echo "Inicializando la API..."
curl -X POST http://localhost:3000/api/init

echo "=== Inicialización completada ==="
"@
Set-Content -Path "$PACKAGE_DIR/init-app.sh" -Value $initScript -Encoding UTF8

# Crear script para reiniciar la aplicación
$restartScript = @"
#!/bin/bash
set -e

echo "=== Reiniciando CyberSec Tasks ==="

# Detener contenedores
echo "Deteniendo contenedores..."
docker-compose down

# Iniciar contenedores
echo "Iniciando contenedores..."
docker-compose up -d

echo "=== Reinicio completado ==="
echo "La aplicación estará disponible en http://localhost:3000"
"@
Set-Content -Path "$PACKAGE_DIR/restart.sh" -Value $restartScript -Encoding UTF8

# Crear script para hacer backup de la base de datos
$backupScript = @"
#!/bin/bash
set -e

BACKUP_DIR="./backups"
TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="\${BACKUP_DIR}/cybersec_db_\${TIMESTAMP}.sql"

echo "=== Creando backup de la base de datos ==="

# Crear directorio de backups si no existe
mkdir -p \$BACKUP_DIR

# Ejecutar backup
echo "Ejecutando backup..."
docker-compose exec -T db pg_dump -U postgres cybersec > \$BACKUP_FILE

echo "=== Backup completado ==="
echo "Archivo de backup: \$BACKUP_FILE"
"@
Set-Content -Path "$PACKAGE_DIR/backup-db.sh" -Value $backupScript -Encoding UTF8

# Crear script para restaurar la base de datos
$restoreScript = @"
#!/bin/bash
set -e

if [ -z "\$1" ]; then
    echo "Error: Debes especificar el archivo de backup a restaurar."
    echo "Uso: ./restore-db.sh ./backups/nombre_del_backup.sql"
    exit 1
fi

BACKUP_FILE="\$1"

if [ ! -f "\$BACKUP_FILE" ]; then
    echo "Error: El archivo de backup no existe: \$BACKUP_FILE"
    exit 1
fi

echo "=== Restaurando base de datos desde \$BACKUP_FILE ==="

# Restaurar backup
echo "Ejecutando restauración..."
docker-compose exec -T db psql -U postgres -d cybersec -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
cat \$BACKUP_FILE | docker-compose exec -T db psql -U postgres -d cybersec

echo "=== Restauración completada ==="
"@
Set-Content -Path "$PACKAGE_DIR/restore-db.sh" -Value $restoreScript -Encoding UTF8

# Crear README para Linux
$readmeContent = @"
# CyberSec Tasks - Instalación sin conexión a internet

Esta es una versión empaquetada de CyberSec Tasks que puede instalarse en un entorno Linux sin conexión a internet.

## Requisitos

- Docker (versión 20.10.0 o superior)
- Docker Compose (versión 2.0.0 o superior)
- Bash
- curl (para inicialización)

## Instalación

1. Asegúrate de que Docker y Docker Compose estén instalados en tu sistema.

2. Ejecuta el script de instalación:
   \`\`\`bash
   chmod +x install.sh
   ./install.sh
   \`\`\`

3. Una vez que los contenedores estén en funcionamiento, inicializa la aplicación:
   \`\`\`bash
   chmod +x init-app.sh
   ./init-app.sh
   \`\`\`

4. Accede a la aplicación en tu navegador: http://localhost:3000

## Scripts incluidos

- \`install.sh\`: Instala y ejecuta la aplicación
- \`init-app.sh\`: Inicializa la base de datos y carga datos de ejemplo
- \`restart.sh\`: Reinicia todos los contenedores
- \`backup-db.sh\`: Crea un backup de la base de datos
- \`restore-db.sh\`: Restaura la base de datos desde un backup

## Gestión de la aplicación

### Ver el estado de los contenedores
\`\`\`bash
docker-compose ps
\`\`\`

### Ver logs de la aplicación
\`\`\`bash
docker-compose logs -f app
\`\`\`

### Detener la aplicación
\`\`\`bash
docker-compose down
\`\`\`

### Reiniciar la aplicación
\`\`\`bash
./restart.sh
\`\`\`

## Backup y restauración

### Crear un backup
\`\`\`bash
chmod +x backup-db.sh
./backup-db.sh
\`\`\`

### Restaurar desde un backup
\`\`\`bash
chmod +x restore-db.sh
./restore-db.sh ./backups/nombre_del_backup.sql
\`\`\`

## Solución de problemas

### La aplicación no se inicia
Verifica los logs de la aplicación:
\`\`\`bash
docker-compose logs app
\`\`\`

### Problemas con la base de datos
Verifica los logs de la base de datos:
\`\`\`bash
docker-compose logs db
\`\`\`

### Reiniciar desde cero
Si necesitas reiniciar completamente la aplicación y eliminar todos los datos:
\`\`\`bash
docker-compose down -v
rm -rf ./postgres_data
./install.sh
./init-app.sh
\`\`\`
"@
Set-Content -Path "$PACKAGE_DIR/README.md" -Value $readmeContent -Encoding UTF8

# Convertir los scripts a formato Unix (LF en lugar de CRLF)
Write-Host "Convirtiendo scripts a formato Unix..." -ForegroundColor Yellow
$files = @("$PACKAGE_DIR/install.sh", "$PACKAGE_DIR/init-app.sh", "$PACKAGE_DIR/restart.sh", "$PACKAGE_DIR/backup-db.sh", "$PACKAGE_DIR/restore-db.sh")
foreach ($file in $files) {
    $content = Get-Content -Path $file -Raw
    $content = $content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($file, $content)
}

# Comprimir el paquete
Write-Host "Comprimiendo el paquete..." -ForegroundColor Yellow
if (Test-Path "cybersec-tasks-offline.tar.gz") {
    Remove-Item -Path "cybersec-tasks-offline.tar.gz" -Force
}

# Usar 7-Zip si está disponible, de lo contrario usar Compress-Archive
if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Usando 7-Zip para comprimir..." -ForegroundColor Yellow
    7z a -ttar cybersec-tasks-offline.tar $PACKAGE_DIR
    7z a -tgzip cybersec-tasks-offline.tar.gz cybersec-tasks-offline.tar
    Remove-Item -Path "cybersec-tasks-offline.tar" -Force
} else {
    Write-Host "7-Zip no encontrado, usando compresión nativa de PowerShell..." -ForegroundColor Yellow
    Compress-Archive -Path $PACKAGE_DIR -DestinationPath "cybersec-tasks-offline.zip" -Force
    Write-Host "NOTA: Se ha creado un archivo .zip en lugar de .tar.gz. Para Linux, es recomendable instalar 7-Zip y volver a ejecutar este script." -ForegroundColor Yellow
}

Write-Host "=== Paquete offline creado ===" -ForegroundColor Green
if (Test-Path "cybersec-tasks-offline.tar.gz") {
    Write-Host "Archivo: cybersec-tasks-offline.tar.gz" -ForegroundColor Cyan
} else {
    Write-Host "Archivo: cybersec-tasks-offline.zip" -ForegroundColor Cyan
}

Write-Host "Para instalar en un entorno Linux sin conexión:" -ForegroundColor Cyan
Write-Host "1. Transfiere el archivo comprimido al servidor Linux" -ForegroundColor White
Write-Host "2. Descomprime el archivo:" -ForegroundColor White
Write-Host "   tar -xzf cybersec-tasks-offline.tar.gz" -ForegroundColor White
Write-Host "3. Navega al directorio:" -ForegroundColor White
Write-Host "   cd cybersec-tasks-offline" -ForegroundColor White
Write-Host "4. Ejecuta el script de instalación:" -ForegroundColor White
Write-Host "   chmod +x install.sh" -ForegroundColor White
Write-Host "   ./install.sh" -ForegroundColor White
Write-Host "5. Inicializa la aplicación:" -ForegroundColor White
Write-Host "   chmod +x init-app.sh" -ForegroundColor White
Write-Host "   ./init-app.sh" -ForegroundColor White
