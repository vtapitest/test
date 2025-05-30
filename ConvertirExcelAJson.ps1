<#
.SYNOPSIS
    Convierte datos de un archivo Excel (.xlsx) seleccionado interactivamente
    a un archivo JSON (.json) en C:\temp, siguiendo un mapeo de columnas especificado.

.DESCRIPTION
    Este script solicita al usuario que seleccione un archivo Excel. Luego, lee el archivo,
    transforma cada fila según un mapeo de columnas definido, y guarda el resultado
    como un archivo JSON en la carpeta C:\temp.
    Requiere el módulo 'ImportExcel' y acceso a System.Windows.Forms para el diálogo.

.NOTES
    Asegúrate de tener instalado el módulo 'ImportExcel': Install-Module -Name ImportExcel -Scope CurrentUser
    Debes personalizar la sección '$columnMapping' en el script para que coincida
    con las columnas de tu Excel y el formato JSON deseado.
    El script intentará crear la carpeta C:\temp si no existe.
#>
[CmdletBinding()]
param () # No se necesitan parámetros de entrada ahora

# Verifica si el módulo ImportExcel está disponible
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Error "El módulo 'ImportExcel' no está instalado. Por favor, instálalo ejecutando: Install-Module -Name ImportExcel -Scope CurrentUser"
    exit 1
}

# --- SELECCIÓN INTERACTIVA DEL ARCHIVO EXCEL ---
try {
    Add-Type -AssemblyName System.Windows.Forms
}
catch {
    Write-Error "No se pudo cargar System.Windows.Forms. Este script requiere un entorno que lo soporte para el diálogo de selección de archivo."
    exit 1
}

$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Title = "Selecciona el archivo Excel a convertir"
$openFileDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")
$openFileDialog.Filter = "Archivos Excel (*.xlsx)|*.xlsx|Todos los archivos (*.*)|*.*"
$openFileDialog.FilterIndex = 1 # Por defecto selecciona el filtro de archivos Excel

if ($openFileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "Operación cancelada por el usuario. No se seleccionó ningún archivo."
    exit
}

$InputExcelPath = $openFileDialog.FileName
Write-Host "Archivo Excel seleccionado: $InputExcelPath"

# --- DEFINICIÓN DE LA RUTA DE SALIDA ---
$OutputDirectory = "C:\temp"
# Crea el directorio de salida si no existe
if (-not (Test-Path $OutputDirectory)) {
    try {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        Write-Host "Directorio de salida '$OutputDirectory' creado."
    }
    catch {
        Write-Error "No se pudo crear el directorio de salida '$OutputDirectory'. Verifica los permisos. Error: $($_.Exception.Message)"
        exit 1
    }
}

$excelBaseName = [System.IO.Path]::GetFileNameWithoutExtension($InputExcelPath)
$OutputJsonPath = Join-Path -Path $OutputDirectory -ChildPath "$($excelBaseName).json"

# --- PERSONALIZA ESTA SECCIÓN ---
# Define el mapeo de las columnas de Excel a las claves JSON.
# Formato: "NombreColumnaExcel" = "NombreClaveJson"
# Asegúrate de que los nombres de las columnas de Excel coincidan EXACTAMENTE
# con los encabezados de tu archivo .xlsx (sensible a mayúsculas/minúsculas).
$columnMapping = @{
    "ID Producto"     = "productId"
    "Nombre"          = "productName"
    "Categoría"       = "category"
    "Precio Unitario" = "unitPrice"
    "Stock"           = "stockQuantity"
    # Agrega más mapeos según tus necesidades
    # Ejemplo:
    # "Nombre Completo" = "fullName"
    # "Correo Electrónico" = "email"
}
# --- FIN DE LA SECCIÓN DE PERSONALIZACIÓN ---

Write-Host "Procesando el archivo Excel: $InputExcelPath"
Write-Host "El archivo JSON se guardará en: $OutputJsonPath"

try {
    # Importa los datos de la primera hoja del archivo Excel
    # Si necesitas una hoja específica, usa el parámetro -WorksheetName "NombreDeTuHoja"
    $excelData = Import-Excel -Path $InputExcelPath

    if ($null -eq $excelData) {
        Write-Warning "No se encontraron datos en el archivo Excel o la hoja está vacía."
        exit 1
    }

    $jsonDataArray = @()

    foreach ($row in $excelData) {
        $jsonObject = [PSCustomObject]@{}
        foreach ($excelHeader in $columnMapping.Keys) {
            $jsonKey = $columnMapping[$excelHeader]
            
            if ($row.PSObject.Properties.Name -contains $excelHeader) {
                $jsonObject | Add-Member -MemberType NoteProperty -Name $jsonKey -Value $row.$excelHeader
            } else {
                Write-Warning "La columna '$excelHeader' definida en el mapeo no se encontró en el archivo Excel. Se omitirá para esta fila."
                # Opcionalmente, puedes agregar la clave JSON con un valor nulo o predeterminado:
                # $jsonObject | Add-Member -MemberType NoteProperty -Name $jsonKey -Value $null
            }
        }
        $jsonDataArray += $jsonObject
    }

    if ($jsonDataArray.Count -eq 0) {
        Write-Warning "No se generaron datos JSON. Verifica tu mapeo de columnas y el contenido del Excel."
        exit 1
    }

    $jsonOutput = $jsonDataArray | ConvertTo-Json -Depth 5 

    Set-Content -Path $OutputJsonPath -Value $jsonOutput -Encoding UTF8
    
    Write-Host "Archivo JSON generado exitosamente en: $OutputJsonPath"

}
catch {
    Write-Error "Ocurrió un error durante el procesamiento: $($_.Exception.Message)"
    exit 1
}
