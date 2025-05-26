@echo off
echo ===== Preparando proyecto para Linux sin internet =====

echo 1. Limpiando instalaciones previas...
if exist node_modules rmdir /s /q node_modules
if exist .next rmdir /s /q .next
if exist docker-export rmdir /s /q docker-export
mkdir docker-export

echo 2. Instalando dependencias...
call npm install --verbose

echo 3. Verificando dependencias faltantes...
call npm install --save-dev @types/react @types/react-dom @types/node
call npm install react react-dom next

echo 4. Intentando construir el proyecto...
set NODE_OPTIONS=--max-old-space-size=4096
call npx next build

if %ERRORLEVEL% NEQ 0 (
  echo La construcción falló. Intentando con opciones adicionales...
  call npm install --save-dev typescript @types/react @types/react-dom @types/node
  call npx next build --no-lint
)

echo 5. Descargando imágenes Docker necesarias...
docker pull bitnami/node:20
docker pull bitnami/postgresql:15
docker pull bitnami/nginx:1.25

echo 6. Guardando imágenes Docker...
docker save bitnami/node:20 > docker-export\node.tar
docker save bitnami/postgresql:15 > docker-export\postgresql.tar
docker save bitnami/nginx:1.25 > docker-export\nginx.tar

echo 7. Creando Dockerfile para Linux...
(
echo FROM bitnami/node:20 AS builder
echo WORKDIR /app
echo COPY . .
echo ENV NODE_ENV=production
echo RUN npx next build
echo FROM bitnami/node:20-prod
echo WORKDIR /app
echo COPY --from=builder /app/.next/standalone ./
echo COPY --from=builder /app/.next/static ./.next/static
echo COPY --from=builder /app/public ./public
echo COPY --from=builder /app/init-db.sql ./init-db.sql
echo COPY --from=builder /app/sample-tasks.sql ./sample-tasks.sql
echo ENV NODE_ENV=production
echo ENV PORT=3000
echo ENV HOSTNAME="0.0.0.0"
echo CMD ["node", "server.js"]
) > Dockerfile.offline

echo 8. Copiando archivos necesarios...
xcopy /E /I /Y . docker-export\app
del docker-export\app\node_modules /S /Q
del docker-export\app\.next /S /Q

echo 9. Creando scripts para Linux...
(
echo #!/bin/bash
echo echo "Cargando imágenes Docker..."
echo docker load -i node.tar
echo docker load -i postgresql.tar
echo docker load -i nginx.tar
echo echo "Imágenes cargadas correctamente."
echo cd app
echo echo "Construyendo la aplicación..."
echo docker build -f Dockerfile.offline -t cybersec-tasks:offline .
echo echo "Aplicación construida correctamente."
echo echo "Para iniciar la aplicación, ejecuta: docker-compose up -d"
) > docker-export\setup-linux.sh

echo 10. Copiando docker-compose.yml...
copy docker-compose.yml docker-export\app\

echo 11. Creando archivo README...
(
echo # Instrucciones para entorno Linux sin internet
echo 
echo ## Pasos para instalar
echo 
echo 1. Descomprime el archivo en el servidor Linux
echo 2. Ejecuta el script de configuración:
echo    ```
echo    chmod +x setup-linux.sh
echo    ./setup-linux.sh
echo    ```
echo 
echo 3. Navega a la carpeta de la aplicación:
echo    ```
echo    cd app
echo    ```
echo 
echo 4. Inicia los contenedores:
echo    ```
echo    docker-compose up -d
echo    ```
echo 
echo 5. La aplicación estará disponible en http://localhost
) > docker-export\README.md

echo 12. Comprimiendo todo para transferir...
powershell Compress-Archive -Path docker-export\* -DestinationPath cybersec-tasks-linux.zip -Force

echo ===== Proceso completado =====
echo El archivo "cybersec-tasks-linux.zip" está listo para ser transferido al entorno Linux sin internet.
echo Transfiere este archivo y sigue las instrucciones del README.md incluido.
