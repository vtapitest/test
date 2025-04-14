<#
.SYNOPSIS
    Script para auditar configuraciones incorrectas de cuentas gMSA en Active Directory.
.DESCRIPTION
    Este script identifica y documenta configuraciones erróneas relacionadas con cuentas
    de servicio administradas por grupo (gMSA) en Active Directory, incluyendo su presencia
    en grupos inadecuados y atributos mal configurados.
.NOTES
    Autor: v0 Assistant
    Fecha: 14/04/2025
#>

# Importar módulo de Active Directory
Import-Module ActiveDirectory

# Configuración de log
$logPath = "$env:USERPROFILE\Desktop\gMSA_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$ErrorActionPreference = "Continue"

# Función para escribir en el log
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Escribir en consola
    switch ($Level) {
        "INFO"    { Write-Host $logMessage -ForegroundColor Green }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
    }
    
    # Escribir en archivo de log
    Add-Content -Path $logPath -Value $logMessage
}

Write-Log "Iniciando auditoría de cuentas gMSA en Active Directory..."

# 1. Identificación de gMSA en grupos inadecuados
Write-Log "SECCIÓN 1: Identificando gMSA en grupos inadecuados..."

# Lista de grupos sensibles a verificar
$gruposSensibles = @(
    "Domain Computers",
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Administrators",
    "Server Operators",
    "Account Operators",
    "Backup Operators"
)

# Colección para almacenar resultados
$gMSAsEnGruposInadecuados = @()

foreach ($grupo in $gruposSensibles) {
    Write-Log "Verificando grupo: $grupo" -Level "INFO"
    
    try {
        # Obtener miembros del grupo
        $miembrosGrupo = Get-ADGroupMember -Identity $grupo -ErrorAction Stop
        
        # Filtrar por gMSAs
        foreach ($miembro in $miembrosGrupo) {
            try {
                $objetoAD = Get-ADObject -Identity $miembro.distinguishedName -Properties objectClass, objectCategory, whenCreated, whenChanged -ErrorAction Stop
                
                # Verificar si es una gMSA
                if ($objetoAD.objectClass -contains "msDS-GroupManagedServiceAccount") {
                    $gMSA = Get-ADServiceAccount -Identity $miembro.distinguishedName -Properties * -ErrorAction Stop
                    
                    $gMSAsEnGruposInadecuados += [PSCustomObject]@{
                        SamAccountName = $gMSA.SamAccountName
                        DistinguishedName = $gMSA.DistinguishedName
                        GrupoInadecuado = $grupo
                        FechaCreacion = $gMSA.whenCreated
                        UltimaModificacion = $gMSA.whenChanged
                    }
                    
                    Write-Log "¡ALERTA! gMSA '$($gMSA.SamAccountName)' encontrada en grupo inadecuado: $grupo" -Level "WARNING"
                }
            }
            catch {
                Write-Log "Error al procesar miembro $($miembro.distinguishedName): $_" -Level "ERROR"
            }
        }
    }
    catch {
        Write-Log "Error al obtener miembros del grupo $grupo: $_" -Level "ERROR"
    }
}

# 2. Verificación de atributos clave en todas las gMSAs
Write-Log "SECCIÓN 2: Verificando atributos clave de todas las gMSAs..."

$todasLasGMSAs = @()
try {
    # Obtener todas las gMSAs del dominio
    $todasLasGMSAs = Get-ADServiceAccount -Filter * -Properties *
    Write-Log "Se encontraron $($todasLasGMSAs.Count) cuentas gMSA en el dominio" -Level "INFO"
}
catch {
    Write-Log "Error al obtener todas las gMSAs: $_" -Level "ERROR"
}

$gMSAsConAtributosIncorrectos = @()

foreach ($gMSA in $todasLasGMSAs) {
    $problemas = @()
    
    # Verificar PrincipalsAllowedToRetrieveManagedPassword
    if (-not $gMSA.PrincipalsAllowedToRetrieveManagedPassword -or $gMSA.PrincipalsAllowedToRetrieveManagedPassword.Count -eq 0) {
        $problemas += "No tiene configurado PrincipalsAllowedToRetrieveManagedPassword"
    }
    
    # Verificar msDS-ManagedPassword (este atributo es generado automáticamente, pero verificamos su existencia)
    if (-not $gMSA.'msDS-ManagedPassword') {
        $problemas += "Posible problema con msDS-ManagedPassword"
    }
    
    # Verificar otros atributos críticos
    if (-not $gMSA.DistinguishedName -or -not $gMSA.SamAccountName) {
        $problemas += "Atributos básicos incompletos (DistinguishedName o SamAccountName)"
    }
    
    if ($problemas.Count -gt 0) {
        $gMSAsConAtributosIncorrectos += [PSCustomObject]@{
            SamAccountName = $gMSA.SamAccountName
            DistinguishedName = $gMSA.DistinguishedName
            Problemas = $problemas -join ", "
            PrincipalsAllowed = $gMSA.PrincipalsAllowedToRetrieveManagedPassword -join ";"
        }
        
        Write-Log "gMSA '$($gMSA.SamAccountName)' tiene problemas de configuración: $($problemas -join ", ")" -Level "WARNING"
    }
}

# 3. Evidenciación de otros posibles errores
Write-Log "SECCIÓN 3: Buscando otros posibles errores de configuración..."

$gMSAsConOtrosErrores = @()

# Verificar gMSAs en grupos de equipos (además de Domain Computers)
$gruposDeEquipos = Get-ADGroup -Filter "name -like '*computer*' -or name -like '*servidor*' -or name -like '*server*'" -Properties Members

foreach ($grupoEquipo in $gruposDeEquipos) {
    if ($grupoEquipo.Name -eq "Domain Computers") {
        # Ya lo verificamos antes
        continue
    }
    
    try {
        $miembrosGrupo = Get-ADGroupMember -Identity $grupoEquipo -ErrorAction Stop
        
        foreach ($miembro in $miembrosGrupo) {
            try {
                $objetoAD = Get-ADObject -Identity $miembro.distinguishedName -Properties objectClass -ErrorAction Stop
                
                if ($objetoAD.objectClass -contains "msDS-GroupManagedServiceAccount") {
                    $gMSA = Get-ADServiceAccount -Identity $miembro.distinguishedName -Properties * -ErrorAction Stop
                    
                    $gMSAsConOtrosErrores += [PSCustomObject]@{
                        SamAccountName = $gMSA.SamAccountName
                        DistinguishedName = $gMSA.DistinguishedName
                        TipoError = "En grupo de equipos"
                        Detalles = "Presente en grupo de equipos: $($grupoEquipo.Name)"
                    }
                    
                    Write-Log "gMSA '$($gMSA.SamAccountName)' encontrada en grupo de equipos: $($grupoEquipo.Name)" -Level "WARNING"
                }
            }
            catch {
                Write-Log "Error al procesar miembro $($miembro.distinguishedName): $_" -Level "ERROR"
            }
        }
    }
    catch {
        Write-Log "Error al obtener miembros del grupo $($grupoEquipo.Name): $_" -Level "ERROR"
    }
}

# Verificar gMSAs modificadas recientemente (últimos 7 días)
$fechaLimite = (Get-Date).AddDays(-7)
foreach ($gMSA in $todasLasGMSAs) {
    if ($gMSA.whenChanged -gt $fechaLimite) {
        $gMSAsConOtrosErrores += [PSCustomObject]@{
            SamAccountName = $gMSA.SamAccountName
            DistinguishedName = $gMSA.DistinguishedName
            TipoError = "Modificación reciente"
            Detalles = "Modificada el $($gMSA.whenChanged)"
        }
        
        Write-Log "gMSA '$($gMSA.SamAccountName)' fue modificada recientemente: $($gMSA.whenChanged)" -Level "INFO"
    }
}

# 4. Salida y documentación
Write-Log "SECCIÓN 4: Generando informe final..."

# Crear informe HTML
$reportPath = "$env:USERPROFILE\Desktop\gMSA_Audit_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Informe de Auditoría de gMSAs</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #003366; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .warning { background-color: #fff3cd; }
        .error { background-color: #f8d7da; }
        .summary { margin-bottom: 20px; padding: 10px; background-color: #e9ecef; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Informe de Auditoría de Cuentas gMSA en Active Directory</h1>
    <div class="summary">
        <p><strong>Fecha de ejecución:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Dominio:</strong> $((Get-ADDomain).DNSRoot)</p>
        <p><strong>Total de gMSAs encontradas:</strong> $($todasLasGMSAs.Count)</p>
        <p><strong>gMSAs en grupos inadecuados:</strong> $($gMSAsEnGruposInadecuados.Count)</p>
        <p><strong>gMSAs con atributos incorrectos:</strong> $($gMSAsConAtributosIncorrectos.Count)</p>
        <p><strong>gMSAs con otros errores:</strong> $($gMSAsConOtrosErrores.Count)</p>
    </div>
"@

$htmlFooter = @"
</body>
</html>
"@

# Función para convertir una colección a tabla HTML
function ConvertTo-HtmlTable {
    param (
        [Parameter(Mandatory=$true)]
        [Array]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$Title
    )
    
    if ($Data.Count -eq 0) {
        return "<h2>$Title</h2><p>No se encontraron resultados.</p>"
    }
    
    $html = "<h2>$Title</h2>"
    $html += "<table>"
    
    # Encabezados de tabla
    $html += "<tr>"
    foreach ($property in $Data[0].PSObject.Properties.Name) {
        $html += "<th>$property</th>"
    }
    $html += "</tr>"
    
    # Filas de datos
    foreach ($item in $Data) {
        $html += "<tr>"
        foreach ($property in $item.PSObject.Properties.Name) {
            $html += "<td>$($item.$property)</td>"
        }
        $html += "</tr>"
    }
    
    $html += "</table>"
    return $html
}

# Generar secciones de la tabla
$htmlGMSAsEnGruposInadecuados = ConvertTo-HtmlTable -Data $gMSAsEnGruposInadecuados -Title "gMSAs en Grupos Inadecuados"
$htmlGMSAsConAtributosIncorrectos = ConvertTo-HtmlTable -Data $gMSAsConAtributosIncorrectos -Title "gMSAs con Atributos Incorrectos"
$htmlGMSAsConOtrosErrores = ConvertTo-HtmlTable -Data $gMSAsConOtrosErrores -Title "gMSAs con Otros Errores"

# Sección de recomendaciones
$htmlRecomendaciones = @"
<h2>Recomendaciones</h2>
<ul>
    <li><strong>gMSAs en grupos inadecuados:</strong> Remover las cuentas gMSA de grupos como "Domain Computers" u otros grupos sensibles donde no deberían estar.</li>
    <li><strong>Configuración de PrincipalsAllowedToRetrieveManagedPassword:</strong> Asegurarse de que este atributo esté correctamente configurado para cada gMSA, incluyendo solo los servidores o grupos que realmente necesitan acceso.</li>
    <li><strong>Revisión periódica:</strong> Establecer un proceso de revisión periódica de las configuraciones de gMSA para evitar desviaciones.</li>
    <li><strong>Documentación:</strong> Mantener documentación actualizada de todas las gMSAs, su propósito y configuración correcta.</li>
</ul>
"@

# Combinar todo el HTML
$htmlContent = $htmlHeader + $htmlGMSAsEnGruposInadecuados + $htmlGMSAsConAtributosIncorrectos + $htmlGMSAsConOtrosErrores + $htmlRecomendaciones + $htmlFooter

# Guardar el informe HTML
$htmlContent | Out-File -FilePath $reportPath -Encoding UTF8

# Exportar también a CSV para análisis adicional
$gMSAsEnGruposInadecuados | Export-Csv -Path "$env:USERPROFILE\Desktop\gMSA_GruposInadecuados_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation
$gMSAsConAtributosIncorrectos | Export-Csv -Path "$env:USERPROFILE\Desktop\gMSA_AtributosIncorrectos_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation
$gMSAsConOtrosErrores | Export-Csv -Path "$env:USERPROFILE\Desktop\gMSA_OtrosErrores_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation

# Resumen final
Write-Log "Auditoría completada. Resultados:" -Level "INFO"
Write-Log "- Total de gMSAs encontradas: $($todasLasGMSAs.Count)" -Level "INFO"
Write-Log "- gMSAs en grupos inadecuados: $($gMSAsEnGruposInadecuados.Count)" -Level "INFO"
Write-Log "- gMSAs con atributos incorrectos: $($gMSAsConAtributosIncorrectos.Count)" -Level "INFO"
Write-Log "- gMSAs con otros errores: $($gMSAsConOtrosErrores.Count)" -Level "INFO"
Write-Log "Informe HTML guardado en: $reportPath" -Level "INFO"
Write-Log "Archivos CSV guardados en el escritorio" -Level "INFO"
Write-Log "Archivo de log guardado en: $logPath" -Level "INFO"

# Abrir el informe HTML automáticamente
Invoke-Item $reportPath
