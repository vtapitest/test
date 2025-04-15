<#
.SYNOPSIS
    Script de auditoría de seguridad para Microsoft Entra ID (Azure AD) sin requerir suscripción completa de Azure.
.DESCRIPTION
    Este script realiza una auditoría de seguridad básica en Microsoft Entra ID,
    incluyendo revisión de usuarios, roles, políticas de acceso condicional, configuración de MFA,
    y aplicaciones registradas.
.NOTES
    Requisitos:
    - Módulos Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement, 
      Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Applications
    - Permisos de lectura en Entra ID (Azure AD)
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

# Verificar módulos requeridos
$requiredModules = @(
    "Microsoft.Graph.Authentication", 
    "Microsoft.Graph.Identity.DirectoryManagement", 
    "Microsoft.Graph.Identity.SignIns", 
    "Microsoft.Graph.Applications",
    "Microsoft.Graph.Users"
)

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Log "El módulo $module no está instalado. Intentando instalar..." -Level "WARNING"
        try {
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
            Write-Log "Módulo $module instalado correctamente" -Level "INFO"
        }
        catch {
            Write-Log "Error al instalar el módulo $module: $_" -Level "ERROR"
            Write-Log "Por favor, instale manualmente el módulo con: Install-Module -Name $module -Force -AllowClobber" -Level "ERROR"
            exit
        }
    }
}
#endregion

#region 1. Autenticación con Microsoft Graph
Write-Log "Iniciando auditoría de seguridad de Microsoft Entra ID..." -Level "INFO"
Write-Log "1. Autenticación con Microsoft Graph" -Level "INFO"

try {
    # Conectar a Microsoft Graph
    Connect-MgGraph -Scopes @(
        "Directory.Read.All", 
        "Policy.Read.All", 
        "AuditLog.Read.All", 
        "IdentityRiskyUser.Read.All", 
        "Application.Read.All",
        "User.Read.All"
    ) -ErrorAction Stop
    
    Write-Log "Conexión a Microsoft Graph establecida correctamente" -Level "INFO"
    
    # Obtener información del tenant
    $organization = Get-MgOrganization
    $tenantInfo = @"
Fecha de auditoría: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Tenant ID: $($organization.Id)
Nombre del tenant: $($organization.DisplayName)
Dominio principal: $($organization.VerifiedDomains | Where-Object { $_.IsDefault -eq $true } | Select-Object -ExpandProperty Name)
Dominios verificados: $($organization.VerifiedDomains.Count)
"@
    
    Write-Report -Section "INFORMACIÓN DEL TENANT" -Content $tenantInfo
}
catch {
    Write-Log "Error durante la autenticación con Microsoft Graph: $_" -Level "ERROR"
    exit
}
#endregion

#region 2. Análisis de Usuarios y Administradores
Write-Log "2. Analizando usuarios y administradores..." -Level "INFO"

try {
    # Obtener todos los usuarios
    $users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AccountEnabled, CreatedDateTime, UserType, AssignedLicenses
    
    # Estadísticas básicas de usuarios
    $enabledUsers = $users | Where-Object { $_.AccountEnabled -eq $true }
    $disabledUsers = $users | Where-Object { $_.AccountEnabled -eq $false }
    $guestUsers = $users | Where-Object { $_.UserType -eq "Guest" }
    $memberUsers = $users | Where-Object { $_.UserType -eq "Member" }
    $licensedUsers = $users | Where-Object { $_.AssignedLicenses.Count -gt 0 }
    
    $userStats = @"
Total de usuarios: $($users.Count)
Usuarios habilitados: $($enabledUsers.Count)
Usuarios deshabilitados: $($disabledUsers.Count)
Usuarios invitados: $($guestUsers.Count)
Usuarios miembros: $($memberUsers.Count)
Usuarios con licencia: $($licensedUsers.Count)
"@
    
    Write-Report -Section "ESTADÍSTICAS DE USUARIOS" -Content $userStats
    
    # Obtener roles de directorio y sus miembros
    $directoryRoles = Get-MgDirectoryRole -All
    
    $roleOutput = "ROLES DE ADMINISTRADOR Y MIEMBROS:`n`n"
    
    foreach ($role in $directoryRoles) {
        $roleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
        
        if ($roleMembers.Count -gt 0) {
            $roleOutput += "Rol: $($role.DisplayName)`n"
            $roleOutput += "Descripción: $($role.Description)`n"
            $roleOutput += "Miembros ($($roleMembers.Count)):`n"
            
            foreach ($member in $roleMembers) {
                try {
                    $user = Get-MgUser -UserId $member.Id -ErrorAction SilentlyContinue
                    if ($user) {
                        $roleOutput += "  - $($user.DisplayName) ($($user.UserPrincipalName))`n"
                    }
                    else {
                        $sp = Get-MgServicePrincipal -ServicePrincipalId $member.Id -ErrorAction SilentlyContinue
                        if ($sp) {
                            $roleOutput += "  - [App] $($sp.DisplayName)`n"
                        }
                        else {
                            $roleOutput += "  - ID: $($member.Id) (Tipo desconocido)`n"
                        }
                    }
                }
                catch {
                    $roleOutput += "  - Error al obtener detalles del miembro: $($member.Id)`n"
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
    $conditionalAccessPolicies = Get-MgIdentityConditionalAccessPolicy
    
    if ($conditionalAccessPolicies.Count -eq 0) {
        $policiesOutput = "No se encontraron políticas de acceso condicional configuradas.`n"
        $policiesOutput += "⚠️ ALERTA: La falta de políticas de acceso condicional puede representar un riesgo de seguridad.`n"
    }
    else {
        $policiesOutput = $conditionalAccessPolicies | ForEach-Object {
            $policy = $_
            $output = "Nombre: $($policy.DisplayName)`n"
            $output += "Estado: $(if ($policy.State -eq 'enabled') { 'Habilitado' } else { 'Deshabilitado' })`n"
            $output += "ID: $($policy.Id)`n"
            
            # Condiciones
            $output += "Condiciones:`n"
            
            # Usuarios
            $output += "  - Usuarios incluidos: "
            if ($policy.Conditions.Users.IncludeUsers -contains 'All') {
                $output += "Todos`n"
            }
            elseif ($policy.Conditions.Users.IncludeUsers.Count -gt 0) {
                $output += "$($policy.Conditions.Users.IncludeUsers -join ', ')`n"
            }
            else {
                $output += "Ninguno`n"
            }
            
            $output += "  - Usuarios excluidos: $($policy.Conditions.Users.ExcludeUsers -join ', ')`n"
            
            # Aplicaciones
            $output += "  - Aplicaciones incluidas: "
            if ($policy.Conditions.Applications.IncludeApplications -contains 'All') {
                $output += "Todas`n"
            }
            elseif ($policy.Conditions.Applications.IncludeApplications.Count -gt 0) {
                $output += "$($policy.Conditions.Applications.IncludeApplications -join ', ')`n"
            }
            else {
                $output += "Ninguna`n"
            }
            
            # Ubicaciones
            if ($policy.Conditions.Locations) {
                $output += "  - Ubicaciones incluidas: $($policy.Conditions.Locations.IncludeLocations -join ', ')`n"
                $output += "  - Ubicaciones excluidas: $($policy.Conditions.Locations.ExcludeLocations -join ', ')`n"
            }
            
            # Controles de acceso
            $output += "Controles de acceso:`n"
            
            # Concesión
            if ($policy.GrantControls) {
                $output += "  - Tipo de control: $(if ($policy.GrantControls.Operator -eq 'OR') { 'Requerir uno de los controles seleccionados' } else { 'Requerir todos los controles seleccionados' })`n"
                
                if ($policy.GrantControls.BuiltInControls -contains 'mfa') {
                    $output += "  - Requiere MFA: Sí`n"
                }
                else {
                    $output += "  - Requiere MFA: No`n"
                }
                
                if ($policy.GrantControls.BuiltInControls -contains 'compliantDevice') {
                    $output += "  - Requiere dispositivo compatible: Sí`n"
                }
                
                if ($policy.GrantControls.BuiltInControls -contains 'domainJoinedDevice') {
                    $output += "  - Requiere dispositivo unido a dominio: Sí`n"
                }
            }
            
            # Verificar si hay políticas para administradores
            $adminRoles = @("Global Administrator", "Privileged Role Administrator", "User Administrator")
            $hasAdminPolicy = $false
            
            if ($policy.Conditions.Users.IncludeRoles) {
                foreach ($role in $policy.Conditions.Users.IncludeRoles) {
                    if ($adminRoles -contains $role) {
                        $hasAdminPolicy = $true
                        break
                    }
                }
            }
            
            if ($hasAdminPolicy -and $policy.State -eq 'enabled') {
                $output += "✓ BUENA PRÁCTICA: Esta política protege cuentas de administrador`n"
            }
            
            $output += "---`n"
            return $output
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
    
    Write-Report -Section "POLÍTICAS DE ACCESO CONDICIONAL" -Content $policiesOutput
    Write-Log "Políticas de acceso condicional revisadas correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al revisar políticas de acceso condicional: $_" -Level "ERROR"
    Write-Report -Section "POLÍTICAS DE ACCESO CONDICIONAL" -Content "Error al obtener información: $_"
}
#endregion

#region 4. Verificación de Configuraciones de MFA
Write-Log "4. Verificando configuraciones de MFA..." -Level "INFO"

try {
    # Obtener configuración de autenticación
    $authenticationMethodsPolicy = Get-MgPolicyAuthenticationMethodPolicy
    
    if ($authenticationMethodsPolicy) {
        $mfaConfig = @"
CONFIGURACIÓN GENERAL DE MFA:

Estado de la política: $(if ($authenticationMethodsPolicy.State -eq 'enabled') { 'Habilitada' } else { 'Deshabilitada' })
"@
        
        # Obtener métodos de autenticación configurados
        $authMethods = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethod
        
        if ($authMethods) {
            $mfaConfig += "`n`nMÉTODOS DE AUTENTICACIÓN CONFIGURADOS:`n"
            
            foreach ($method in $authMethods) {
                $methodState = if ($method.State -eq 'enabled') { 'Habilitado' } else { 'Deshabilitado' }
                $mfaConfig += "`n- $($method.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', ''): $methodState"
            }
        }
        
        # Verificar configuración de SSPR
        try {
            $sspr = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "passwordReset"
            
            if ($sspr) {
                $mfaConfig += "`n`nCONFIGURACIÓN DE AUTOSERVICIO DE RESTABLECIMIENTO DE CONTRASEÑA (SSPR):`n"
                $mfaConfig += "`nEstado: $(if ($sspr.State -eq 'enabled') { 'Habilitado' } else { 'Deshabilitado' })"
                
                if ($sspr.State -eq 'enabled') {
                    # Verificar métodos permitidos para SSPR
                    if ($sspr.AdditionalProperties.authenticationMethodConfigurations) {
                        $mfaConfig += "`nMétodos permitidos para SSPR:"
                        
                        foreach ($method in $sspr.AdditionalProperties.authenticationMethodConfigurations) {
                            $methodState = if ($method.state -eq 'enabled') { 'Habilitado' } else { 'Deshabilitado' }
                            $mfaConfig += "`n- $($method.'@odata.type' -replace '#microsoft.graph.', ''): $methodState"
                        }
                    }
                }
                else {
                    $mfaConfig += "`n⚠️ ALERTA: El autoservicio de restablecimiento de contraseña (SSPR) está deshabilitado."
                }
            }
        }
        catch {
            $mfaConfig += "`n`nNo se pudo obtener información de SSPR: $_"
        }
    }
    else {
        $mfaConfig = "No se pudo obtener la configuración de métodos de autenticación.`n"
    }
    
    # Analizar estado de MFA por usuario
    $mfaStatusOutput = "`nESTADO DE MFA POR USUARIO:`n"
    
    # Obtener usuarios (limitado a 100 para evitar problemas de rendimiento)
    $users = Get-MgUser -Top 100 -Property Id, DisplayName, UserPrincipalName, AccountEnabled, UserType
    
    $usersWithoutMfa = 0
    $adminsWithoutMfa = 0
    $totalChecked = 0
    
    foreach ($user in $users) {
        # Omitir cuentas deshabilitadas y cuentas de invitado
        if (-not $user.AccountEnabled -or $user.UserType -eq "Guest") {
            continue
        }
        
        $totalChecked++
        
        # Obtener métodos de autenticación del usuario
        try {
            $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id
            
            # Determinar si MFA está habilitado
            $hasMfa = $authMethods | Where-Object { 
                $_.AdditionalProperties.'@odata.type' -ne "#microsoft.graph.passwordAuthenticationMethod" -and 
                $_.AdditionalProperties.'@odata.type' -ne $null
            }
            
            if (-not $hasMfa) {
                $usersWithoutMfa++
                $mfaStatusOutput += "- $($user.DisplayName) ($($user.UserPrincipalName)) no tiene MFA configurado`n"
                
                # Verificar si es administrador
                $userRoles = Get-MgUserDirectoryRole -UserId $user.Id -ErrorAction SilentlyContinue
                if ($userRoles) {
                    $adminsWithoutMfa++
                    $mfaStatusOutput += "  ⚠️ ALERTA: Este usuario tiene roles de administrador`n"
                }
            }
        }
        catch {
            $mfaStatusOutput += "- Error al verificar MFA para $($user.DisplayName): $_`n"
        }
    }
    
    # Añadir estadísticas de MFA
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
    $applications = Get-MgApplication -All
    
    if ($applications.Count -eq 0) {
        $appsOutput = "No se encontraron aplicaciones registradas en Azure AD.`n"
    }
    else {
        $appsOutput = "APLICACIONES REGISTRADAS EN AZURE AD:`n`n"
        
        foreach ($app in $applications) {
            $appsOutput += "Nombre: $($app.DisplayName)`n"
            $appsOutput += "ID de aplicación: $($app.AppId)`n"
            $appsOutput += "ID de objeto: $($app.Id)`n"
            $appsOutput += "Fecha de creación: $($app.CreatedDateTime)`n"
            
            # Verificar si la aplicación tiene secretos
            if ($app.PasswordCredentials.Count -gt 0) {
                $appsOutput += "Secretos configurados: $($app.PasswordCredentials.Count)`n"
                
                foreach ($secret in $app.PasswordCredentials) {
                    $expiryDate = $secret.EndDateTime
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
            if ($app.KeyCredentials.Count -gt 0) {
                $appsOutput += "Certificados configurados: $($app.KeyCredentials.Count)`n"
                
                foreach ($cert in $app.KeyCredentials) {
                    $expiryDate = $cert.EndDateTime
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
            
            # Verificar permisos delegados y de aplicación
            try {
                $appServicePrincipals = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"
                
                if ($appServicePrincipals) {
                    $sp = $appServicePrincipals[0]
                    
                    # Verificar permisos delegados
                    $oauth2PermissionGrants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $sp.Id -All
                    
                    if ($oauth2PermissionGrants) {
                        $appsOutput += "Permisos delegados:`n"
                        
                        foreach ($grant in $oauth2PermissionGrants) {
                            $resourceSp = Get-MgServicePrincipal -ServicePrincipalId $grant.ResourceId -ErrorAction SilentlyContinue
                            $resourceName = if ($resourceSp) { $resourceSp.DisplayName } else { $grant.ResourceId }
                            
                            $appsOutput += "  - Recurso: $resourceName`n"
                            $appsOutput += "    Alcances: $($grant.Scope)`n"
                            
                            # Verificar permisos sensibles
                            $sensitiveScopes = @("Mail.Read", "Mail.ReadWrite", "Files.Read", "Files.ReadWrite", "Directory.Read.All", "Directory.ReadWrite.All", "User.Read.All", "User.ReadWrite.All")
                            $grantedScopes = $grant.Scope -split " "
                            
                            foreach ($scope in $grantedScopes) {
                                if ($sensitiveScopes -contains $scope) {
                                    $appsOutput += "    ⚠️ ALERTA: Permiso sensible detectado: $scope`n"
                                }
                            }
                        }
                    }
                    
                    # Verificar permisos de aplicación
                    $appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All
                    
                    if ($appRoleAssignments) {
                        $appsOutput += "Permisos de aplicación:`n"
                        
                        foreach ($assignment in $appRoleAssignments) {
                            $resourceSp = Get-MgServicePrincipal -ServicePrincipalId $assignment.ResourceId -ErrorAction SilentlyContinue
                            $resourceName = if ($resourceSp) { $resourceSp.DisplayName } else { $assignment.ResourceId }
                            
                            # Obtener el nombre del rol
                            $roleName = "Desconocido"
                            if ($resourceSp) {
                                $role = $resourceSp.AppRoles | Where-Object { $_.Id -eq $assignment.AppRoleId }
                                if ($role) {
                                    $roleName = $role.DisplayName
                                }
                            }
                            
                            $appsOutput += "  - Recurso: $resourceName`n"
                            $appsOutput += "    Rol: $roleName`n"
                            
                            # Verificar roles sensibles
                            $sensitiveRoles = @("Directory.Read.All", "Directory.ReadWrite.All", "User.Read.All", "User.ReadWrite.All", "Mail.Read", "Mail.ReadWrite", "Files.Read", "Files.ReadWrite")
                            
                            if ($sensitiveRoles -contains $roleName) {
                                $appsOutput += "    ⚠️ ALERTA: Rol sensible detectado: $roleName`n"
                            }
                        }
                    }
                }
            }
            catch {
                $appsOutput += "Error al obtener permisos: $_`n"
            }
            
            $appsOutput += "---`n"
        }
    }
    
    # Obtener aplicaciones empresariales (service principals)
    $servicePrincipals = Get-MgServicePrincipal -Filter "servicePrincipalType eq 'Application'" -All
    
    $spOutput = "APLICACIONES EMPRESARIALES (SERVICE PRINCIPALS):`n`n"
    $spOutput += "Total de aplicaciones empresariales: $($servicePrincipals.Count)`n`n"
    
    # Verificar aplicaciones con consentimiento de administrador
    $adminConsentApps = $servicePrincipals | Where-Object { $_.ServicePrincipalType -eq "Application" -and $_.AppRoleAssignmentRequired -eq $true }
    $spOutput += "Aplicaciones que requieren consentimiento de administrador: $($adminConsentApps.Count)`n"
    
    # Verificar aplicaciones con acceso a la API de Graph
    $graphResourceId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    $appsWithGraphAccess = @()
    
    foreach ($sp in $servicePrincipals) {
        $graphPermissions = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All | 
            Where-Object { $_.ResourceId -eq $graphResourceId }
        
        if ($graphPermissions) {
            $appsWithGraphAccess += $sp
        }
    }
    
    $spOutput += "Aplicaciones con acceso a Microsoft Graph: $($appsWithGraphAccess.Count)`n"
    
    if ($appsWithGraphAccess.Count -gt 0) {
        $spOutput += "`nAPLICACIONES CON ACCESO A MICROSOFT GRAPH:`n"
        
        foreach ($app in $appsWithGraphAccess) {
            $spOutput += "  - $($app.DisplayName) (ID: $($app.AppId))`n"
            
            # Obtener permisos específicos de Graph
            $graphPermissions = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $app.Id -All | 
                Where-Object { $_.ResourceId -eq $graphResourceId }
            
            if ($graphPermissions) {
                $spOutput += "    Permisos de Graph:`n"
                
                foreach ($permission in $graphPermissions) {
                    # Obtener el nombre del rol
                    $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue
                    $roleName = "Desconocido"
                    
                    if ($graphSp) {
                        $role = $graphSp.AppRoles | Where-Object { $_.Id -eq $permission.AppRoleId }
                        if ($role) {
                            $roleName = $role.DisplayName
                        }
                    }
                    
                    $spOutput += "    - $roleName`n"
                    
                    # Verificar permisos de alto privilegio
                    $highPrivilegePermissions = @(
                        "Directory.Read.All", 
                        "Directory.ReadWrite.All", 
                        "User.Read.All", 
                        "User.ReadWrite.All",
                        "Group.Read.All",
                        "Group.ReadWrite.All",
                        "Application.Read.All",
                        "Application.ReadWrite.All"
                    )
                    
                    if ($highPrivilegePermissions -contains $roleName) {
                        $spOutput += "      ⚠️ ALERTA: Permiso de alto privilegio`n"
                    }
                }
            }
            
            $spOutput += "`n"
        }
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
    # Obtener configuración de seguridad del directorio
    $securityDefaults = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy
    
    $securityConfig = "CONFIGURACIÓN DE SEGURIDAD DEL DIRECTORIO:`n`n"
    
    # Verificar si los valores predeterminados de seguridad están habilitados
    $securityConfig += "Valores predeterminados de seguridad: $(if ($securityDefaults.IsEnabled) { 'Habilitados' } else { 'Deshabilitados' })`n"
    
    if (-not $securityDefaults.IsEnabled) {
        $securityConfig += "⚠️ ALERTA: Los valores predeterminados de seguridad están deshabilitados. Esto puede representar un riesgo si no hay políticas de acceso condicional configuradas adecuadamente.`n"
    }
    
    # Intentar obtener configuración de contraseñas
    try {
        $passwordPolicy = Get-MgDirectorySettingTemplate | 
            Where-Object { $_.DisplayName -eq "Password Rule Settings" } | 
            Select-Object -First 1
        
        if ($passwordPolicy) {
            $securityConfig += "`nPOLÍTICA DE CONTRASEÑAS:`n"
            $securityConfig += "Plantilla: $($passwordPolicy.DisplayName)`n"
            
            # Intentar obtener configuración actual
            $currentSettings = Get-MgDirectorySetting | 
                Where-Object { $_.TemplateId -eq $passwordPolicy.Id } | 
                Select-Object -First 1
            
            if ($currentSettings) {
                $securityConfig += "Configuración actual:`n"
                
                foreach ($value in $currentSettings.Values) {
                    $securityConfig += "  - $($value.Name): $($value.Value)`n"
                }
            }
            else {
                $securityConfig += "No se encontró configuración personalizada de contraseñas. Se están utilizando los valores predeterminados.`n"
            }
        }
        else {
            $securityConfig += "`nNo se pudo obtener información sobre la política de contraseñas.`n"
        }
    }
    catch {
        $securityConfig += "`nError al obtener política de contraseñas: $_`n"
    }
    
    # Verificar configuración de bloqueo de cuentas
    try {
        $authenticationStrengthPolicies = Get-MgPolicyAuthenticationStrengthPolicy
        
        if ($authenticationStrengthPolicies) {
            $securityConfig += "`nPOLÍTICAS DE FUERZA DE AUTENTICACIÓN:`n"
            
            foreach ($policy in $authenticationStrengthPolicies) {
                $securityConfig += "- $($policy.DisplayName)`n"
                $securityConfig += "  Descripción: $($policy.Description)`n"
                $securityConfig += "  Métodos permitidos: $($policy.AllowedCombinations -join ', ')`n"
            }
        }
    }
    catch {
        $securityConfig += "`nError al obtener políticas de fuerza de autenticación: $_`n"
    }
    
    # Verificar configuración de registro de auditoría
    try {
        $auditLogConfig = Get-MgPolicyAuditLogPolicy
        
        if ($auditLogConfig) {
            $securityConfig += "`nCONFIGURACIÓN DE REGISTROS DE AUDITORÍA:`n"
            $securityConfig += "Estado: $(if ($auditLogConfig.IsEnabled) { 'Habilitado' } else { 'Deshabilitado' })`n"
            
            if (-not $auditLogConfig.IsEnabled) {
                $securityConfig += "⚠️ ALERTA: Los registros de auditoría están deshabilitados. Esto dificulta la detección y análisis de actividades sospechosas.`n"
            }
        }
    }
    catch {
        $securityConfig += "`nError al obtener configuración de registros de auditoría: $_`n"
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
Tenant: $($organization.DisplayName)
Tenant ID: $($organization.Id)

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
   - Aplicaciones con acceso a Graph: $(if ($appsWithGraphAccess) { $appsWithGraphAccess.Count } else { "No disponible" })

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

# Desconectar de Microsoft Graph
Disconnect-MgGraph | Out-Null
Write-Log "Desconectado de Microsoft Graph" -Level "INFO"
