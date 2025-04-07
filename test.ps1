# Script optimizado para contar miembros de grupo de Active Directory por mes
# Reemplaza "YourGroupName" con el nombre real del grupo

# Importar el módulo de Active Directory
Import-Module ActiveDirectory

# Definir el nombre del grupo
$groupName = "YourGroupName"

# Configurar para los primeros 3 meses de 2025
$currentYear = 2025
$currentDate = Get-Date -Month 3 -Day 31 -Year $currentYear

Write-Host "Obteniendo miembros del grupo $groupName..." -ForegroundColor Yellow

# Obtener todos los miembros del grupo especificado en una sola consulta eficiente
$allMembers = Get-ADGroupMember -Identity $groupName -Recursive | 
              Where-Object {$_.objectClass -eq "user"} | 
              Get-ADUser -Properties whenCreated

# Contar miembros totales
$totalMembers = $allMembers.Count
Write-Host "Procesando $totalMembers usuarios..." -ForegroundColor Yellow

# Crear un hashtable para almacenar usuarios por mes (más eficiente)
$usersByMonth = @{
    "January" = @()
    "February" = @()
    "March" = @()
}

# Clasificar usuarios por mes en una sola pasada
foreach ($member in $allMembers) {
    $created = $member.whenCreated
    
    # Solo procesar usuarios creados en 2025
    if ($created.Year -eq $currentYear) {
        switch ($created.Month) {
            1 { $usersByMonth["January"] += $member }
            2 { $usersByMonth["February"] += $member }
            3 { $usersByMonth["March"] += $member }
        }
    }
}

# Calcular conteos
$januaryCreated = $usersByMonth["January"].Count
$februaryCreated = $usersByMonth["February"].Count
$marchCreated = $usersByMonth["March"].Count

# Calcular miembros presentes en cada mes (acumulativo)
$marchCount = $totalMembers
$februaryCount = $marchCount - $marchCreated
$januaryCount = $februaryCount - $februaryCreated

# Mostrar resultados
Clear-Host
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "   MIEMBROS DE GRUPO DE AD POR MES $currentYear   " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Grupo: $groupName" -ForegroundColor Green
Write-Host "Total miembros: $totalMembers" -ForegroundColor Green
Write-Host "Fecha del informe: $(Get-Date)" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

Write-Host "`nCONTEO DE MIEMBROS POR MES ($currentYear):" -ForegroundColor Yellow
Write-Host "-----------------------------------------------" -ForegroundColor Yellow
Write-Host "Mes        | Creados | Total Presentes" -ForegroundColor Yellow
Write-Host "-----------------------------------------------" -ForegroundColor Yellow
Write-Host "Enero      | $januaryCreated".PadRight(12) -NoNewline
Write-Host " | $januaryCount" -ForegroundColor White
Write-Host "Febrero    | $februaryCreated".PadRight(12) -NoNewline
Write-Host " | $februaryCount" -ForegroundColor White
Write-Host "Marzo      | $marchCreated".PadRight(12) -NoNewline
Write-Host " | $marchCount" -ForegroundColor White
Write-Host "-----------------------------------------------" -ForegroundColor Yellow

Write-Host "`nRESULTADOS DETALLADOS:" -ForegroundColor Magenta

# Función para mostrar datos del mes
function Format-MonthData {
    param (
        [string]$Month,
        [array]$CreatedUsers,
        [int]$TotalUsers,
        [string]$MonthSpanish
    )
    
    Write-Host "`n$MonthSpanish $currentYear:" -ForegroundColor Cyan
    Write-Host "- Usuarios creados en $MonthSpanish: $($CreatedUsers.Count)" -ForegroundColor White
    Write-Host "- Total usuarios presentes en $MonthSpanish: $TotalUsers" -ForegroundColor White
    
    if ($CreatedUsers.Count -gt 0) {
        Write-Host "`nUsuarios creados en $MonthSpanish:" -ForegroundColor Gray
        $CreatedUsers | ForEach-Object {
            Write-Host "  - $($_.SamAccountName) ($($_.Name)) - Creado: $($_.whenCreated.ToString('yyyy-MM-dd'))" -ForegroundColor White
        }
    } else {
        Write-Host "  No se crearon usuarios en $MonthSpanish." -ForegroundColor Gray
    }
}

# Mostrar información detallada para cada mes
Format-MonthData -Month "January" -CreatedUsers $usersByMonth["January"] -TotalUsers $januaryCount -MonthSpanish "Enero"
Format-MonthData -Month "February" -CreatedUsers $usersByMonth["February"] -TotalUsers $februaryCount -MonthSpanish "Febrero"
Format-MonthData -Month "March" -CreatedUsers $usersByMonth["March"] -TotalUsers $marchCount -MonthSpanish "Marzo"

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "Informe completado para los primeros 3 meses de $currentYear" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
