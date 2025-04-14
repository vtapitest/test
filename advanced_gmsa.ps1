# Script unificado para análisis completo de cuentas gMSA en Active Directory
# Author: v0
# Date: 2025-04-14

# Importar el módulo de Active Directory
Import-Module ActiveDirectory

# Obtener todas las cuentas gMSA
Write-Host "Recuperando todas las cuentas gMSA de Active Directory..." -ForegroundColor Cyan
$gMSAs = Get-ADServiceAccount -Filter * -Properties *

if ($gMSAs.Count -eq 0) {
    Write-Host "No se encontraron cuentas gMSA en el dominio." -ForegroundColor Yellow
    exit
}

Write-Host "Se encontraron $($gMSAs.Count) cuentas gMSA." -ForegroundColor Green

# Definir grupos privilegiados/inadecuados para gMSAs
$privilegedGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Administrators",
    "Account Operators",
    "Backup Operators",
    "Server Operators",
    "Print Operators",
    "Domain Controllers",
    "Domain Computers"  # Añadido Domain Computers como grupo inadecuado
)

# Definir atributos que deberían verificarse
$requiredAttributes = @(
    "msDS-GroupMSAMembership",
    "servicePrincipalName"
)

# Crear un array para almacenar resultados
$results = @()
$allAuthorizedComputerDetails = @()

# Primero, obtener el SID del grupo Domain Computers para una comparación más confiable
try {
    $domainComputersGroup = Get-ADGroup -Identity "Domain Computers" -Properties objectSid
    $domainComputersSID = $domainComputersGroup.objectSid.Value
    Write-Host "SID del grupo Domain Computers: $domainComputersSID" -ForegroundColor Cyan
} catch {
    Write-Host "No se pudo obtener el grupo Domain Computers. Error: $_" -ForegroundColor Yellow
    $domainComputersSID = $null
}

foreach ($gMSA in $gMSAs) {
    Write-Host "Analizando gMSA: $($gMSA.Name)" -ForegroundColor Cyan
    
    # Verificar si msDS-ManagedPassword está generado
    $hasManagedPassword = $null -ne $gMSA.'msDS-ManagedPassword'
    
    # Obtener equipos autorizados
    $authorizedPrincipals = $gMSA.'PrincipalsAllowedToRetrieveManagedPassword'
    $hasAuthorizedComputers = $authorizedPrincipals.Count -gt 0
    
    # Verificar si los equipos autorizados existen
    $allComputersExist = $true
    $authorizedComputerDetails = @()
    
    if ($hasAuthorizedComputers) {
        foreach ($principal in $authorizedPrincipals) {
            try {
                $adObject = Get-ADObject -Identity $principal -Properties objectClass, distinguishedName
                $isComputer = $adObject.objectClass -eq 'computer'
                
                # Verificar permisos reales sobre el atributo msDS-ManagedPassword
                $hasReadPermission = $false
                if ($isComputer) {
                    # Obtener los permisos ACL del objeto gMSA
                    $gMSAPath = "AD:$($gMSA.DistinguishedName)"
                    $acl = Get-Acl -Path $gMSAPath
                    
                    # Verificar si el equipo tiene permisos de lectura sobre msDS-ManagedPassword
                    foreach ($ace in $acl.Access) {
                        if ($ace.IdentityReference.Value.EndsWith($adObject.Name + '$') -and 
                            $ace.ActiveDirectoryRights -match "ReadProperty" -and 
                            ($ace.ObjectType -eq "00000000-0000-0000-0000-000000000000" -or 
                             $ace.ObjectType -eq "28630ebf-41d5-11d1-a9c1-0000f80367c1")) {
                            $hasReadPermission = $true
                            break
                        }
                    }
                }
                
                $computerDetail = [PSCustomObject]@{
                    DN = $adObject.distinguishedName
                    Name = $adObject.Name
                    Exists = $true
                    IsComputer = $isComputer
                    HasReadPermission = $hasReadPermission
                    gMSA = $gMSA.Name
                }
                
                $authorizedComputerDetails += $computerDetail
                $allAuthorizedComputerDetails += $computerDetail
                
                if (-not $isComputer) {
                    $allComputersExist = $false
                }
            }
            catch {
                $computerDetail = [PSCustomObject]@{
                    DN = $principal
                    Name = ($principal -split ',')[0] -replace 'CN=',''
                    Exists = $false
                    IsComputer = $false
                    HasReadPermission = $false
                    gMSA = $gMSA.Name
                }
                
                $authorizedComputerDetails += $computerDetail
                $allAuthorizedComputerDetails += $computerDetail
                $allComputersExist = $false
            }
        }
    }
    
    # Verificar pertenencia a grupos privilegiados
    $memberOfGroups = @()
    $inPrivilegedGroups = $false
    $privilegedGroupsList = @()
    $inDomainComputers = $false  # Nueva variable para Domain Computers
    
    # Verificar pertenencia directa a grupos
    foreach ($group in $gMSA.MemberOf) {
        try {
            $adGroup = Get-ADGroup -Identity $group -Properties objectSid
            $groupName = $adGroup.Name
            $groupSID = $adGroup.objectSid.Value
            
            $memberOfGroups += $groupName
            
            if ($privilegedGroups -contains $groupName) {
                $inPrivilegedGroups = $true
                $privilegedGroupsList += $groupName
            }
            
            # Verificar específicamente Domain Computers usando SID (más confiable)
            if ($domainComputersSID -and $groupSID -eq $domainComputersSID) {
                $inDomainComputers = $true
                Write-Host "La cuenta gMSA $($gMSA.Name) es miembro del grupo Domain Computers (verificado por SID)" -ForegroundColor Red
            }
            # Verificación adicional por nombre (respaldo)
            elseif ($groupName -eq "Domain Computers") {
                $inDomainComputers = $true
                Write-Host "La cuenta gMSA $($gMSA.Name) es miembro del grupo Domain Computers (verificado por nombre)" -ForegroundColor Red
            }
        }
        catch {
            # Grupo no encontrado o error al obtener información
            $memberOfGroups += "Error: $group"
            Write-Host "Error al verificar el grupo $group para la cuenta gMSA $($gMSA.Name): $_" -ForegroundColor Yellow
        }
    }
    
    # Verificación adicional usando Get-ADGroupMember (para capturar membresías que podrían no aparecer en MemberOf)
    if (-not $inDomainComputers -and $domainComputersSID) {
        try {
            $domainComputersMembers = Get-ADGroupMember -Identity $domainComputersSID
            foreach ($member in $domainComputersMembers) {
                if ($member.distinguishedName -eq $gMSA.DistinguishedName) {
                    $inDomainComputers = $true
                    $inPrivilegedGroups = $true
                    if (-not ($privilegedGroupsList -contains "Domain Computers")) {
                        $privilegedGroupsList += "Domain Computers"
                    }
                    if (-not ($memberOfGroups -contains "Domain Computers")) {
                        $memberOfGroups += "Domain Computers"
                    }
                    Write-Host "La cuenta gMSA $($gMSA.Name) es miembro del grupo Domain Computers (verificado por Get-ADGroupMember)" -ForegroundColor Red
                    break
                }
            }
        } catch {
            Write-Host "Error al verificar miembros del grupo Domain Computers: $_" -ForegroundColor Yellow
        }
    }
    
    # Verificar atributos requeridos
    $missingAttributes = @()
    foreach ($attr in $requiredAttributes) {
        if ($null -eq $gMSA.$attr -or $gMSA.$attr.Count -eq 0) {
            $missingAttributes += $attr
        }
    }
    $hasMissingAttributes = $missingAttributes.Count -gt 0
    
    # Verificar configuración de KerberosEncryptionType
    $validKerberosEncryption = $true
    $kerberosEncryptionTypes = $gMSA.KerberosEncryptionType
    
    # Verificar si usa encriptaciones débiles o está vacío
    if ($null -eq $kerberosEncryptionTypes -or $kerberosEncryptionTypes -eq 0) {
        $validKerberosEncryption = $false
    }
    else {
        # Convertir a entero para asegurar que la operación de bits funcione
        try {
            $encryptionValue = [int]$kerberosEncryptionTypes
            # Verifica si usa DES (0x1) o RC4 (0x2) (encriptaciones débiles)
            if (($encryptionValue -band 3) -ne 0) {
                $validKerberosEncryption = $false
            }
        }
        catch {
            # Si no se puede convertir, asumimos que hay un problema con la encriptación
            $validKerberosEncryption = $false
            Write-Host "Error al verificar el tipo de encriptación para $($gMSA.Name): $_" -ForegroundColor Yellow
        }
    }
    
    # Verificar si la cuenta tiene SPN duplicados
    $hasDuplicateSPNs = $false
    $duplicateSPNs = @()
    
    if ($null -ne $gMSA.ServicePrincipalName -and $gMSA.ServicePrincipalName.Count -gt 0) {
        foreach ($spn in $gMSA.ServicePrincipalName) {
            try {
                $spnCheck = Get-ADObject -Filter "ServicePrincipalName -eq '$spn'" -Properties ServicePrincipalName, distinguishedName
                if ($spnCheck.Count -gt 1) {
                    $hasDuplicateSPNs = $true
                    $duplicateSPNs += $spn
                }
            }
            catch {
                # Error al verificar SPN
            }
        }
    }
    
    # Verificar si la cuenta tiene una política de contraseña correcta
    $hasCorrectPasswordSettings = $true
    
    # Verificar si la cuenta está configurada para no expirar (lo cual es correcto para gMSAs)
    $passwordNeverExpires = $gMSA.PasswordNeverExpires
    if ($passwordNeverExpires -ne $true) {
        $hasCorrectPasswordSettings = $false
    }
    
    # Añadir a resultados
    $results += [PSCustomObject]@{
        Name = $gMSA.Name
        DN = $gMSA.DistinguishedName
        HasManagedPassword = $hasManagedPassword
        Enabled = $gMSA.Enabled
        HasAuthorizedComputers = $hasAuthorizedComputers
        AuthorizedComputersCount = $authorizedPrincipals.Count
        AllAuthorizedComputersExist = $allComputersExist
        AllAuthorizedComputersHavePermission = if ($hasAuthorizedComputers) { 
            ($authorizedComputerDetails | Where-Object { -not $_.HasReadPermission }).Count -eq 0 
        } else { 
            $false 
        }
        AuthorizedComputers = $authorizedComputerDetails
        InPrivilegedGroups = $inPrivilegedGroups
        PrivilegedGroupsList = $privilegedGroupsList
        InDomainComputers = $inDomainComputers  # Nueva propiedad
        MemberOfGroups = $memberOfGroups
        HasMissingAttributes = $hasMissingAttributes
        MissingAttributes = $missingAttributes
        ValidKerberosEncryption = $validKerberosEncryption
        KerberosEncryptionType = $kerberosEncryptionTypes
        HasDuplicateSPNs = $hasDuplicateSPNs
        DuplicateSPNs = $duplicateSPNs
        HasCorrectPasswordSettings = $hasCorrectPasswordSettings
        PasswordNeverExpires = $passwordNeverExpires
        SPNs = $gMSA.ServicePrincipalName
    }
}

# Exportar a CSV
$csvPath = "$env:USERPROFILE\Desktop\Analisis_gMSA_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Select-Object -Property Name, DN, HasManagedPassword, Enabled, HasAuthorizedComputers, AuthorizedComputersCount, 
    AllAuthorizedComputersExist, AllAuthorizedComputersHavePermission, InPrivilegedGroups, InDomainComputers, HasMissingAttributes, 
    ValidKerberosEncryption, HasDuplicateSPNs, HasCorrectPasswordSettings | 
    Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Resultados exportados a: $csvPath" -ForegroundColor Green

# Exportar detalles de equipos autorizados
$csvDetailPath = "$env:USERPROFILE\Desktop\Detalles_Equipos_Autorizados_gMSA_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$allAuthorizedComputerDetails | Export-Csv -Path $csvDetailPath -NoTypeInformation
Write-Host "Detalles de equipos autorizados exportados a: $csvDetailPath" -ForegroundColor Green

# Generar informe HTML
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Análisis Completo de Cuentas gMSA</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        h1, h2, h3 {
            color: #0066cc;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
            background-color: white;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #0066cc;
            color: white;
            position: sticky;
            top: 0;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #e6f2ff;
        }
        .success {
            background-color: #dff0d8;
            color: #3c763d;
        }
        .warning {
            background-color: #fcf8e3;
            color: #8a6d3b;
        }
        .danger {
            background-color: #f2dede;
            color: #a94442;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .summary {
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }
        .summary-box {
            background-color: white;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            width: 23%;
            text-align: center;
            margin-bottom: 10px;
        }
        .summary-box h3 {
            margin-top: 0;
        }
        .summary-box.blue {
            border-top: 4px solid #0066cc;
        }
        .summary-box.green {
            border-top: 4px solid #5cb85c;
        }
        .summary-box.yellow {
            border-top: 4px solid #f0ad4e;
        }
        .summary-box.red {
            border-top: 4px solid #d9534f;
        }
        .big-number {
            font-size: 24px;
            font-weight: bold;
            margin: 10px 0;
        }
        .accordion {
            background-color: #eee;
            color: #444;
            cursor: pointer;
            padding: 18px;
            width: 100%;
            text-align: left;
            border: none;
            outline: none;
            transition: 0.4s;
            margin-bottom: 1px;
        }
        .active, .accordion:hover {
            background-color: #ccc;
        }
        .panel {
            padding: 0 18px;
            background-color: white;
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.2s ease-out;
        }
        .timestamp {
            text-align: right;
            font-style: italic;
            color: #666;
            margin-top: 20px;
        }
        .badge {
            display: inline-block;
            padding: 3px 7px;
            font-size: 12px;
            font-weight: bold;
            line-height: 1;
            color: #fff;
            text-align: center;
            white-space: nowrap;
            vertical-align: middle;
            border-radius: 10px;
        }
        .badge-success {
            background-color: #5cb85c;
        }
        .badge-warning {
            background-color: #f0ad4e;
        }
        .badge-danger {
            background-color: #d9534f;
        }
        .tab {
            overflow: hidden;
            border: 1px solid #ccc;
            background-color: #f1f1f1;
            border-radius: 5px 5px 0 0;
        }
        .tab button {
            background-color: inherit;
            float: left;
            border: none;
            outline: none;
            cursor: pointer;
            padding: 14px 16px;
            transition: 0.3s;
            font-size: 17px;
        }
        .tab button:hover {
            background-color: #ddd;
        }
        .tab button.active {
            background-color: #0066cc;
            color: white;
        }
        .tabcontent {
            display: none;
            padding: 6px 12px;
            border: 1px solid #ccc;
            border-top: none;
            border-radius: 0 0 5px 5px;
            animation: fadeEffect 1s;
        }
        @keyframes fadeEffect {
            from {opacity: 0;}
            to {opacity: 1;}
        }
        .flex-container {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }
        .flex-item {
            flex: 1 1 300px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Análisis Completo de Cuentas gMSA en Active Directory</h1>
        <p>Este informe muestra un análisis detallado de todas las cuentas de servicio administradas del dominio (gMSA), incluyendo configuración, permisos, grupos y atributos.</p>
        <p class="timestamp">Informe generado el $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
        
        <div class="summary">
            <div class="summary-box blue">
                <h3>Total gMSAs</h3>
                <div class="big-number">$($results.Count)</div>
            </div>
            <div class="summary-box green">
                <h3>Habilitadas</h3>
                <div class="big-number">$($results | Where-Object { $_.Enabled -eq $true } | Measure-Object | Select-Object -ExpandProperty Count)</div>
            </div>
            <div class="summary-box yellow">
                <h3>Con Contraseña</h3>
                <div class="big-number">$($results | Where-Object { $_.HasManagedPassword -eq $true } | Measure-Object | Select-Object -ExpandProperty Count)</div>
            </div>
            <div class="summary-box red">
                <h3>Sin Equipos</h3>
                <div class="big-number">$($results | Where-Object { $_.HasAuthorizedComputers -eq $false } | Measure-Object | Select-Object -ExpandProperty Count)</div>
            </div>
            <div class="summary-box red">
                <h3>En Grupos Privilegiados</h3>
                <div class="big-number">$($results | Where-Object { $_.InPrivilegedGroups -eq $true } | Measure-Object | Select-Object -ExpandProperty Count)</div>
            </div>
            <div class="summary-box red">
                <h3>En Domain Computers</h3>
                <div class="big-number">$($results | Where-Object { $_.InDomainComputers -eq $true } | Measure-Object | Select-Object -ExpandProperty Count)</div>
            </div>
            <div class="summary-box yellow">
                <h3>Atributos Faltantes</h3>
                <div class="big-number">$($results | Where-Object { $_.HasMissingAttributes -eq $true } | Measure-Object | Select-Object -ExpandProperty Count)</div>
            </div>
            <div class="summary-box yellow">
                <h3>Encriptación Inválida</h3>
                <div class="big-number">$($results | Where-Object { $_.ValidKerberosEncryption -eq $false } | Measure-Object | Select-Object -ExpandProperty Count)</div>
            </div>
            <div class="summary-box red">
                <h3>SPNs Duplicados</h3>
                <div class="big-number">$($results | Where-Object { $_.HasDuplicateSPNs -eq $true } | Measure-Object | Select-Object -ExpandProperty Count)</div>
            </div>
        </div>
    </div>

    <div class="container">
        <h2>Resumen de Cuentas gMSA</h2>
        <div class="tab">
            <button class="tablinks active" onclick="openTab(event, 'TabGeneral')">General</button>
            <button class="tablinks" onclick="openTab(event, 'TabSeguridad')">Seguridad</button>
            <button class="tablinks" onclick="openTab(event, 'TabConfiguracion')">Configuración</button>
        </div>
        
        <div id="TabGeneral" class="tabcontent" style="display: block;">
            <table>
                <tr>
                    <th>Nombre</th>
                    <th>Habilitada</th>
                    <th>Tiene Contraseña</th>
                    <th>Equipos Autorizados</th>
                    <th>Nº Equipos</th>
                    <th>Equipos Existen</th>
                    <th>Equipos con Permisos</th>
                </tr>
"@

foreach ($result in $results) {
    $enabledClass = if ($result.Enabled) { "success" } else { "danger" }
    $passwordClass = if ($result.HasManagedPassword) { "success" } else { "danger" }
    $authComputersClass = if ($result.HasAuthorizedComputers) { "success" } else { "warning" }
    $allExistClass = if ($result.AllAuthorizedComputersExist) { "success" } else { "danger" }
    $allPermissionClass = if ($result.AllAuthorizedComputersHavePermission) { "success" } else { "danger" }
    
    $htmlReport += @"
                <tr>
                    <td>$($result.Name)</td>
                    <td class="$enabledClass">$($result.Enabled)</td>
                    <td class="$passwordClass">$($result.HasManagedPassword)</td>
                    <td class="$authComputersClass">$($result.HasAuthorizedComputers)</td>
                    <td>$($result.AuthorizedComputersCount)</td>
                    <td class="$allExistClass">$($result.AllAuthorizedComputersExist)</td>
                    <td class="$allPermissionClass">$($result.AllAuthorizedComputersHavePermission)</td>
                </tr>
"@
}

$htmlReport += @"
            </table>
        </div>
        
        <div id="TabSeguridad" class="tabcontent">
            <table>
                <tr>
                    <th>Nombre</th>
                    <th>En Grupos Privilegiados</th>
                    <th>En Domain Computers</th>
                    <th>Grupos Privilegiados</th>
                    <th>Encriptación Válida</th>
                    <th>SPNs Duplicados</th>
                </tr>
"@

foreach ($result in $results) {
    $privilegedClass = if ($result.InPrivilegedGroups) { "danger" } else { "success" }
    $domainComputersClass = if ($result.InDomainComputers) { "danger" } else { "success" }
    $encryptionClass = if ($result.ValidKerberosEncryption) { "success" } else { "warning" }
    $spnClass = if ($result.HasDuplicateSPNs) { "danger" } else { "success" }
    
    $htmlReport += @"
                <tr>
                    <td>$($result.Name)</td>
                    <td class="$privilegedClass">$($result.InPrivilegedGroups)</td>
                    <td class="$domainComputersClass">$($result.InDomainComputers)</td>
                    <td>$(if ($result.PrivilegedGroupsList.Count -gt 0) { $result.PrivilegedGroupsList -join ", " } else { "Ninguno" })</td>
                    <td class="$encryptionClass">$($result.ValidKerberosEncryption)</td>
                    <td class="$spnClass">$($result.HasDuplicateSPNs)</td>
                </tr>
"@
}

$htmlReport += @"
            </table>
        </div>
        
        <div id="TabConfiguracion" class="tabcontent">
            <table>
                <tr>
                    <th>Nombre</th>
                    <th>Atributos Faltantes</th>
                    <th>Lista Atributos Faltantes</th>
                    <th>Config. Contraseña Correcta</th>
                    <th>Contraseña No Expira</th>
                </tr>
"@

foreach ($result in $results) {
    $attributesClass = if ($result.HasMissingAttributes) { "warning" } else { "success" }
    $passwordSettingsClass = if ($result.HasCorrectPasswordSettings) { "success" } else { "danger" }
    $passwordExpiresClass = if ($result.PasswordNeverExpires) { "success" } else { "danger" }
    
    $htmlReport += @"
                <tr>
                    <td>$($result.Name)</td>
                    <td class="$attributesClass">$($result.HasMissingAttributes)</td>
                    <td>$(if ($result.MissingAttributes.Count -gt 0) { $result.MissingAttributes -join ", " } else { "Ninguno" })</td>
                    <td class="$passwordSettingsClass">$($result.HasCorrectPasswordSettings)</td>
                    <td class="$passwordExpiresClass">$($result.PasswordNeverExpires)</td>
                </tr>
"@
}

$htmlReport += @"
            </table>
        </div>
    </div>

    <div class="container">
        <h2>Detalles de Cuentas gMSA</h2>
"@

foreach ($result in $results) {
    # Calcular el estado general de la cuenta
    $statusBadges = @()
    
    if (-not $result.Enabled) {
        $statusBadges += '<span class="badge badge-danger">Deshabilitada</span>'
    }
    if (-not $result.HasManagedPassword) {
        $statusBadges += '<span class="badge badge-danger">Sin Contraseña</span>'
    }
    if (-not $result.HasAuthorizedComputers) {
        $statusBadges += '<span class="badge badge-warning">Sin Equipos</span>'
    }
    if ($result.InPrivilegedGroups) {
        $statusBadges += '<span class="badge badge-danger">Grupo Privilegiado</span>'
    }
    if ($result.InDomainComputers) {
        $statusBadges += '<span class="badge badge-danger">En Domain Computers</span>'
    }
    if ($result.HasMissingAttributes) {
        $statusBadges += '<span class="badge badge-warning">Atributos Faltantes</span>'
    }
    if (-not $result.ValidKerberosEncryption) {
        $statusBadges += '<span class="badge badge-warning">Encriptación Débil</span>'
    }
    if ($result.HasDuplicateSPNs) {
        $statusBadges += '<span class="badge badge-danger">SPNs Duplicados</span>'
    }
    
    $statusBadgesHtml = if ($statusBadges.Count -gt 0) { $statusBadges -join " " } else { '<span class="badge badge-success">OK</span>' }
    
    $htmlReport += @"
        <button class="accordion">$($result.Name) - $statusBadgesHtml</button>  }
    
    $htmlReport += @"
        <button class="accordion">$($result.Name) - $statusBadgesHtml</button>
        <div class="panel">
            <div class="flex-container">
                <div class="flex-item">
                    <h3>Información General</h3>
                    <p><strong>Distinguished Name:</strong> $($result.DN)</p>
                    <p><strong>Habilitada:</strong> <span class="$(if ($result.Enabled) { "success" } else { "danger" })">$($result.Enabled)</span></p>
                    <p><strong>Tiene Contraseña Gestionada:</strong> <span class="$(if ($result.HasManagedPassword) { "success" } else { "danger" })">$($result.HasManagedPassword)</span></p>
                    <p><strong>Configuración de Contraseña Correcta:</strong> <span class="$(if ($result.HasCorrectPasswordSettings) { "success" } else { "danger" })">$($result.HasCorrectPasswordSettings)</span></p>
                    <p><strong>Contraseña No Expira:</strong> <span class="$(if ($result.PasswordNeverExpires) { "success" } else { "danger" })">$($result.PasswordNeverExpires)</span></p>
                </div>
                
                <div class="flex-item">
                    <h3>Seguridad</h3>
                    <p><strong>En Grupos Privilegiados:</strong> <span class="$(if ($result.InPrivilegedGroups) { "danger" } else { "success" })">$($result.InPrivilegedGroups)</span></p>
                    <p><strong>En Domain Computers:</strong> <span class="$(if ($result.InDomainComputers) { "danger" } else { "success" })">$($result.InDomainComputers)</span></p>
                    <p><strong>Grupos Privilegiados:</strong> $(if ($result.PrivilegedGroupsList.Count -gt 0) { $result.PrivilegedGroupsList -join ", " } else { "Ninguno" })</p>
                    <p><strong>Encriptación Kerberos Válida:</strong> <span class="$(if ($result.ValidKerberosEncryption) { "success" } else { "warning" })">$($result.ValidKerberosEncryption)</span></p>
                    <p><strong>Tipo de Encriptación:</strong> $($result.KerberosEncryptionType)</p>
                    <p><strong>SPNs Duplicados:</strong> <span class="$(if ($result.HasDuplicateSPNs) { "danger" } else { "success" })">$($result.HasDuplicateSPNs)</span></p>
                </div>
            </div>
            
            <div class="flex-container">
                <div class="flex-item">
                    <h3>Atributos</h3>
                    <p><strong>Atributos Faltantes:</strong> <span class="$(if ($result.HasMissingAttributes) { "warning" } else { "success" })">$($result.HasMissingAttributes)</span></p>
                    <p><strong>Lista de Atributos Faltantes:</strong> $(if ($result.MissingAttributes.Count -gt 0) { $result.MissingAttributes -join ", " } else { "Ninguno" })</p>
                    <h4>SPNs Configurados:</h4>
                    <ul>
"@

    if ($null -ne $result.SPNs -and $result.SPNs.Count -gt 0) {
        foreach ($spn in $result.SPNs) {
            $spnClass = if ($result.DuplicateSPNs -contains $spn) { "danger" } else { "success" }
            $htmlReport += @"
                        <li class="$spnClass">$spn $(if ($result.DuplicateSPNs -contains $spn) { "<span class='badge badge-danger'>Duplicado</span>" } else { "" })</li>
"@
        }
    } else {
        $htmlReport += @"
                        <li>No hay SPNs configurados</li>
"@
    }

    $htmlReport += @"
                    </ul>
                </div>
                
                <div class="flex-item">
                    <h3>Grupos</h3>
                    <p><strong>Miembro de Grupos:</strong></p>
                    <ul>
"@

    if ($result.MemberOfGroups.Count -gt 0) {
        foreach ($group in $result.MemberOfGroups) {
            $groupClass = if ($result.PrivilegedGroupsList -contains $group) { "danger" } else { "success" }
            $htmlReport += @"
                        <li class="$groupClass">$group $(if ($result.PrivilegedGroupsList -contains $group) { "<span class='badge badge-danger'>Privilegiado</span>" } else { "" })</li>
"@
        }
    } else {
        $htmlReport += @"
                        <li>No es miembro de ningún grupo</li>
"@
    }

    $htmlReport += @"
                    </ul>
                </div>
            </div>
            
"@

    if ($result.HasAuthorizedComputers) {
        $htmlReport += @"
            <h3>Equipos Autorizados</h3>
            <table>
                <tr>
                    <th>#</th>
                    <th>Nombre</th>
                    <th>Existe</th>
                    <th>Es Equipo</th>
                    <th>Tiene Permisos</th>
                </tr>
"@

        $i = 1
        foreach ($computer in $result.AuthorizedComputers) {
            $existsClass = if ($computer.Exists) { "success" } else { "danger" }
            $isComputerClass = if ($computer.IsComputer) { "success" } else { "warning" }
            $hasPermissionClass = if ($computer.HasReadPermission) { "success" } else { "danger" }
            
            $htmlReport += @"
                <tr>
                    <td>$i</td>
                    <td>$($computer.Name)</td>
                    <td class="$existsClass">$($computer.Exists)</td>
                    <td class="$isComputerClass">$($computer.IsComputer)</td>
                    <td class="$hasPermissionClass">$($computer.HasReadPermission)</td>
                </tr>
"@
            $i++
        }

        $htmlReport += @"
            </table>
"@
    } else {
        $htmlReport += @"
            <h3>Equipos Autorizados</h3>
            <p class="warning">No hay equipos autorizados para recuperar la contraseña gestionada.</p>
"@
    }

    $htmlReport += @"
        </div>
"@
}

$htmlReport += @"
    </div>

    <script>
        var acc = document.getElementsByClassName("accordion");
        var i;

        for (i = 0; i < acc.length; i++) {
            acc[i].addEventListener("click", function() {
                this.classList.toggle("active");
                var panel = this.nextElementSibling;
                if (panel.style.maxHeight) {
                    panel.style.maxHeight = null;
                } else {
                    panel.style.maxHeight = panel.scrollHeight + "px";
                }
            });
        }
        
        function openTab(evt, tabName) {
            var i, tabcontent, tablinks;
            tabcontent = document.getElementsByClassName("tabcontent");
            for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
            }
            tablinks = document.getElementsByClassName("tablinks");
            for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }
            document.getElementById(tabName).style.display = "block";
            evt.currentTarget.className += " active";
        }
    </script>
</body>
</html>
"@

# Guardar el informe HTML
$htmlPath = "$env:USERPROFILE\Desktop\Informe_Completo_gMSA_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$htmlReport | Out-File -FilePath $htmlPath -Encoding utf8
Write-Host "Informe HTML generado en: $htmlPath" -ForegroundColor Green

# Abrir el informe HTML automáticamente
Start-Process $htmlPath
