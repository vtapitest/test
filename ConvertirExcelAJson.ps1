<#
.SYNOPSIS
    Convierte datos de un archivo Excel (.xlsx) a un archivo JSON (.json)
    siguiendo un mapeo de columnas especificado.

.DESCRIPTION
    Este script lee un archivo Excel, transforma cada fila según un mapeo de columnas
    definido por el usuario, y luego guarda el resultado como un archivo JSON.
    Requiere el módulo 'ImportExcel'.

.PARAMETER InputExcelPath
    Ruta completa al archivo Excel de entrada (.xlsx).

.PARAMETER OutputJsonPath
    Ruta completa donde se guardará el archivo JSON de salida (.json).

.EXAMPLE
    .\ConvertirExcelAJson.ps1 -InputExcelPath "C:\ruta\a\tu\archivo.xlsx" -OutputJsonPath "C:\ruta\a\tu\salida.json"

.NOTES
    Asegúrate de tener instalado el módulo 'ImportExcel': Install-Module -Name ImportExcel -Scope CurrentUser
    Debes personalizar la sección '$columnMapping' en el script para que coincida
    con las columnas de tu Excel y el formato JSON deseado.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Ruta completa al archivo Excel de entrada (.xlsx)")]
    [string]$InputExcelPath,

    [Parameter(Mandatory = $true, HelpMessage = "Ruta completa donde se guardará el archivo JSON de salida (.json)")]
    [string]$OutputJsonPath
)

# Verifica si el módulo ImportExcel está disponible
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Error "El módulo 'ImportExcel' no está instalado. Por favor, instálalo ejecutando: Install-Module -Name ImportExcel -Scope CurrentUser"
    exit 1
}

# Verifica si el archivo de entrada existe
if (-not (Test-Path $InputExcelPath)) {
    Write-Error "El archivo de entrada '$InputExcelPath' no existe."
    exit 1
}

# --- PERSONALIZA ESTA SECCIÓN ---
# Define el mapeo de las columnas de Excel a las claves JSON.
# Formato: "NombreColumnaExcel" = "NombreClaveJson"
# Asegúrate de que los nombres de las columnas de Excel coincidan EXACTAMENTE
# con los encabezados de tu archivo .xlsx (sensible a mayúsculas/minúsculas).
$columnMapping = @{
    "ID Producto"  = "productId"
    "Nombre"       = "productName"
    "Categoría"    = "category"
    "Precio Unitario" = "unitPrice"
    "Stock"        = "stockQuantity"
    # Agrega más mapeos según tus necesidades
    # Ejemplo:
    # "Nombre Completo" = "fullName"
    # "Correo Electrónico" = "email"
}
# --- FIN DE LA SECCIÓN DE PERSONALIZACIÓN ---

Write-Host "Procesando el archivo Excel: $InputExcelPath"

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
            
            # Verifica si la columna de Excel existe en la fila actual
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

    # Convierte el array de objetos a formato JSON
    # El parámetro -Depth controla la profundidad de la serialización. Para estructuras simples, el valor por defecto suele ser suficiente.
    # Si tienes objetos anidados complejos, podrías necesitar aumentar este valor.
    $jsonOutput = $jsonDataArray | ConvertTo-Json -Depth 5 

    # Guarda el JSON en el archivo de salida
    Set-Content -Path $OutputJsonPath -Value $jsonOutput -Encoding UTF8
    
    Write-Host "Archivo JSON generado exitosamente en: $OutputJsonPath"

}
catch {
    Write-Error "Ocurrió un error durante el procesamiento: $($_.Exception.Message)"
    exit 1
}
