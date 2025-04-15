<#
.SYNOPSIS
    Script de auditoría de seguridad para Microsoft Entra ID (Azure AD) con reporte HTML.
.DESCRIPTION
    Este script realiza una auditoría de seguridad básica en Microsoft Entra ID utilizando
    los módulos MSOnline o AzureAD, y genera un reporte HTML con estilos y buena presentación.
.NOTES
    Requisitos:
    - Módulos MSOnline o AzureAD
    - Permisos básicos de lectura en Azure AD
    Fecha: 15/04/2025
#>

#region Configuración inicial
# Configuración de preferencias de error
$ErrorActionPreference = "Continue"
$WarningPreference = "SilentlyContinue"

# Crear carpeta para el reporte si no existe
$reportFolder = "$env:USERPROFILE\EntraIDSecurityAudit"
if (-not (Test-Path -Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder | Out-Null
}

$reportFile = "$reportFolder\EntraIDSecurityAuditReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$logFile = "$reportFolder\EntraIDSecurityAuditLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Función para escribir en el log
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $logFile -Value $logEntry
    
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
    }
}

# Inicializar el HTML
$htmlHeader = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Auditoría de Seguridad de Microsoft Entra ID</title>
    <style>
        :root {
            --primary-color: #0078d4;
            --secondary-color: #106ebe;
            --accent-color: #ffaa44;
            --warning-color: #d13438;
            --success-color: #107c10;
            --info-color: #0078d4;
            --bg-color: #f9f9f9;
            --card-bg: #ffffff;
            --text-color: #323130;
            --text-light: #605e5c;
            --border-color: #edebe9;
            --hover-color: #f3f2f1;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: var(--text-color);
            background-color: var(--bg-color);
            padding: 0;
            margin: 0;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        header {
            background-color: var(--primary-color);
            color: white;
            padding: 20px 0;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        header .container {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header-title {
            display: flex;
            align-items: center;
        }

        .header-title h1 {
            font-size: 24px;
            margin-left: 15px;
        }

        .header-meta {
            text-align: right;
            font-size: 14px;
        }

        .logo {
            width: 40px;
            height: 40px;
            background-color: white;
            border-radius: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--primary-color);
            font-weight: bold;
            font-size: 20px;
        }

        .toc {
            background-color: var(--card-bg);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 30px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
        }

        .toc h2 {
            margin-bottom: 15px;
            color: var(--primary-color);
            font-size: 18px;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 10px;
        }

        .toc ul {
            list-style-type: none;
        }

        .toc li {
            margin-bottom: 8px;
        }

        .toc a {
            color: var(--primary-color);
            text-decoration: none;
            display: block;
            padding: 5px 10px;
            border-radius: 4px;
            transition: background-color 0.2s;
        }

        .toc a:hover {
            background-color: var(--hover-color);
        }

        .executive-summary {
            background-color: var(--card-bg);
            border-radius: 8px;
            padding: 25px;
            margin-bottom: 30px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
        }

        .executive-summary h2 {
            color: var(--primary-color);
            margin-bottom: 20px;
            font-size: 20px;
        }

        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .summary-card {
            background-color: var(--hover-color);
            border-radius: 8px;
            padding: 15px;
            display: flex;
            flex-direction: column;
        }

        .summary-card h3 {
            font-size: 16px;
            margin-bottom: 10px;
            color: var(--text-color);
        }

        .summary-card .stat {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 5px;
            color: var(--primary-color);
        }

        .summary-card .description {
            font-size: 14px;
            color: var(--text-light);
            flex-grow: 1;
        }

        .recommendations {
            margin-top: 20px;
        }

        .recommendations h3 {
            font-size: 16px;
            margin-bottom: 10px;
            color: var(--text-color);
        }

        .recommendations ol {
            padding-left: 20px;
        }

        .recommendations li {
            margin-bottom: 8px;
        }

        .section {
            background-color: var(--card-bg);
            border-radius: 8px;
            padding: 25px;
            margin-bottom: 30px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
        }

        .section h2 {
            color: var(--primary-color);
            margin-bottom: 20px;
            font-size: 20px;
            display: flex;
            align-items: center;
            cursor: pointer;
        }

        .section h2::after {
            content: "▼";
            margin-left: 10px;
            font-size: 12px;
            transition: transform 0.3s;
        }

        .section.collapsed h2::after {
            transform: rotate(-90deg);
        }

        .section.collapsed .section-content {
            display: none;
        }

        .section-content {
            transition: all 0.3s;
        }

        .alert {
            background-color: #fdefe3;
            border-left: 4px solid var(--warning-color);
            padding: 10px 15px;
            margin: 15px 0;
            border-radius: 4px;
        }

        .alert-icon {
            color: var(--warning-color);
            margin-right: 10px;
        }

        .success {
            background-color: #e7f6e7;
            border-left: 4px solid var(--success-color);
            padding: 10px 15px;
            margin: 15px 0;
            border-radius: 4px;
        }

        .success-icon {
            color: var(--success-color);
            margin-right: 10px;
        }

        .info-box {
            background-color: #e5f0f8;
            border-left: 4px solid var(--info-color);
            padding: 10px 15px;
            margin: 15px 0;
            border-radius: 4px;
        }

        .info-icon {
            color: var(--info-color);
            margin-right: 10px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }

        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }

        th {
            background-color: var(--hover-color);
            font-weight: 600;
        }

        tr:hover {
            background-color: var(--hover-color);
        }

        .chart-container {
            margin: 20px 0;
            height: 250px;
            position: relative;
        }

        .bar-chart {
            display: flex;
            align-items: flex-end;
            height: 200px;
            gap: 10px;
        }

        .bar {
            flex-grow: 1;
            background-color: var(--primary-color);
            min-width: 40px;
            position: relative;
            border-radius: 4px 4px 0 0;
            transition: height 0.5s;
        }

        .bar-label {
            position: absolute;
            bottom: -25px;
            left: 0;
            right: 0;
            text-align: center;
            font-size: 12px;
        }

        .bar-value {
            position: absolute;
            top: -25px;
            left: 0;
            right: 0;
            text-align: center;
            font-size: 12px;
            font-weight: bold;
        }

        .pie-chart {
            width: 200px;
            height: 200px;
            border-radius: 50%;
            background: conic-gradient(var(--primary-color) 0% var(--primary-percentage), var(--warning-color) var(--primary-percentage) 100%);
            margin: 0 auto;
        }

        .pie-legend {
            display: flex;
            justify-content: center;
            margin-top: 20px;
            gap: 20px;
        }

        .legend-item {
            display: flex;
            align-items: center;
        }

        .legend-color {
            width: 15px;
            height: 15px;
            border-radius: 3px;
            margin-right: 8px;
        }

        .divider {
            height: 1px;
            background-color: var(--border-color);
            margin: 20px 0;
        }

        .role-card {
            background-color: var(--hover-color);
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 15px;
        }

        .role-card h3 {
            font-size: 16px;
            margin-bottom: 10px;
        }

        .role-card p {
            margin-bottom: 10px;
            font-size: 14px;
        }

        .role-card ul {
            list-style-type: none;
            margin-left: 15px;
        }

        .role-card li {
            margin-bottom: 5px;
            font-size: 14px;
        }

        .critical-role {
            border-left: 4px solid var(--warning-color);
        }

        footer {
            text-align: center;
            padding: 20px;
            margin-top: 30px;
            color: var(--text-light);
            font-size: 14px;
            border-top: 1px solid var(--border-color);
        }

        @media (max-width: 768px) {
            .container {
                padding: 15px;
            }
            
            header .container {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .header-meta {
                text-align: left;
                margin-top: 10px;
            }
            
            .summary-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <header>
        <div class="container">
            <div class="header-title">
                <div class="logo">E</div>
                <h1>Auditoría de Seguridad de Microsoft Entra ID</h1>
            </div>
            <div class="header-meta">
                <div>Fecha: $(Get-Date -Format "dd/MM/yyyy HH:mm")</div>
                <div>Generado por: PowerShell Security Audit</div>
            </div>
        </div>
    </header>
    
    <div class="container">
        <div class="toc">
            <h2>Tabla de Contenidos</h2>
            <ul>
                <li><a href="#resumen">Resumen Ejecutivo</a></li>
                <li><a href="#tenant">Información del Tenant</a></li>
                <li><a href="#usuarios">Estadísticas de Usuarios</a></li>
                <li><a href="#roles">Roles de Administrador</a></li>
                <li><a href="#acceso">Políticas de Acceso Condicional</a></li>
                <li><a href="#mfa">Configuración de MFA</a></li>
                <li><a href="#aplicaciones">Aplicaciones y Permisos</a></li>
                <li><a href="#seguridad">Configuración de Seguridad</a></li>
            </ul>
        </div>
"@

$htmlFooter = @"
        <footer>
            <p>Reporte de Auditoría de Seguridad de Microsoft Entra ID</p>
            <p>Generado el $(Get-Date -Format "dd/MM/yyyy") a las $(Get-Date -Format "HH:mm:ss")</p>
        </footer>
    </div>
    
    <script>
        // Función para colapsar/expandir secciones
        document.querySelectorAll('.section h2').forEach(header => {
            header.addEventListener('click', () => {
                const section = header.parentElement;
                section.classList.toggle('collapsed');
            });
        });
    </script>
</body>
</html>
"@

# Inicializar el contenido HTML
$htmlContent = ""

# Verificar módulos disponibles
$moduleFound = $false
$msolineAvailable = $false

# Comprobar si MSOnline está disponible
if (Get-Module -ListAvailable -Name MSOnline) {
    $msolineAvailable = $true
    Write-Log "Módulo MSOnline disponible" -Level "INFO"
    
    # Si solo está disponible MSOnline, lo usamos como principal
    if (-not (Get-Module -ListAvailable -Name AzureAD)) {
        Write-Log "Usando módulo MSOnline para la auditoría" -Level "INFO"
        Import-Module MSOnline
        $moduleFound = $true
        $usingAzureAD = $false
    }
}

# Comprobar si AzureAD está disponible
if (Get-Module -ListAvailable -Name AzureAD) {
    Write-Log "Usando módulo AzureAD para la auditoría" -Level "INFO"
    Import-Module AzureAD
    $moduleFound = $true
    $usingAzureAD = $true
    
    # Si también está disponible MSOnline, lo cargamos como complemento
    if ($msolineAvailable) {
        Write-Log "Cargando también MSOnline para funcionalidades adicionales" -Level "INFO"
        Import-Module MSOnline
    }
}

if (-not $moduleFound) {
    Write-Log "No se encontró ningún módulo compatible (AzureAD o MSOnline)" -Level "ERROR"
    Write-Log "Por favor, instale uno de estos módulos con: Install-Module AzureAD -Scope CurrentUser" -Level "WARNING"
    Write-Log "O bien: Install-Module MSOnline -Scope CurrentUser" -Level "WARNING"
    exit
}

# Intentar instalar el módulo que falta
if ($usingAzureAD -and -not $msolineAvailable) {
    try {
        Write-Log "Intentando instalar el módulo MSOnline como complemento..." -Level "INFO"
        Install-Module -Name MSOnline -Force -AllowClobber -Scope CurrentUser -ErrorAction SilentlyContinue
        Import-Module MSOnline -ErrorAction SilentlyContinue
        $msolineAvailable = $true
    }
    catch {
        Write-Log "No se pudo instalar el módulo MSOnline: $_" -Level "WARNING"
    }
}
elseif (-not $usingAzureAD) {
    try {
        Write-Log "Intentando instalar el módulo AzureAD como complemento..." -Level "INFO"
        Install-Module -Name AzureAD -Force -AllowClobber -Scope CurrentUser -ErrorAction SilentlyContinue
        Import-Module AzureAD -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "No se pudo instalar el módulo AzureAD: $_" -Level "WARNING"
    }
}
#endregion

#region 1. Autenticación
Write-Log "Iniciando auditoría de seguridad de Microsoft Entra ID..." -Level "INFO"
Write-Log "1. Autenticación" -Level "INFO"

try {
    # Conectar a Azure AD o MSOnline
    if ($usingAzureAD) {
        Connect-AzureAD -ErrorAction Stop
        Write-Log "Conexión a Azure AD establecida correctamente" -Level "INFO"
        
        # Obtener información del tenant
        $tenantDetails = Get-AzureADTenantDetail
        $tenantName = $tenantDetails.DisplayName
        $tenantId = $tenantDetails.ObjectId
        $verifiedDomains = (Get-AzureADDomain | Where-Object { $_.IsVerified -eq $true }).Count
        
        # Si también tenemos MSOnline disponible, conectamos para funcionalidades adicionales
        if ($msolineAvailable) {
            try {
                Connect-MsolService -ErrorAction SilentlyContinue
                Write-Log "Conexión a MSOnline establecida correctamente (para funcionalidades adicionales)" -Level "INFO"
            }
            catch {
                Write-Log "No se pudo conectar a MSOnline: $_" -Level "WARNING"
            }
        }
    }
    else {
        Connect-MsolService -ErrorAction Stop
        Write-Log "Conexión a MSOnline establecida correctamente" -Level "INFO"
        
        # Obtener información del tenant
        $tenantDetails = Get-MsolCompanyInformation
        $tenantName = $tenantDetails.DisplayName
        $tenantId = $tenantDetails.ObjectId
        $verifiedDomains = (Get-MsolDomain | Where-Object { $_.Status -eq "Verified" }).Count
    }
    
    # Sección de información del tenant
    $tenantSection = @"
    <div id="tenant" class="section">
        <h2>Información del Tenant</h2>
        <div class="section-content">
            <table>
                <tr>
                    <th>Propiedad</th>
                    <th>Valor</th>
                </tr>
                <tr>
                    <td>Nombre del Tenant</td>
                    <td>$tenantName</td>
                </tr>
                <tr>
                    <td>ID del Tenant</td>
                    <td>$tenantId</td>
                </tr>
                <tr>
                    <td>Dominios Verificados</td>
                    <td>$verifiedDomains</td>
                </tr>
                <tr>
                    <td>Fecha de Auditoría</td>
                    <td>$(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</td>
                </tr>
            </table>
        </div>
    </div>
"@

    $htmlContent += $tenantSection
}
catch {
    Write-Log "Error durante la autenticación: $_" -Level "ERROR"
    exit
}
#endregion

#region 2. Análisis de Usuarios y Administradores
Write-Log "2. Analizando usuarios y administradores..." -Level "INFO"

try {
    # Obtener todos los usuarios
    if ($usingAzureAD) {
        $users = Get-AzureADUser -All $true
        
        # Estadísticas básicas de usuarios
        $enabledUsers = $users | Where-Object { $_.AccountEnabled -eq $true }
        $disabledUsers = $users | Where-Object { $_.AccountEnabled -eq $false }
        $guestUsers = $users | Where-Object { $_.UserType -eq "Guest" }
        $memberUsers = $users | Where-Object { $_.UserType -eq "Member" }
    }
    else {
        $users = Get-MsolUser -All
        
        # Estadísticas básicas de usuarios
        $enabledUsers = $users | Where-Object { $_.BlockCredential -eq $false }
        $disabledUsers = $users | Where-Object { $_.BlockCredential -eq $true }
        $guestUsers = $users | Where-Object { $_.UserType -eq "Guest" }
        $memberUsers = $users | Where-Object { $_.UserType -eq "Member" }
    }
    
    # Calcular porcentajes para gráficos
    $enabledPercentage = [math]::Round(($enabledUsers.Count / $users.Count) * 100)
    $guestPercentage = [math]::Round(($guestUsers.Count / $users.Count) * 100)
    
    # Sección de estadísticas de usuarios
    $usuariosSection = @"
    <div id="usuarios" class="section">
        <h2>Estadísticas de Usuarios</h2>
        <div class="section-content">
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Total de Usuarios</h3>
                    <div class="stat">$($users.Count)</div>
                    <div class="description">Número total de cuentas de usuario en el directorio</div>
                </div>
                <div class="summary-card">
                    <h3>Usuarios Habilitados</h3>
                    <div class="stat">$($enabledUsers.Count)</div>
                    <div class="description">Cuentas activas que pueden iniciar sesión</div>
                </div>
                <div class="summary-card">
                    <h3>Usuarios Deshabilitados</h3>
                    <div class="stat">$($disabledUsers.Count)</div>
                    <div class="description">Cuentas bloqueadas que no pueden iniciar sesión</div>
                </div>
                <div class="summary-card">
                    <h3>Usuarios Invitados</h3>
                    <div class="stat">$($guestUsers.Count)</div>
                    <div class="description">Usuarios externos invitados al directorio</div>
                </div>
            </div>
            
            <div class="chart-container">
                <h3>Distribución de Usuarios</h3>
                <div style="display: flex; gap: 30px; justify-content: center;">
                    <div style="text-align: center;">
                        <h4>Estado de Cuentas</h4>
                        <div class="pie-chart" style="--primary-percentage: ${enabledPercentage}%;"></div>
                        <div class="pie-legend">
                            <div class="legend-item">
                                <div class="legend-color" style="background-color: var(--primary-color);"></div>
                                <span>Habilitados ($enabledPercentage%)</span>
                            </div>
                            <div class="legend-item">
                                <div class="legend-color" style="background-color: var(--warning-color);"></div>
                                <span>Deshabilitados ($(100 - $enabledPercentage)%)</span>
                            </div>
                        </div>
                    </div>
                    
                    <div style="text-align: center;">
                        <h4>Tipo de Usuarios</h4>
                        <div class="pie-chart" style="--primary-percentage: $(100 - $guestPercentage)%;"></div>
                        <div class="pie-legend">
                            <div class="legend-item">
                                <div class="legend-color" style="background-color: var(--primary-color);"></div>
                                <span>Miembros ($(100 - $guestPercentage)%)</span>
                            </div>
                            <div class="legend-item">
                                <div class="legend-color" style="background-color: var(--warning-color);"></div>
                                <span>Invitados ($guestPercentage%)</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
"@

    # Obtener roles de directorio y sus miembros
    if ($usingAzureAD) {
        $directoryRoles = Get-AzureADDirectoryRole
        
        $rolesSection = @"
            <div class="divider"></div>
            <h3>Roles de Administrador</h3>
            <p>Total de roles: $($directoryRoles.Count)</p>
"@
        
        # Roles críticos para destacar
        $criticalRoles = @(
            "Global Administrator", 
            "Privileged Role Administrator", 
            "User Administrator", 
            "Exchange Administrator", 
            "SharePoint Administrator", 
            "Conditional Access Administrator",
            "Security Administrator",
            "Application Administrator"
        )
        
        foreach ($role in $directoryRoles) {
            $roleMembers = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
            
            if ($roleMembers.Count -gt 0) {
                $isCritical = $criticalRoles -contains $role.DisplayName
                $criticalClass = if ($isCritical) { "critical-role" } else { "" }
                
                $rolesSection += @"
                <div class="role-card $criticalClass">
                    <h3>$($role.DisplayName)</h3>
                    <p>$($role.Description)</p>
                    <p>Miembros: $($roleMembers.Count)</p>
"@
                
                if ($roleMembers.Count -gt 0) {
                    $rolesSection += "<ul>"
                    foreach ($member in $roleMembers) {
                        if ($member.ObjectType -eq "User") {
                            $rolesSection += "<li>$($member.DisplayName) ($($member.UserPrincipalName))</li>"
                        }
                        else {
                            $rolesSection += "<li>[Grupo/App] $($member.DisplayName)</li>"
                        }
                    }
                    $rolesSection += "</ul>"
                }
                
                if ($isCritical) {
                    $rolesSection += @"
                    <div class="alert">
                        <span class="alert-icon">⚠️</span> Este es un rol crítico con altos privilegios
                    </div>
"@
                }
                
                # Verificar si hay demasiados administradores globales
                if ($role.DisplayName -eq "Global Administrator" -and $roleMembers.Count -gt 5) {
                    $rolesSection += @"
                    <div class="alert">
                        <span class="alert-icon">⚠️</span> Hay $($roleMembers.Count) Administradores Globales. Microsoft recomienda limitar este número.
                    </div>
"@
                }
                
                $rolesSection += "</div>"
            }
        }
    }
    else {
        $directoryRoles = Get-MsolRole
        
        $rolesSection = @"
            <div class="divider"></div>
            <h3>Roles de Administrador</h3>
            <p>Total de roles: $($directoryRoles.Count)</p>
"@
        
        # Roles críticos para destacar
        $criticalRoles = @(
            "Company Administrator", # Global Administrator en MSOnline
            "User Account Administrator", 
            "Exchange Service Administrator", 
            "SharePoint Service Administrator", 
            "Conditional Access Administrator",
            "Security Administrator",
            "Application Administrator"
        )
        
        foreach ($role in $directoryRoles) {
            $roleMembers = Get-MsolRoleMember -RoleObjectId $role.ObjectId
            
            if ($roleMembers.Count -gt 0) {
                $isCritical = $criticalRoles -contains $role.Name
                $criticalClass = if ($isCritical) { "critical-role" } else { "" }
                
                $rolesSection += @"
                <div class="role-card $criticalClass">
                    <h3>$($role.Name)</h3>
                    <p>$($role.Description)</p>
                    <p>Miembros: $($roleMembers.Count)</p>
"@
                
                if ($roleMembers.Count -gt 0) {
                    $rolesSection += "<ul>"
                    foreach ($member in $roleMembers) {
                        $rolesSection += "<li>$($member.DisplayName) ($($member.EmailAddress))</li>"
                    }
                    $rolesSection += "</ul>"
                }
                
                if ($isCritical) {
                    $rolesSection += @"
                    <div class="alert">
                        <span class="alert-icon">⚠️</span> Este es un rol crítico con altos privilegios
                    </div>
"@
                }
                
                # Verificar si hay demasiados administradores globales
                if ($role.Name -eq "Company Administrator" -and $roleMembers.Count -gt 5) {
                    $rolesSection += @"
                    <div class="alert">
                        <span class="alert-icon">⚠️</span> Hay $($roleMembers.Count) Administradores Globales. Microsoft recomienda limitar este número.
                    </div>
"@
                }
                
                $rolesSection += "</div>"
            }
        }
    }
    
    $usuariosSection += $rolesSection
    $usuariosSection += @"
        </div>
    </div>
"@
    
    $htmlContent += $usuariosSection
    Write-Log "Usuarios y administradores analizados correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al analizar usuarios y administradores: $_" -Level "ERROR"
    $htmlContent += @"
    <div id="usuarios" class="section">
        <h2>Estadísticas de Usuarios</h2>
        <div class="section-content">
            <div class="alert">
                <span class="alert-icon">⚠️</span> Error al obtener información: $_
            </div>
        </div>
    </div>
"@
}
#endregion

#region 3. Revisión de Políticas de Acceso Condicional
Write-Log "3. Revisando políticas de acceso condicional..." -Level "INFO"

try {
    # Obtener políticas de acceso condicional
    $conditionalAccessPolicies = $null
    
    if ($usingAzureAD) {
        try {
            # Intentar obtener políticas de acceso condicional (requiere módulo AzureAD Preview o permisos específicos)
            $conditionalAccessPolicies = Get-AzureADMSConditionalAccessPolicy -ErrorAction Stop
        }
        catch {
            Write-Log "No se pudieron obtener las políticas de acceso condicional: $_" -Level "WARNING"
        }
    }
    
    $accesoSection = @"
    <div id="acceso" class="section">
        <h2>Políticas de Acceso Condicional</h2>
        <div class="section-content">
"@
    
    if ($conditionalAccessPolicies) {
        if ($conditionalAccessPolicies.Count -eq 0) {
            $accesoSection += @"
            <div class="alert">
                <span class="alert-icon">⚠️</span> No se encontraron políticas de acceso condicional configuradas. La falta de políticas de acceso condicional puede representar un riesgo de seguridad.
            </div>
"@
        }
        else {
            $accesoSection += @"
            <div class="summary-card">
                <h3>Total de Políticas</h3>
                <div class="stat">$($conditionalAccessPolicies.Count)</div>
                <div class="description">Políticas de acceso condicional configuradas</div>
            </div>
            
            <table>
                <tr>
                    <th>Nombre</th>
                    <th>Estado</th>
                    <th>Requiere MFA</th>
                </tr>
"@
            
            foreach ($policy in $conditionalAccessPolicies) {
                $estado = if ($policy.State -eq 'enabled') { 'Habilitado' } else { 'Deshabilitado' }
                
                # Verificar si la política requiere MFA
                $requiresMfa = $false
                if ($policy.GrantControls.BuiltInControls -contains "mfa") {
                    $requiresMfa = $true
                    $mfaText = "Sí"
                }
                else {
                    $mfaText = "No"
                }
                
                $accesoSection += @"
                <tr>
                    <td>$($policy.DisplayName)</td>
                    <td>$estado</td>
                    <td>$mfaText</td>
                </tr>
"@
            }
            
            $accesoSection += "</table>"
            
            # Verificar si hay política de línea base para todos los usuarios
            $hasBaselinePolicy = $conditionalAccessPolicies | Where-Object { 
                $_.Conditions.Users.IncludeUsers -contains 'All' -and 
                $_.State -eq 'enabled' -and 
                $_.GrantControls.BuiltInControls -contains 'mfa'
            }
            
            if (-not $hasBaselinePolicy) {
                $accesoSection += @"
                <div class="alert">
                    <span class="alert-icon">⚠️</span> No se detectó una política de línea base que requiera MFA para todos los usuarios. Se recomienda implementar al menos una política que requiera MFA para todos los usuarios.
                </div>
"@
            }
            else {
                $accesoSection += @"
                <div class="success">
                    <span class="success-icon">✓</span> Se detectó una política de línea base que requiere MFA para todos los usuarios.
                </div>
"@
            }
        }
    }
    else {
        $accesoSection += @"
        <div class="info-box">
            <span class="info-icon">ℹ️</span> No se pudo obtener información sobre políticas de acceso condicional. Esto puede deberse a que no tiene los permisos necesarios o a que está utilizando el módulo MSOnline, que no admite esta funcionalidad.
        </div>
        <div class="alert">
            <span class="alert-icon">⚠️</span> Recomendación: Verifique manualmente las políticas de acceso condicional en el portal de Azure AD.
        </div>
"@
    }
    
    $accesoSection += @"
        </div>
    </div>
"@
    
    $htmlContent += $accesoSection
    Write-Log "Revisión de políticas de acceso condicional completada" -Level "INFO"
}
catch {
    Write-Log "Error al revisar políticas de acceso condicional: $_" -Level "ERROR"
    $htmlContent += @"
    <div id="acceso" class="section">
        <h2>Políticas de Acceso Condicional</h2>
        <div class="section-content">
            <div class="alert">
                <span class="alert-icon">⚠️</span> Error al obtener información: $_
            </div>
        </div>
    </div>
"@
}
#endregion

#region 4. Verificación de Configuraciones de MFA
Write-Log "4. Verificando configuraciones de MFA..." -Level "INFO"

try {
    $mfaSection = @"
    <div id="mfa" class="section">
        <h2>Configuración de MFA</h2>
        <div class="section-content">
"@
    
    # Verificar si los valores predeterminados de seguridad están habilitados
    $securityDefaultsEnabled = $false
    $securityDefaultsStatus = "No se pudo determinar"

    # Intentar determinar el estado de Security Defaults
    try {
        # Primero intentamos con MSOnline si está disponible
        if ($msolineAvailable) {
            try {
                # Verificar si hay usuarios con MFA forzado, lo que podría indicar Security Defaults
                $sampleUsers = Get-MsolUser -MaxResults 20 | Where-Object { 
                    $_.UserType -eq "Member" -and 
                    ($usingAzureAD -or $_.BlockCredential -eq $false)
                }
                
                $mfaEnforcedCount = 0
                foreach ($user in $sampleUsers) {
                    if ($user.StrongAuthenticationRequirements -and $user.StrongAuthenticationRequirements.Count -gt 0) {
                        $mfaEnforcedCount++
                    }
                }
                
                # Si más del 80% de los usuarios tienen MFA forzado, probablemente Security Defaults está habilitado
                if ($sampleUsers.Count -gt 0 -and ($mfaEnforcedCount / $sampleUsers.Count) -gt 0.8) {
                    $securityDefaultsEnabled = $true
                    $securityDefaultsStatus = "Probablemente habilitados"
                }
                else {
                    # Verificar si hay políticas de acceso condicional, lo que suele indicar que Security Defaults está deshabilitado
                    $hasConditionalAccessPolicies = $false
                    if ($conditionalAccessPolicies -and $conditionalAccessPolicies.Count -gt 0) {
                        $hasConditionalAccessPolicies = $true
                        $securityDefaultsEnabled = $false
                        $securityDefaultsStatus = "Probablemente deshabilitados (se detectaron políticas de acceso condicional)"
                    }
                    else {
                        $securityDefaultsStatus = "No se pudo determinar con certeza"
                    }
                }
            }
            catch {
                Write-Log "Error al verificar estado de MFA con MSOnline: $_" -Level "WARNING"
                $securityDefaultsStatus = "No se pudo determinar"
            }
        }
        else {
            $securityDefaultsStatus = "No se pudo determinar (MSOnline no disponible)"
        }
        
        $mfaSection += @"
        <div class="summary-card">
            <h3>Valores Predeterminados de Seguridad</h3>
            <div class="stat">$securityDefaultsStatus</div>
            <div class="description">Estado estimado de la configuración de seguridad predeterminada</div>
        </div>
"@
        
        $mfaSection += @"
        <div class="info-box">
            <span class="info-icon">ℹ️</span> Nota: No se pudo verificar directamente el estado de los valores predeterminados de seguridad porque el cmdlet requiere Microsoft Graph. El estado mostrado es una estimación basada en otras configuraciones.
        </div>
"@
        
        if ($securityDefaultsEnabled) {
            $mfaSection += @"
            <div class="success">
                <span class="success-icon">✓</span> BUENA PRÁCTICA: Los valores predeterminados de seguridad parecen estar habilitados, lo que requiere MFA para todos los usuarios.
            </div>
"@
        }
        elseif ($hasConditionalAccessPolicies) {
            $mfaSection += @"
            <div class="info-box">
                <span class="info-icon">ℹ️</span> Se detectaron políticas de acceso condicional, lo que sugiere que se está utilizando un enfoque personalizado para la seguridad en lugar de los valores predeterminados.
            </div>
"@
        }
        else {
            $mfaSection += @"
            <div class="alert">
                <span class="alert-icon">⚠️</span> ALERTA: No se pudo confirmar si los valores predeterminados de seguridad están habilitados. Verifique manualmente en el portal de Azure AD.
            </div>
"@
        }
    }
    catch {
        Write-Log "No se pudo estimar el estado de los valores predeterminados de seguridad: $_" -Level "WARNING"
        $mfaSection += @"
        <div class="info-box">
            <span class="info-icon">ℹ️</span> No se pudo estimar el estado de los valores predeterminados de seguridad: $_
        </div>
"@
    }
    
    # Analizar estado de MFA por usuario
    $mfaSection += @"
        <div class="divider"></div>
        <h3>Estado de MFA por Usuario</h3>
"@
    
    # Verificar si tenemos el módulo MSOnline disponible para verificar MFA
    if ($msolineAvailable) {
        try {
            # Asegurarse de que estamos conectados a MSOnline
            if (-not (Get-MsolCompanyInformation -ErrorAction SilentlyContinue)) {
                Write-Log "Conectando a MSOnline para verificar MFA..." -Level "INFO"
                Connect-MsolService -ErrorAction Stop
            }
            
            # Inicializar contadores y listas
            $totalChecked = 0
            $usersWithoutMfa = 0
            $adminsWithoutMfa = 0
            $usersWithoutMfaList = @()
            
            # Implementar procesamiento por lotes para evitar errores de pipeline
            Write-Log "Obteniendo todos los usuarios para verificar MFA (procesamiento por lotes)..." -Level "INFO"
            
            # Primero obtenemos solo los IDs y UPNs para minimizar la carga de memoria
            $allUserIds = @()
            try {
                # Obtener solo usuarios miembros activos
                Write-Log "Obteniendo lista de usuarios miembros activos..." -Level "INFO"
                $allUserIds = Get-MsolUser -All -EnabledFilter EnabledOnly | 
                    Where-Object { $_.UserType -eq "Member" } | 
                    Select-Object -Property ObjectId, UserPrincipalName
                
                Write-Log "Se encontraron $($allUserIds.Count) usuarios miembros activos" -Level "INFO"
            }
            catch {
                Write-Log "Error al obtener lista completa de usuarios: $_" -Level "WARNING"
                # Plan B: Intentar con un enfoque más limitado
                try {
                    Write-Log "Intentando obtener usuarios con enfoque alternativo..." -Level "INFO"
                    $allUserIds = Get-MsolUser -MaxResults 1000 | 
                        Where-Object { $_.UserType -eq "Member" -and (-not $_.BlockCredential) } | 
                        Select-Object -Property ObjectId, UserPrincipalName
                    
                    Write-Log "Se encontraron $($allUserIds.Count) usuarios con enfoque alternativo" -Level "INFO"
                }
                catch {
                    Write-Log "Error al obtener usuarios con enfoque alternativo: $_" -Level "ERROR"
                    throw "No se pudieron obtener usuarios para verificar MFA"
                }
            }
            
            # Tamaño del lote - procesar usuarios en grupos pequeños
            $batchSize = 50
            $totalBatches = [Math]::Ceiling($allUserIds.Count / $batchSize)
            
            Write-Log "Procesando $($allUserIds.Count) usuarios en $totalBatches lotes de $batchSize usuarios cada uno..." -Level "INFO"
            
            # Procesar usuarios por lotes
            for ($batchIndex = 0; $batchIndex -lt $totalBatches; $batchIndex++) {
                $startIndex = $batchIndex * $batchSize
                $endIndex = [Math]::Min(($batchIndex + 1) * $batchSize - 1, $allUserIds.Count - 1)
                $currentBatchSize = $endIndex - $startIndex + 1
                
                Write-Log "Procesando lote $($batchIndex + 1) de $totalBatches ($currentBatchSize usuarios)..." -Level "INFO"
                
                # Obtener el lote actual de usuarios
                $currentBatch = $allUserIds[$startIndex..$endIndex]
                
                # Procesar cada usuario en el lote actual
                foreach ($userBasic in $currentBatch) {
                    try {
                        # Obtener detalles completos del usuario uno por uno para evitar sobrecarga
                        $user = Get-MsolUser -ObjectId $userBasic.ObjectId -ErrorAction Stop
                        $totalChecked++
                        
                        # Verificar estado de MFA
                        $mfaStatus = $user.StrongAuthenticationRequirements
                        $mfaEnabled = ($mfaStatus -ne $null -and $mfaStatus.Count -gt 0) -or 
                                      ($securityDefaultsEnabled -eq $true)
                        
                        if (-not $mfaEnabled) {
                            $usersWithoutMfa++
                            
                            # Verificar si es administrador - con manejo de errores mejorado
                            $isAdmin = $false
                            try {
                                # Usar Get-MsolUserRole con el parámetro UserPrincipalName para evitar errores
                                $userRoles = Get-MsolUserRole -UserPrincipalName $user.UserPrincipalName -ErrorAction Stop
                                if ($userRoles -and $userRoles.Count -gt 0) {
                                    $isAdmin = $true
                                    $adminsWithoutMfa++
                                }
                            }
                            catch {
                                Write-Log "Error al verificar roles para $($user.UserPrincipalName): $_" -Level "WARNING"
                                # Intentar un enfoque alternativo para verificar si es admin
                                try {
                                    $userRoles = Get-MsolUserRole -ObjectId $user.ObjectId -ErrorAction SilentlyContinue
                                    if ($userRoles -and $userRoles.Count -gt 0) {
                                        $isAdmin = $true
                                        $adminsWithoutMfa++
                                    }
                                }
                                catch {
                                    Write-Log "Error al verificar roles por ObjectId para $($user.UserPrincipalName): $_" -Level "WARNING"
                                }
                            }
                            
                            # Solo guardar los primeros 100 usuarios sin MFA para no sobrecargar el informe
                            if ($usersWithoutMfaList.Count -lt 100) {
                                $usersWithoutMfaList += [PSCustomObject]@{
                                    DisplayName = $user.DisplayName
                                    UserPrincipalName = $user.UserPrincipalName
                                    IsAdmin = $isAdmin
                                }
                            }
                        }
                        
                        # Mostrar progreso cada 100 usuarios
                        if ($totalChecked % 100 -eq 0) {
                            Write-Log "Progreso: $totalChecked usuarios procesados..." -Level "INFO"
                        }
                    }
                    catch {
                        Write-Log "Error al procesar usuario $($userBasic.UserPrincipalName): $_" -Level "WARNING"
                        # Continuar con el siguiente usuario
                    }
                }
                
                # Pequeña pausa entre lotes para no sobrecargar la API
                if ($batchIndex -lt $totalBatches - 1) {
                    Start-Sleep -Milliseconds 500
                }
            }
            
            Write-Log "Análisis de MFA completado. Total procesado: $totalChecked usuarios" -Level "INFO"
            
            # Añadir estadísticas de MFA
            if ($totalChecked -gt 0) {
                $mfaPercentage = [math]::Round((($totalChecked - $usersWithoutMfa) / $totalChecked) * 100)
                
                $mfaSection += @"
                <div class="summary-grid">
                    <div class="summary-card">
                        <h3>Usuarios Verificados</h3>
                        <div class="stat">$totalChecked</div>
                        <div class="description">Número total de usuarios analizados</div>
                    </div>
                    <div class="summary-card">
                        <h3>Usuarios sin MFA</h3>
                        <div class="stat">$usersWithoutMfa</div>
                        <div class="description">Usuarios que no tienen MFA configurado</div>
                    </div>
                    <div class="summary-card">
                        <h3>Administradores sin MFA</h3>
                        <div class="stat">$adminsWithoutMfa</div>
                        <div class="description">Administradores sin MFA</div>
                    </div>
                    <div class="summary-card">
                        <h3>Adopción de MFA</h3>
                        <div class="stat">$mfaPercentage%</div>
                        <div class="description">Porcentaje de usuarios con MFA</div>
                    </div>
                </div>
                
                <div class="chart-container">
                    <h3>Estado de MFA</h3>
                    <div class="pie-chart" style="--primary-percentage: ${mfaPercentage}%;">
                    </div>
                    <div class="pie-legend">
                        <div class="legend-item">
                            <div class="legend-color" style="background-color: var(--primary-color);"></div>
                            <span>Con MFA ($mfaPercentage%)</span>
                        </div>
                        <div class="legend-item">
                            <div class="legend-color" style="background-color: var(--warning-color);"></div>
                            <span>Sin MFA ($(100 - $mfaPercentage)%)</span>
                        </div>
                    </div>
                </div>
"@
                
                if ($adminsWithoutMfa -gt 0) {
                    $mfaSection += @"
                <div class="alert">
                    <span class="alert-icon">⚠️</span> ALERTA CRÍTICA: Hay $adminsWithoutMfa administradores sin MFA configurado. Esto representa un riesgo de seguridad significativo.
                </div>
"@
                }
                
                if ($usersWithoutMfa / $totalChecked -gt 0.5) {
                    $mfaSection += @"
                <div class="alert">
                    <span class="alert-icon">⚠️</span> ALERTA: Más del 50% de los usuarios no tienen MFA configurado.
                </div>
"@
                }
                
                # Mostrar lista de usuarios sin MFA (limitado a 100 para no sobrecargar el informe)
                if ($usersWithoutMfaList.Count -gt 0) {
                    $mfaSection += @"
                <div class="divider"></div>
                <h3>Usuarios sin MFA configurado</h3>
"@

                    if ($usersWithoutMfa > 100) {
                        $mfaSection += @"
                <div class="info-box">
                    <span class="info-icon">ℹ️</span> Se muestran solo los primeros 100 usuarios sin MFA de un total de $usersWithoutMfa.
                </div>
"@
                    }

                    $mfaSection += @"
                <table>
                    <tr>
                        <th>Nombre</th>
                        <th>Correo</th>
                        <th>Administrador</th>
                    </tr>
"@
                    
                    foreach ($user in $usersWithoutMfaList) {
                        $adminIcon = if ($user.IsAdmin) { "⚠️ Sí" } else { "No" }
                        $rowClass = if ($user.IsAdmin) { ' class="alert"' } else { '' }
                        
                        $mfaSection += @"
                    <tr$rowClass>
                        <td>$($user.DisplayName)</td>
                        <td>$($user.UserPrincipalName)</td>
                        <td>$adminIcon</td>
                    </tr>
"@
                    }
                    
                    $mfaSection += "</table>"
                }
            }
        }
        catch {
            Write-Log "Error al verificar el estado de MFA: $_" -Level "ERROR"
            $mfaSection += @"
            <div class="alert">
                <span class="alert-icon">⚠️</span> Error al verificar el estado de MFA: $_
            </div>
"@
        }
    }
    else {
        $mfaSection += @"
        <div class="info-box">
            <span class="info-icon">ℹ️</span> No se puede verificar el estado de MFA de los usuarios porque el módulo MSOnline no está disponible o no se pudo cargar.
        </div>
        <div class="alert">
            <span class="alert-icon">⚠️</span> Recomendación: Instale el módulo MSOnline con el comando <code>Install-Module MSOnline</code> para habilitar la verificación de MFA.
        </div>
"@
    }
    
    $mfaSection += @"
        </div>
    </div>
"@
    
    $htmlContent += $mfaSection
    Write-Log "Configuraciones de MFA verificadas correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al verificar configuraciones de MFA: $_" -Level "ERROR"
    $htmlContent += @"
    <div id="mfa" class="section">
        <h2>Configuración de MFA</h2>
        <div class="section-content">
            <div class="alert">
                <span class="alert-icon">⚠️</span> Error al obtener información de MFA: $_
            </div>
        </div>
    </div>
"@
}
#endregion

#region 5. Análisis de Aplicaciones y Permisos
Write-Log "5. Analizando aplicaciones y permisos..." -Level "INFO"

try {
    $aplicacionesSection = @"
    <div id="aplicaciones" class="section">
        <h2>Aplicaciones y Permisos</h2>
        <div class="section-content">
"@
    
    # Obtener aplicaciones registradas
    if ($usingAzureAD) {
        try {
            $applications = Get-AzureADApplication -All $true -ErrorAction Stop
            
            if ($applications.Count -eq 0) {
                $aplicacionesSection += @"
                <div class="info-box">
                    <span class="info-icon">ℹ️</span> No se encontraron aplicaciones registradas en Azure AD.
                </div>
"@
            }
            else {
                $aplicacionesSection += @"
                <div class="summary-card">
                    <h3>Aplicaciones Registradas</h3>
                    <div class="stat">$($applications.Count)</div>
                    <div class="description">Total de aplicaciones registradas en Azure AD</div>
                </div>
                
                <div class="divider"></div>
                <h3>Aplicaciones Registradas</h3>
                <table>
                    <tr>
                        <th>Nombre</th>
                        <th>ID de Aplicación</th>
                        <th>Fecha de Creación</th>
                    </tr>
"@
                
                # Mostrar solo las primeras 20 aplicaciones para evitar que el reporte sea demasiado grande
                foreach ($app in $applications | Select-Object -First 20) {
                    $creationDate = if ($app.CreatedDateTime) { $app.CreatedDateTime.ToString("dd/MM/yyyy") } else { "Desconocida" }
                    
                    $aplicacionesSection += @"
                    <tr>
                        <td>$($app.DisplayName)</td>
                        <td>$($app.AppId)</td>
                        <td>$creationDate</td>
                    </tr>
"@
                }
                
                $aplicacionesSection += "</table>"
                
                if ($applications.Count > 20) {
                    $aplicacionesSection += @"
                    <div class="info-box">
                        <span class="info-icon">ℹ️</span> Se muestran solo las primeras 20 aplicaciones de un total de $($applications.Count).
                    </div>
"@
                }
                
                # Intentar obtener información sobre secretos y certificados
                try {
                    $appsWithSecrets = 0
                    $appsWithCerts = 0
                    $appsWithExpiringCredentials = 0
                    
                    foreach ($app in $applications) {
                        $appCredentials = Get-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -ErrorAction SilentlyContinue
                        $appCertificates = Get-AzureADApplicationKeyCredential -ObjectId $app.ObjectId -ErrorAction SilentlyContinue
                        
                        if ($appCredentials -and $appCredentials.Count -gt 0) {
                            $appsWithSecrets++
                            
                            # Verificar si hay secretos que expiran pronto
                            foreach ($cred in $appCredentials) {
                                $daysUntilExpiry = (New-TimeSpan -Start (Get-Date) -End $cred.EndDate).Days
                                if ($daysUntilExpiry -lt 30) {
                                    $appsWithExpiringCredentials++
                                    break
                                }
                            }
                        }
                        
                        if ($appCertificates -and $appCertificates.Count -gt 0) {
                            $appsWithCerts++
                            
                            # Verificar si hay certificados que expiran pronto
                            foreach ($cert in $appCertificates) {
                                $daysUntilExpiry = (New-TimeSpan -Start (Get-Date) -End $cert.EndDate).Days
                                if ($daysUntilExpiry -lt 30) {
                                    $appsWithExpiringCredentials++
                                    break
                                }
                            }
                        }
                    }
                    
                    $aplicacionesSection += @"
                    <div class="divider"></div>
                    <h3>Resumen de Credenciales</h3>
                    <div class="summary-grid">
                        <div class="summary-card">
                            <h3>Aplicaciones con Secretos</h3>
                            <div class="stat">$appsWithSecrets</div>
                            <div class="description">Aplicaciones que utilizan secretos para autenticación</div>
                        </div>
                        <div class="summary-card">
                            <h3>Aplicaciones con Certificados</h3>
                            <div class="stat">$appsWithCerts</div>
                            <div class="description">Aplicaciones que utilizan certificados para autenticación</div>
                        </div>
                        <div class="summary-card">
                            <h3>Credenciales por Expirar</h3>
                            <div class="stat">$appsWithExpiringCredentials</div>
                            <div class="description">Aplicaciones con credenciales que expiran en menos de 30 días</div>
                        </div>
                    </div>
"@
                    
                    if ($appsWithExpiringCredentials -gt 0) {
                        $aplicacionesSection += @"
                        <div class="alert">
                            <span class="alert-icon">⚠️</span> ALERTA: Hay $appsWithExpiringCredentials aplicaciones con credenciales que expirarán en menos de 30 días. Revise y renueve estas credenciales para evitar interrupciones.
                        </div>
"@
                    }
                }
                catch {
                    Write-Log "Error al analizar credenciales de aplicaciones: $_" -Level "WARNING"
                    $aplicacionesSection += @"
                    <div class="info-box">
                        <span class="info-icon">ℹ️</span> No se pudo obtener información detallada sobre credenciales de aplicaciones: $_
                    </div>
"@
                }
            }
            
            # Obtener aplicaciones empresariales (service principals)
            try {
                $servicePrincipals = Get-AzureADServicePrincipal -All $true -ErrorAction Stop | 
                    Where-Object { $_.ServicePrincipalType -eq "Application" }
                
                $aplicacionesSection += @"
                <div class="divider"></div>
                <h3>Aplicaciones Empresariales</h3>
                <div class="summary-card">
                    <h3>Total de Aplicaciones Empresariales</h3>
                    <div class="stat">$($servicePrincipals.Count)</div>
                    <div class="description">Service Principals de tipo Aplicación</div>
                </div>
"@
                
                # Mostrar algunas aplicaciones empresariales importantes
                $importantSps = $servicePrincipals | Where-Object { 
                    $_.DisplayName -like "*Microsoft*" -or 
                    $_.DisplayName -like "*Azure*" -or 
                    $_.DisplayName -like "*Office*" -or 
                    $_.DisplayName -like "*Graph*" 
                } | Select-Object -First 10
                
                if ($importantSps.Count -gt 0) {
                    $aplicacionesSection += @"
                <h4>Aplicaciones Empresariales Destacadas</h4>
                <table>
                    <tr>
                        <th>Nombre</th>
                        <th>ID de Aplicación</th>
                    </tr>
"@
                    
                    foreach ($sp in $importantSps) {
                        $aplicacionesSection += @"
                    <tr>
                        <td>$($sp.DisplayName)</td>
                        <td>$($sp.AppId)</td>
                    </tr>
"@
                    }
                    
                    $aplicacionesSection += "</table>"
                }
            }
            catch {
                Write-Log "Error al obtener aplicaciones empresariales: $_" -Level "WARNING"
                $aplicacionesSection += @"
                <div class="info-box">
                    <span class="info-icon">ℹ️</span> No se pudo obtener información sobre aplicaciones empresariales: $_
                </div>
"@
            }
        }
        catch {
            Write-Log "Error al obtener aplicaciones registradas: $_" -Level "WARNING"
            $aplicacionesSection += @"
            <div class="alert">
                <span class="alert-icon">⚠️</span> Error al obtener aplicaciones registradas: $_
            </div>
"@
        }
    }
    else {
        # Usando MSOnline - capacidades limitadas para aplicaciones
        $aplicacionesSection += @"
        <div class="info-box">
            <span class="info-icon">ℹ️</span> No se puede obtener información detallada sobre aplicaciones registradas con el módulo MSOnline. Para un análisis completo de aplicaciones, utilice el módulo AzureAD.
        </div>
        
        <div class="alert">
            <span class="alert-icon">⚠️</span> Recomendación: Para analizar aplicaciones, instale el módulo AzureAD con el comando <code>Install-Module AzureAD</code> y ejecute nuevamente el script.
        </div>
"@
    }
    
    $aplicacionesSection += @"
        </div>
    </div>
"@
    
    $htmlContent += $aplicacionesSection
    Write-Log "Aplicaciones y permisos analizados correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al analizar aplicaciones y permisos: $_" -Level "ERROR"
    $htmlContent += @"
    <div id="aplicaciones" class="section">
        <h2>Aplicaciones y Permisos</h2>
        <div class="section-content">
            <div class="alert">
                <span class="alert-icon">⚠️</span> Error al obtener información: $_
            </div>
        </div>
    </div>
"@
}
#endregion

#region 6. Análisis de Configuración de Seguridad
Write-Log "6. Analizando configuración de seguridad..." -Level "INFO"

try {
    $seguridadSection = @"
    <div id="seguridad" class="section">
        <h2>Configuración de Seguridad</h2>
        <div class="section-content">
"@
    
    # Referencia al estado de Security Defaults estimado anteriormente
    $seguridadSection += @"
        <div class="summary-card">
            <h3>Valores Predeterminados de Seguridad</h3>
            <div class="stat">$securityDefaultsStatus</div>
            <div class="description">Estado estimado de la configuración de seguridad predeterminada</div>
        </div>
"@
    
    # Verificar configuración de contraseñas usando MSOnline si está disponible
    if ($msolineAvailable) {
        try {
            # Obtener el dominio inicial
            $initialDomain = $null
            if ($usingAzureAD) {
                $domains = Get-AzureADDomain
                $initialDomain = ($domains | Where-Object { $_.IsInitial -eq $true }).Name
            }
            else {
                $domains = Get-MsolDomain
                $initialDomain = ($domains | Where-Object { $_.IsInitial -eq $true }).Name
            }
            
            if ($initialDomain) {
                $passwordPolicy = Get-MsolPasswordPolicy -Domain $initialDomain -ErrorAction Stop
                
                $seguridadSection += @"
                <div class="divider"></div>
                <h3>Política de Contraseñas</h3>
                <table>
                    <tr>
                        <th>Configuración</th>
                        <th>Valor</th>
                    </tr>
                    <tr>
                        <td>Validez de contraseña</td>
                        <td>$($passwordPolicy.ValidityPeriod) $($passwordPolicy.ValidityPeriodType)</td>
                    </tr>
                    <tr>
                        <td>Notificación previa a expiración</td>
                        <td>$($passwordPolicy.NotificationDays) días</td>
                    </tr>
"@
                
                # Obtener configuración de complejidad de contraseñas
                try {
                    $strongPasswordRequired = $passwordPolicy.StrongPasswordRequired
                    
                    $seguridadSection += @"
                    <tr>
                        <td>Contraseñas seguras requeridas</td>
                        <td>$strongPasswordRequired</td>
                    </tr>
"@
                }
                catch {
                    $seguridadSection += @"
                    <tr>
                        <td>Contraseñas seguras requeridas</td>
                        <td>Error al obtener información</td>
                    </tr>
"@
                }
                
                $seguridadSection += "</table>"
                
                if ($passwordPolicy.ValidityPeriod -eq 0) {
                    $seguridadSection += @"
                <div class="success">
                    <span class="success-icon">✓</span> BUENA PRÁCTICA: Las contraseñas no expiran (política moderna de contraseñas)
                </div>
"@
                }
                elseif ($passwordPolicy.ValidityPeriod -gt 90) {
                    $seguridadSection += @"
                <div class="alert">
                    <span class="alert-icon">⚠️</span> ALERTA: El período de validez de contraseñas es superior a 90 días
                </div>
"@
                }
                
                if (-not $strongPasswordRequired) {
                    $seguridadSection += @"
                <div class="alert">
                    <span class="alert-icon">⚠️</span> ALERTA: No se requieren contraseñas seguras
                </div>
"@
                }
            }
            else {
                $seguridadSection += @"
                <div class="info-box">
                    <span class="info-icon">ℹ️</span> No se pudo determinar el dominio inicial para verificar la política de contraseñas.
                </div>
"@
            }
        }
        catch {
            Write-Log "Error al obtener política de contraseñas: $_" -Level "WARNING"
            $seguridadSection += @"
            <div class="info-box">
                <span class="info-icon">ℹ️</span> Error al obtener política de contraseñas: $_
            </div>
"@
        }
    }
    else {
        $seguridadSection += @"
        <div class="info-box">
            <span class="info-icon">ℹ️</span> La información detallada sobre políticas de contraseñas no está disponible porque el módulo MSOnline no está disponible. Para obtener esta información, instale el módulo MSOnline.
        </div>
"@
    }
    
    # Añadir información sobre mejores prácticas de seguridad
    $seguridadSection += @"
    <div class="divider"></div>
    <h3>Recomendaciones de Seguridad</h3>
    <ul>
        <li>Habilitar MFA para todos los usuarios, especialmente para cuentas de administrador</li>
        <li>Implementar políticas de acceso condicional para proteger recursos críticos</li>
        <li>Revisar regularmente los permisos de aplicaciones y roles de administrador</li>
        <li>Monitorear y responder a alertas de seguridad</li>
        <li>Implementar políticas de contraseñas seguras</li>
        <li>Realizar auditorías de seguridad periódicas</li>
    </ul>
"@
    
    $seguridadSection += @"
        </div>
    </div>
"@
    
    $htmlContent += $seguridadSection
    Write-Log "Configuración de seguridad analizada correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al analizar configuración de seguridad: $_" -Level "ERROR"
    $htmlContent += @"
    <div id="seguridad" class="section">
        <h2>Configuración de Seguridad</h2>
        <div class="section-content">
            <div class="alert">
                <span class="alert-icon">⚠️</span> Error al obtener información: $_
            </div>
        </div>
    </div>
"@
}
#endregion

#region 7. Resumen Ejecutivo
Write-Log "7. Generando resumen ejecutivo..." -Level "INFO"

try {
    # Calcular estadísticas para el resumen
    $totalUsers = $users.Count
    $enabledUsersCount = $enabledUsers.Count
    $totalRoles = $directoryRoles.Count
    $policiesCount = if ($conditionalAccessPolicies) { $conditionalAccessPolicies.Count } else { "No disponible" }
    $securityDefaultsEnabled = if ($securityDefaultsEnabled) { "Sí" } else { "No" }
    $usersWithMfaPercentage = if ($totalChecked -gt 0) { [math]::Round((($totalChecked - $usersWithoutMfa) / $totalChecked) * 100) } else { 0 }
    $applicationsCount = if ($applications) { $applications.Count } else { "No disponible" }
    
    # Crear resumen ejecutivo
    $resumenSection = @"
    <div id="resumen" class="section executive-summary">
        <h2>Resumen Ejecutivo</h2>
        <div class="section-content">
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Usuarios</h3>
                    <div class="stat">$totalUsers</div>
                    <div class="description">Total de usuarios en el directorio</div>
                </div>
                <div class="summary-card">
                    <h3>Roles de Administrador</h3>
                    <div class="stat">$totalRoles</div>
                    <div class="description">Roles de administrador configurados</div>
                </div>
                <div class="summary-card">
                    <h3>Políticas de Acceso</h3>
                    <div class="stat">$policiesCount</div>
                    <div class="description">Políticas de acceso condicional</div>
                </div>
                <div class="summary-card">
                    <h3>Adopción de MFA</h3>
                    <div class="stat">$usersWithMfaPercentage%</div>
                    <div class="description">Usuarios con MFA configurado</div>
                </div>
            </div>
            
            <div class="recommendations">
                <h3>Recomendaciones Principales</h3>
                <ol>
                    <li>Implementar MFA para todos los usuarios, especialmente para cuentas de administrador.</li>
                    <li>Revisar y configurar políticas de acceso condicional para proteger recursos críticos.</li>
                    <li>Revisar permisos de aplicaciones, especialmente aquellas con permisos elevados.</li>
                    <li>Habilitar valores predeterminados de seguridad si no hay políticas de acceso condicional configuradas.</li>
                    <li>Revisar regularmente las asignaciones de roles administrativos para asegurar el principio de mínimo privilegio.</li>
                </ol>
            </div>
            
            <div class="divider"></div>
            
            <div class="chart-container">
                <h3>Resumen de Seguridad</h3>
                <div style="display: flex; gap: 30px; justify-content: center;">
                    <div style="text-align: center;">
                        <h4>Adopción de MFA</h4>
                        <div class="pie-chart" style="--primary-percentage: ${usersWithMfaPercentage}%;"></div>
                        <div class="pie-legend">
                            <div class="legend-item">
                                <div class="legend-color" style="background-color: var(--primary-color);"></div>
                                <span>Con MFA ($usersWithMfaPercentage%)</span>
                            </div>
                            <div class="legend-item">
                                <div class="legend-color" style="background-color: var(--warning-color);"></div>
                                <span>Sin MFA ($(100 - $usersWithMfaPercentage)%)</span>
                            </div>
                        </div>
                    </div>
                    
                    <div style="text-align: center;">
                        <h4>Estado de Usuarios</h4>
                        <div class="pie-chart" style="--primary-percentage: ${enabledPercentage}%;"></div>
                        <div class="pie-legend">
                            <div class="legend-item">
                                <div class="legend-color" style="background-color: var(--primary-color);"></div>
                                <span>Habilitados ($enabledPercentage%)</span>
                            </div>
                            <div class="legend-item">
                                <div class="legend-color" style="background-color: var(--warning-color);"></div>
                                <span>Deshabilitados ($(100 - $enabledPercentage)%)</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
"@
    
    # Insertar el resumen ejecutivo al principio del contenido HTML
    $htmlContent = $resumenSection + $htmlContent
    
    Write-Log "Resumen ejecutivo generado correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al generar resumen ejecutivo: $_" -Level "ERROR"
}
#endregion

# Generar el archivo HTML completo
$fullHtml = $htmlHeader + $htmlContent + $htmlFooter

# Guardar el archivo HTML con codificación UTF-8
[System.IO.File]::WriteAllText($reportFile, $fullHtml, [System.Text.Encoding]::UTF8)

# Desconectar sesiones
if ($usingAzureAD) {
    Disconnect-AzureAD -ErrorAction SilentlyContinue
}
if ($msolineAvailable) {
    # No hay un cmdlet específico para desconectar MSOnline, pero podemos limpiar la sesión
    [Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState() -ErrorAction SilentlyContinue
}

Write-Log "Reporte HTML generado correctamente en: $reportFile" -Level "INFO"
Write-Log "Log de la auditoría guardado en: $logFile" -Level "INFO"

# Mostrar ubicación del reporte
Write-Host "`nLa auditoría de seguridad de Microsoft Entra ID ha finalizado correctamente." -ForegroundColor Green
Write-Host "El reporte HTML se encuentra en: $reportFile" -ForegroundColor Cyan
Write-Host "El log de la auditoría se encuentra en: $logFile" -ForegroundColor Cyan

# Abrir el reporte HTML automáticamente
try {
    Start-Process $reportFile
}
catch {
    Write-Host "No se pudo abrir el reporte automáticamente. Por favor, ábralo manualmente." -ForegroundColor Yellow
}
