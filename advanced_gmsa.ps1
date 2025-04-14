# Script para analizar cuentas gMSA en Active Directory y generar informe HTML
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

# Crear un array para almacenar resultados
$results = @()
$allAuthorizedComputerDetails = @()

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
    }
}

# Exportar a CSV
$csvPath = "$env:USERPROFILE\Desktop\Analisis_gMSA_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Select-Object -Property Name, DN, HasManagedPassword, Enabled, HasAuthorizedComputers, AuthorizedComputersCount, AllAuthorizedComputersExist, AllAuthorizedComputersHavePermission | 
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
    <title>Análisis de Cuentas gMSA</title>
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
            margin-bottom: 20px;
        }
        .summary-box {
            background-color: white;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            width: 23%;
            text-align: center;
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
    </style>
</head>
<body>
    <div class="container">
        <h1>Análisis de Cuentas gMSA en Active Directory</h1>
        <p>Este informe muestra un análisis detallado de todas las cuentas de servicio administradas del dominio (gMSA).</p>
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
        </div>
    </div>

    <div class="container">
        <h2>Resumen de Cuentas gMSA</h2>
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

    <div class="container">
        <h2>Detalles de Cuentas gMSA</h2>
"@

foreach ($result in $results) {
    $htmlReport += @"
        <button class="accordion">$($result.Name) - $(if ($result.Enabled) { "Habilitada" } else { "Deshabilitada" })</button>
        <div class="panel">
            <p><strong>Distinguished Name:</strong> $($result.DN)</p>
            <p><strong>Habilitada:</strong> $($result.Enabled)</p>
            <p><strong>Tiene Contraseña Gestionada:</strong> $($result.HasManagedPassword)</p>
            <p><strong>Tiene Equipos Autorizados:</strong> $($result.HasAuthorizedComputers)</p>
            <p><strong>Número de Equipos Autorizados:</strong> $($result.AuthorizedComputersCount)</p>
            <p><strong>Todos los Equipos Autorizados Existen:</strong> $($result.AllAuthorizedComputersExist)</p>
            <p><strong>Todos los Equipos Autorizados Tienen Permisos:</strong> $($result.AllAuthorizedComputersHavePermission)</p>
            
"@

    if ($result.HasAuthorizedComputers -and $result.AuthorizedComputers.Count -gt 0) {
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
    </script>
</body>
</html>
"@

# Guardar el informe HTML
$htmlPath = "$env:USERPROFILE\Desktop\Informe_gMSA_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$htmlReport | Out-File -FilePath $htmlPath -Encoding utf8
Write-Host "Informe HTML generado en: $htmlPath" -ForegroundColor Green

# Abrir el informe HTML automáticamente
Start-Process $htmlPath
