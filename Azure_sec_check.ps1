<#
.SYNOPSIS
    Script de auditoría de seguridad para Microsoft Entra ID (Azure AD) sin usar Microsoft Graph.
.DESCRIPTION
    Este script realiza una auditoría de seguridad básica en Microsoft Entra ID utilizando
    los módulos MSOnline o AzureAD, sin requerir acceso a Microsoft Graph.
.NOTES
    Requisitos:
    - Módulos MSOnline o AzureAD
    - Permisos básicos de lectura en Azure AD
    Autor: v0
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

$reportFile = "$reportFolder\EntraIDSecurityAuditReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$logFile = "$reportFolder\EntraIDSecurityAuditLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Función para escribir en el reporte
function Write-Report {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Section,
        
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $separator = "=" * 80
    $sectionHeader = "`n$separator`n$Section`n$separator`n"
    
    Add-Content -Path $reportFile -Value $sectionHeader
    Add-Content -Path $reportFile -Value $Content
}

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

# Verificar módulos disponibles
$moduleFound = $false

# Comprobar si AzureAD está disponible
if (Get-Module -ListAvailable -Name AzureAD) {
    Write-Log "Usando módulo AzureAD para la auditoría" -Level "INFO"
    Import-Module AzureAD
    $moduleFound = $true
    $usingAzureAD = $true
}
# Comprobar si MSOnline está disponible
elseif (Get-Module -ListAvailable -Name MSOnline) {
    Write-Log "Usando módulo MSOnline para la auditoría" -Level "INFO"
    Import-Module MSOnline
    $moduleFound = $true
    $usingAzureAD = $false
}

if (-not $moduleFound) {
    Write-Log "No se encontró ningún módulo compatible (AzureAD o MSOnline)" -Level "ERROR"
    Write-Log "Por favor, instale uno de estos módulos con: Install-Module AzureAD -Scope CurrentUser" -Level "WARNING"
    Write-Log "O bien: Install-Module MSOnline -Scope CurrentUser" -Level "WARNING"
    exit
}

# Intentar instalar el módulo que falta
if ($usingAzureAD -and -not (Get-Module -ListAvailable -Name MSOnline)) {
    try {
        Write-Log "Intentando instalar el módulo MSOnline como respaldo..." -Level "INFO"
        Install-Module -Name MSOnline -Force -AllowClobber -Scope CurrentUser -ErrorAction SilentlyContinue
        Import-Module MSOnline -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "No se pudo instalar el módulo MSOnline: $_" -Level "WARNING"
    }
}
elseif (-not $usingAzureAD -and -not (Get-Module -ListAvailable -Name AzureAD)) {
    try {
        Write-Log "Intentando instalar el módulo AzureAD como respaldo..." -Level "INFO"
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
        $tenantInfo = @"
Fecha de auditoría: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Tenant ID: $($tenantDetails.ObjectId)
Nombre del tenant: $($tenantDetails.DisplayName)
Dominios verificados: $((Get-AzureADDomain | Where-Object { $_.IsVerified -eq $true }).Count)
"@
    }
    else {
        Connect-MsolService -ErrorAction Stop
        Write-Log "Conexión a MSOnline establecida correctamente" -Level "INFO"
        
        # Obtener información del tenant
        $tenantDetails = Get-MsolCompanyInformation
        $tenantInfo = @"
Fecha de auditoría: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Tenant ID: $($tenantDetails.ObjectId)
Nombre del tenant: $($tenantDetails.DisplayName)
Dominios verificados: $((Get-MsolDomain | Where-Object { $_.Status -eq "Verified" }).Count)
"@
    }
    
    Write-Report -Section "INFORMACIÓN DEL TENANT" -Content $tenantInfo
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
    
    $userStats = @"
Total de usuarios: $($users.Count)
Usuarios habilitados: $($enabledUsers.Count)
Usuarios deshabilitados: $($disabledUsers.Count)
Usuarios invitados: $($guestUsers.Count)
Usuarios miembros: $($memberUsers.Count)
"@
    
    Write-Report -Section "ESTADÍSTICAS DE USUARIOS" -Content $userStats
    
    # Obtener roles de directorio y sus miembros
    if ($usingAzureAD) {
        $directoryRoles = Get-AzureADDirectoryRole
        
        $roleOutput = "ROLES DE ADMINISTRADOR Y MIEMBROS:`n`n"
        
        foreach ($role in $directoryRoles) {
            $roleMembers = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
            
            if ($roleMembers.Count -gt 0) {
                $roleOutput += "Rol: $($role.DisplayName)`n"
                $roleOutput += "Descripción: $($role.Description)`n"
                $roleOutput += "Miembros ($($roleMembers.Count)):`n"
                
                foreach ($member in $roleMembers) {
                    if ($member.ObjectType -eq "User") {
                        $roleOutput += "  - $($member.DisplayName) ($($member.UserPrincipalName))`n"
                    }
                    else {
                        $roleOutput += "  - [Grupo/App] $($member.DisplayName)`n"
                    }
                }
                
                # Marcar roles críticos
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
                
                if ($criticalRoles -contains $role.DisplayName) {
                    $roleOutput += "⚠️ ALERTA: Este es un rol crítico con altos privilegios`n"
                    
                    # Verificar si hay demasiados administradores globales
                    if ($role.DisplayName -eq "Global Administrator" -and $roleMembers.Count -gt 5) {
                        $roleOutput += "⚠️ ALERTA: Hay $($roleMembers.Count) Administradores Globales. Microsoft recomienda limitar este número.`n"
                    }
                }
                
                $roleOutput += "---`n"
            }
        }
    }
    else {
        $directoryRoles = Get-MsolRole
        
        $roleOutput = "ROLES DE ADMINISTRADOR Y MIEMBROS:`n`n"
        
        foreach ($role in $directoryRoles) {
            $roleMembers = Get-MsolRoleMember -RoleObjectId $role.ObjectId
            
            if ($roleMembers.Count -gt 0) {
                $roleOutput += "Rol: $($role.Name)`n"
                $roleOutput += "Descripción: $($role.Description)`n"
                $roleOutput += "Miembros ($($roleMembers.Count)):`n"
                
                foreach ($member in $roleMembers) {
                    $roleOutput += "  - $($member.DisplayName) ($($member.EmailAddress))`n"
                }
                
                # Marcar roles críticos
                $criticalRoles = @(
                    "Company Administrator", # Global Administrator en MSOnline
                    "User Account Administrator", 
                    "Exchange Service Administrator", 
                    "SharePoint Service Administrator", 
                    "Conditional Access Administrator",
                    "Security Administrator",
                    "Application Administrator"
                )
                
                if ($criticalRoles -contains $role.Name) {
                    $roleOutput += "⚠️ ALERTA: Este es un rol crítico con altos privilegios`n"
                    
                    # Verificar si hay demasiados administradores globales
                    if ($role.Name -eq "Company Administrator" -and $roleMembers.Count -gt 5) {
                        $roleOutput += "⚠️ ALERTA: Hay $($roleMembers.Count) Administradores Globales. Microsoft recomienda limitar este número.`n"
                    }
                }
                
                $roleOutput += "---`n"
            }
        }
    }
    
    Write-Report -Section "ROLES DE ADMINISTRADOR" -Content $roleOutput
    Write-Log "Usuarios y administradores analizados correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al analizar usuarios y administradores: $_" -Level "ERROR"
    Write-Report -Section "USUARIOS Y ADMINISTRADORES" -Content "Error al obtener información: $_"
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
    
    if ($conditionalAccessPolicies) {
        if ($conditionalAccessPolicies.Count -eq 0) {
            $policiesOutput = "No se encontraron políticas de acceso condicional configuradas.`n"
            $policiesOutput += "⚠️ ALERTA: La falta de políticas de acceso condicional puede representar un riesgo de seguridad.`n"
        }
        else {
            $policiesOutput = "Total de políticas: $($conditionalAccessPolicies.Count)`n`n"
            
            foreach ($policy in $conditionalAccessPolicies) {
                $policiesOutput += "Nombre: $($policy.DisplayName)`n"
                $policiesOutput += "Estado: $(if ($policy.State -eq 'enabled') { 'Habilitado' } else { 'Deshabilitado' })`n"
                $policiesOutput += "ID: $($policy.Id)`n"
                
                # Verificar si la política requiere MFA
                $requiresMfa = $false
                if ($policy.GrantControls.BuiltInControls -contains "mfa") {
                    $requiresMfa = $true
                    $policiesOutput += "Requiere MFA: Sí`n"
                }
                else {
                    $policiesOutput += "Requiere MFA: No`n"
                }
                
                $policiesOutput += "---`n"
            }
            
            # Verificar si hay política de línea base para todos los usuarios
            $hasBaselinePolicy = $conditionalAccessPolicies | Where-Object { 
                $_.Conditions.Users.IncludeUsers -contains 'All' -and 
                $_.State -eq 'enabled' -and 
                $_.GrantControls.BuiltInControls -contains 'mfa'
            }
            
            if (-not $hasBaselinePolicy) {
                $policiesOutput += "`n⚠️ ALERTA: No se detectó una política de línea base que requiera MFA para todos los usuarios.`n"
                $policiesOutput += "Se recomienda implementar al menos una política que requiera MFA para todos los usuarios.`n"
            }
        }
    }
    else {
        $policiesOutput = "No se pudo obtener información sobre políticas de acceso condicional.`n"
        $policiesOutput += "Esto puede deberse a que no tiene los permisos necesarios o a que está utilizando el módulo MSOnline, que no admite esta funcionalidad.`n"
        $policiesOutput += "Recomendación: Verifique manualmente las políticas de acceso condicional en el portal de Azure AD.`n"
    }
    
    Write-Report -Section "POLÍTICAS DE ACCESO CONDICIONAL" -Content $policiesOutput
    Write-Log "Revisión de políticas de acceso condicional completada" -Level "INFO"
}
catch {
    Write-Log "Error al revisar políticas de acceso condicional: $_" -Level "ERROR"
    Write-Report -Section "POLÍTICAS DE ACCESO CONDICIONAL" -Content "Error al obtener información: $_"
}
#endregion

#region 4. Verificación de Configuraciones de MFA
Write-Log "4. Verificando configuraciones de MFA..." -Level "INFO"

try {
    $mfaConfig = "CONFIGURACIÓN GENERAL DE MFA:`n`n"
    
    # Verificar si los valores predeterminados de seguridad están habilitados
    if ($usingAzureAD) {
        try {
            # Intentar obtener configuración de valores predeterminados de seguridad
            $securityDefaults = Get-AzureADMSIdentitySecurityDefaultsEnforcementPolicy -ErrorAction Stop
            
            if ($securityDefaults) {
                $mfaConfig += "Valores predeterminados de seguridad: $(if ($securityDefaults.IsEnabled) { 'Habilitados' } else { 'Deshabilitados' })`n"
                
                if ($securityDefaults.IsEnabled) {
                    $mfaConfig += "✓ BUENA PRÁCTICA: Los valores predeterminados de seguridad están habilitados, lo que requiere MFA para todos los usuarios.`n"
                }
                else {
                    $mfaConfig += "⚠️ ALERTA: Los valores predeterminados de seguridad están deshabilitados. Asegúrese de tener políticas de acceso condicional configuradas para requerir MFA.`n"
                }
            }
        }
        catch {
            $mfaConfig += "No se pudo obtener información sobre los valores predeterminados de seguridad: $_`n"
        }
    }
    
    # Analizar estado de MFA por usuario
    $mfaStatusOutput = "`nESTADO DE MFA POR USUARIO:`n"
    
    # Obtener usuarios (limitado a 100 para evitar problemas de rendimiento)
    if ($usingAzureAD) {
        $usersToCheck = $users | Where-Object { $_.AccountEnabled -eq $true -and $_.UserType -eq "Member" } | Select-Object -First 100
    }
    else {
        $usersToCheck = $users | Where-Object { $_.BlockCredential -eq $false -and $_.UserType -eq "Member" } | Select-Object -First 100
    }
    
    $usersWithoutMfa = 0
    $adminsWithoutMfa = 0
    $totalChecked = 0
    
    foreach ($user in $usersToCheck) {
        $totalChecked++
        
        # Obtener estado de MFA
        if ($usingAzureAD) {
            # No hay método directo en AzureAD para verificar MFA, intentamos usar MSOnline si está disponible
            if (Get-Command Get-MsolUser -ErrorAction SilentlyContinue) {
                try {
                    $mfaStatus = Get-MsolUser -UserPrincipalName $user.UserPrincipalName | Select-Object -ExpandProperty StrongAuthenticationRequirements
                    
                    if (-not $mfaStatus -or $mfaStatus.Count -eq 0) {
                        $usersWithoutMfa++
                        $mfaStatusOutput += "- $($user.DisplayName) ($($user.UserPrincipalName)) no tiene MFA configurado`n"
                        
                        # Verificar si es administrador
                        $isAdmin = $false
                        foreach ($role in $directoryRoles) {
                            $roleMembers = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
                            if ($roleMembers | Where-Object { $_.ObjectId -eq $user.ObjectId }) {
                                $isAdmin = $true
                                break
                            }
                        }
                        
                        if ($isAdmin) {
                            $adminsWithoutMfa++
                            $mfaStatusOutput += "  ⚠️ ALERTA: Este usuario tiene roles de administrador`n"
                        }
                    }
                }
                catch {
                    $mfaStatusOutput += "- Error al verificar MFA para $($user.DisplayName): $_`n"
                }
            }
            else {
                $mfaStatusOutput += "No se puede verificar el estado de MFA individual con el módulo AzureAD. Se requiere MSOnline.`n"
                break
            }
        }
        else {
            # Usando MSOnline
            try {
                $mfaStatus = Get-MsolUser -UserPrincipalName $user.UserPrincipalName | Select-Object -ExpandProperty StrongAuthenticationRequirements
                
                if (-not $mfaStatus -or $mfaStatus.Count -eq 0) {
                    $usersWithoutMfa++
                    $mfaStatusOutput += "- $($user.DisplayName) ($($user.UserPrincipalName)) no tiene MFA configurado`n"
                    
                    # Verificar si es administrador
                    $isAdmin = $false
                    foreach ($role in $directoryRoles) {
                        $roleMembers = Get-MsolRoleMember -RoleObjectId $role.ObjectId
                        if ($roleMembers | Where-Object { $_.EmailAddress -eq $user.UserPrincipalName }) {
                            $isAdmin = $true
                            break
                        }
                    }
                    
                    if ($isAdmin) {
                        $adminsWithoutMfa++
                        $mfaStatusOutput += "  ⚠️ ALERTA: Este usuario tiene roles de administrador`n"
                    }
                }
            }
            catch {
                $mfaStatusOutput += "- Error al verificar MFA para $($user.DisplayName): $_`n"
            }
        }
    }
    
    # Añadir estadísticas de MFA
    if ($totalChecked -gt 0) {
        $mfaStats = @"
ESTADÍSTICAS DE MFA:

Usuarios verificados: $totalChecked
Usuarios sin MFA: $usersWithoutMfa ($(if ($totalChecked -gt 0) { [math]::Round(($usersWithoutMfa / $totalChecked) * 100, 2) } else { 0 })%)
Administradores sin MFA: $adminsWithoutMfa
"@
        
        if ($adminsWithoutMfa -gt 0) {
            $mfaStats += "`n⚠️ ALERTA CRÍTICA: Hay administradores sin MFA configurado. Esto representa un riesgo de seguridad significativo.`n"
        }
        
        if ($usersWithoutMfa / $totalChecked -gt 0.5) {
            $mfaStats += "`n⚠️ ALERTA: Más del 50% de los usuarios no tienen MFA configurado.`n"
        }
    }
    else {
        $mfaStats = "No se pudo verificar el estado de MFA para ningún usuario.`n"
    }
    
    Write-Report -Section "CONFIGURACIÓN DE MFA" -Content "$mfaConfig`n`n$mfaStats`n`n$mfaStatusOutput"
    Write-Log "Configuraciones de MFA verificadas correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al verificar configuraciones de MFA: $_" -Level "ERROR"
    Write-Report -Section "CONFIGURACIÓN DE MFA" -Content "Error al obtener información: $_"
}
#endregion

#region 5. Análisis de Aplicaciones y Permisos
Write-Log "5. Analizando aplicaciones y permisos..." -Level "INFO"

try {
    # Obtener aplicaciones registradas
    if ($usingAzureAD) {
        $applications = Get-AzureADApplication -All $true
        
        if ($applications.Count -eq 0) {
            $appsOutput = "No se encontraron aplicaciones registradas en Azure AD.`n"
        }
        else {
            $appsOutput = "APLICACIONES REGISTRADAS EN AZURE AD:`n`n"
            $appsOutput += "Total de aplicaciones: $($applications.Count)`n`n"
            
            foreach ($app in $applications) {
                $appsOutput += "Nombre: $($app.DisplayName)`n"
                $appsOutput += "ID de aplicación: $($app.AppId)`n"
                $appsOutput += "ID de objeto: $($app.ObjectId)`n"
                
                # Verificar si la aplicación tiene secretos
                $appCredentials = Get-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId
                
                if ($appCredentials.Count -gt 0) {
                    $appsOutput += "Secretos configurados: $($appCredentials.Count)`n"
                    
                    foreach ($cred in $appCredentials) {
                        $expiryDate = $cred.EndDate
                        $daysUntilExpiry = (New-TimeSpan -Start (Get-Date) -End $expiryDate).Days
                        
                        $appsOutput += "  - Secreto expira el: $expiryDate (en $daysUntilExpiry días)`n"
                        
                        if ($daysUntilExpiry -lt 30) {
                            $appsOutput += "    ⚠️ ALERTA: Este secreto expirará pronto`n"
                        }
                    }
                }
                else {
                    $appsOutput += "Secretos configurados: 0`n"
                }
                
                # Verificar si la aplicación tiene certificados
                $appCertificates = Get-AzureADApplicationKeyCredential -ObjectId $app.ObjectId
                
                if ($appCertificates.Count -gt 0) {
                    $appsOutput += "Certificados configurados: $($appCertificates.Count)`n"
                    
                    foreach ($cert in $appCertificates) {
                        $expiryDate = $cert.EndDate
                        $daysUntilExpiry = (New-TimeSpan -Start (Get-Date) -End $expiryDate).Days
                        
                        $appsOutput += "  - Certificado expira el: $expiryDate (en $daysUntilExpiry días)`n"
                        
                        if ($daysUntilExpiry -lt 30) {
                            $appsOutput += "    ⚠️ ALERTA: Este certificado expirará pronto`n"
                        }
                    }
                }
                else {
                    $appsOutput += "Certificados configurados: 0`n"
                }
                
                $appsOutput += "---`n"
            }
        }
        
        # Obtener aplicaciones empresariales (service principals)
        $servicePrincipals = Get-AzureADServicePrincipal -All $true | Where-Object { $_.ServicePrincipalType -eq "Application" }
        
        $spOutput = "APLICACIONES EMPRESARIALES (SERVICE PRINCIPALS):`n`n"
        $spOutput += "Total de aplicaciones empresariales: $($servicePrincipals.Count)`n`n"
        
        # Mostrar algunas aplicaciones empresariales importantes
        $spOutput += "APLICACIONES EMPRESARIALES DESTACADAS:`n`n"
        
        $importantSps = $servicePrincipals | Where-Object { 
            $_.DisplayName -like "*Microsoft*" -or 
            $_.DisplayName -like "*Azure*" -or 
            $_.DisplayName -like "*Office*" -or 
            $_.DisplayName -like "*Graph*" 
        } | Select-Object -First 10
        
        foreach ($sp in $importantSps) {
            $spOutput += "- $($sp.DisplayName) (ID: $($sp.AppId))`n"
        }
    }
    else {
        # Usando MSOnline - capacidades limitadas para aplicaciones
        $appsOutput = "APLICACIONES REGISTRADAS EN AZURE AD:`n`n"
        $appsOutput += "No se puede obtener información detallada sobre aplicaciones registradas con el módulo MSOnline.`n"
        $appsOutput += "Para un análisis completo de aplicaciones, utilice el módulo AzureAD o Microsoft Graph.`n"
        
        $spOutput = "APLICACIONES EMPRESARIALES (SERVICE PRINCIPALS):`n`n"
        $spOutput += "No se puede obtener información detallada sobre service principals con el módulo MSOnline.`n"
    }
    
    Write-Report -Section "APLICACIONES Y PERMISOS" -Content "$appsOutput`n$spOutput"
    Write-Log "Aplicaciones y permisos analizados correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al analizar aplicaciones y permisos: $_" -Level "ERROR"
    Write-Report -Section "APLICACIONES Y PERMISOS" -Content "Error al obtener información: $_"
}
#endregion

#region 6. Análisis de Configuración de Seguridad
Write-Log "6. Analizando configuración de seguridad..." -Level "INFO"

try {
    $securityConfig = "CONFIGURACIÓN DE SEGURIDAD DEL DIRECTORIO:`n`n"
    
    # Verificar si los valores predeterminados de seguridad están habilitados
    if ($usingAzureAD) {
        try {
            $securityDefaults = Get-AzureADMSIdentitySecurityDefaultsEnforcementPolicy -ErrorAction Stop
            
            if ($securityDefaults) {
                $securityConfig += "Valores predeterminados de seguridad: $(if ($securityDefaults.IsEnabled) { 'Habilitados' } else { 'Deshabilitados' })`n"
                
                if (-not $securityDefaults.IsEnabled) {
                    $securityConfig += "⚠️ ALERTA: Los valores predeterminados de seguridad están deshabilitados. Esto puede representar un riesgo si no hay políticas de acceso condicional configuradas adecuadamente.`n"
                }
            }
        }
        catch {
            $securityConfig += "No se pudo obtener información sobre los valores predeterminados de seguridad: $_`n"
        }
    }
    else {
        $securityConfig += "No se puede verificar la configuración de valores predeterminados de seguridad con el módulo MSOnline.`n"
    }
    
    # Verificar configuración de contraseñas
    if (-not $usingAzureAD) {
        try {
            $passwordPolicy = Get-MsolPasswordPolicy -Domain $tenantDetails.InitialDomain
            
            $securityConfig += "`nPOLÍTICA DE CONTRASEÑAS:`n"
            $securityConfig += "Validez de contraseña: $($passwordPolicy.ValidityPeriod) $($passwordPolicy.ValidityPeriodType)`n"
            $securityConfig += "Notificación previa a expiración: $($passwordPolicy.NotificationDays) días`n"
            
            if ($passwordPolicy.ValidityPeriod -eq 0) {
                $securityConfig += "✓ BUENA PRÁCTICA: Las contraseñas no expiran (política moderna de contraseñas)`n"
            }
            elseif ($passwordPolicy.ValidityPeriod -gt 90) {
                $securityConfig += "⚠️ ALERTA: El período de validez de contraseñas es superior a 90 días`n"
            }
        }
        catch {
            $securityConfig += "`nError al obtener política de contraseñas: $_`n"
        }
        
        # Obtener configuración de complejidad de contraseñas
        try {
            $strongPasswordRequired = Get-MsolPasswordPolicy -Domain $tenantDetails.InitialDomain | Select-Object -ExpandProperty StrongPasswordRequired
            
            $securityConfig += "Contraseñas seguras requeridas: $strongPasswordRequired`n"
            
            if (-not $strongPasswordRequired) {
                $securityConfig += "⚠️ ALERTA: No se requieren contraseñas seguras`n"
            }
        }
        catch {
            $securityConfig += "Error al obtener configuración de complejidad de contraseñas: $_`n"
        }
    }
    
    Write-Report -Section "CONFIGURACIÓN DE SEGURIDAD" -Content $securityConfig
    Write-Log "Configuración de seguridad analizada correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al analizar configuración de seguridad: $_" -Level "ERROR"
    Write-Report -Section "CONFIGURACIÓN DE SEGURIDAD" -Content "Error al obtener información: $_"
}
#endregion

#region 7. Reporte Final
Write-Log "7. Generando reporte final..." -Level "INFO"

try {
    # Generar resumen ejecutivo
    $resumenEjecutivo = @"
RESUMEN EJECUTIVO DE AUDITORÍA DE SEGURIDAD DE MICROSOFT ENTRA ID
================================================================

Fecha de auditoría: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Tenant: $($tenantDetails.DisplayName)
Tenant ID: $($tenantDetails.ObjectId)

HALLAZGOS PRINCIPALES:

1. USUARIOS Y ADMINISTRADORES:
   - Total de usuarios: $($users.Count)
   - Usuarios habilitados: $($enabledUsers.Count)
   - Roles de administrador: $($directoryRoles.Count)

2. ACCESO CONDICIONAL:
   - Políticas de acceso condicional: $(if ($conditionalAccessPolicies) { $conditionalAccessPolicies.Count } else { "No disponible" })
   - Valores predeterminados de seguridad: $(if ($securityDefaults.IsEnabled) { 'Habilitados' } else { 'Deshabilitados' })

3. MFA Y SEGURIDAD DE IDENTIDAD:
   - Usuarios sin MFA: $usersWithoutMfa de $totalChecked verificados
   - Administradores sin MFA: $adminsWithoutMfa

4. APLICACIONES:
   - Aplicaciones registradas: $(if ($applications) { $applications.Count } else { "No disponible" })

RECOMENDACIONES GENERALES:

1. Implementar MFA para todos los usuarios, especialmente para cuentas de administrador.
2. Revisar y configurar políticas de acceso condicional para proteger recursos críticos.
3. Revisar permisos de aplicaciones, especialmente aquellas con permisos elevados.
4. Habilitar valores predeterminados de seguridad si no hay políticas de acceso condicional configuradas.
5. Revisar regularmente las asignaciones de roles administrativos para asegurar el principio de mínimo privilegio.

Para más detalles, consulte las secciones específicas de este reporte.
"@

    # Añadir resumen ejecutivo al inicio del reporte
    $reportContent = Get-Content -Path $reportFile -Raw
    $newReportContent = $resumenEjecutivo + "`n`n" + $reportContent
    Set-Content -Path $reportFile -Value $newReportContent
    
    Write-Log "Reporte final generado correctamente en: $reportFile" -Level "INFO"
    Write-Log "Log de la auditoría guardado en: $logFile" -Level "INFO"
    
    # Mostrar ubicación del reporte
    Write-Host "`nLa auditoría de seguridad de Microsoft Entra ID ha finalizado correctamente." -ForegroundColor Green
    Write-Host "El reporte completo se encuentra en: $reportFile" -ForegroundColor Cyan
    Write-Host "El log de la auditoría se encuentra en: $logFile" -ForegroundColor Cyan
}
catch {
    Write-Log "Error al generar reporte final: $_" -Level "ERROR"
}
#endregion

# Desconectar sesiones
if ($usingAzureAD) {
    Disconnect-AzureAD -ErrorAction SilentlyContinue
}

Write-Log "Auditoría de seguridad completada" -Level "INFO"
