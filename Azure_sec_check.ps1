<#
.SYNOPSIS
    Script de auditoría de seguridad para entornos Azure.
.DESCRIPTION
    Este script realiza una auditoría de seguridad completa en un entorno Azure,
    incluyendo revisión de roles, políticas de acceso condicional, configuración de MFA,
    alertas de seguridad, configuraciones de recursos y aplicaciones expuestas.
.NOTES
    Requisitos:
    - Módulos Az, Microsoft.Graph, Az.SecurityCenter
    - Roles de Security Administrator y Global Reader
    Autor: v0
    Fecha: 15/04/2025
#>

#region Configuración inicial
# Configuración de preferencias de error
$ErrorActionPreference = "Continue"
$WarningPreference = "SilentlyContinue"

# Crear carpeta para el reporte si no existe
$reportFolder = "$env:USERPROFILE\AzureSecurityAudit"
if (-not (Test-Path -Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder | Out-Null
}

$reportFile = "$reportFolder\SecurityAuditReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$logFile = "$reportFolder\SecurityAuditLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

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
$requiredModules = @("Az.Accounts", "Az.Resources", "Az.Security", "Az.Storage", "Az.Network", "Microsoft.Graph.Authentication", "Microsoft.Graph.Identity.SignIns")

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

#region 1. Autenticación y Contexto
Write-Log "Iniciando auditoría de seguridad de Azure..." -Level "INFO"
Write-Log "1. Autenticación y selección de contexto" -Level "INFO"

try {
    # Conectar a Azure
    Connect-AzAccount -ErrorAction Stop
    Write-Log "Conexión a Azure establecida correctamente" -Level "INFO"
    
    # Obtener todas las suscripciones
    $subscriptions = Get-AzSubscription
    
    if ($subscriptions.Count -eq 0) {
        Write-Log "No se encontraron suscripciones disponibles" -Level "ERROR"
        exit
    }
    
    # Mostrar suscripciones disponibles
    Write-Host "Suscripciones disponibles:"
    $i = 1
    foreach ($sub in $subscriptions) {
        Write-Host "$i. $($sub.Name) ($($sub.Id))"
        $i++
    }
    
    # Seleccionar suscripción
    if ($subscriptions.Count -eq 1) {
        $selectedSubscription = $subscriptions[0]
    }
    else {
        $selection = Read-Host "Seleccione el número de la suscripción a auditar (1-$($subscriptions.Count))"
        $selectedSubscription = $subscriptions[$selection - 1]
    }
    
    # Establecer contexto
    Set-AzContext -SubscriptionId $selectedSubscription.Id | Out-Null
    Write-Log "Suscripción seleccionada: $($selectedSubscription.Name) ($($selectedSubscription.Id))" -Level "INFO"
    
    # Guardar información en el reporte
    $contextInfo = @"
Fecha de auditoría: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Usuario: $((Get-AzContext).Account.Id)
Suscripción: $($selectedSubscription.Name)
ID de Suscripción: $($selectedSubscription.Id)
Tenant ID: $((Get-AzContext).Tenant.Id)
"@
    
    Write-Report -Section "INFORMACIÓN DE CONTEXTO" -Content $contextInfo
}
catch {
    Write-Log "Error durante la autenticación: $_" -Level "ERROR"
    exit
}

# Conectar a Microsoft Graph
try {
    Connect-MgGraph -Scopes "Directory.Read.All", "Policy.Read.All", "AuditLog.Read.All", "IdentityRiskyUser.Read.All", "Application.Read.All" -ErrorAction Stop
    Write-Log "Conexión a Microsoft Graph establecida correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al conectar con Microsoft Graph: $_" -Level "WARNING"
    Write-Log "Algunas funcionalidades relacionadas con Azure AD no estarán disponibles" -Level "WARNING"
}
#endregion

#region 2. Enumeración de Asignaciones de Roles
Write-Log "2. Enumerando asignaciones de roles..." -Level "INFO"

try {
    # Obtener el usuario actual
    $currentUser = (Get-AzContext).Account.Id
    
    # Obtener asignaciones de roles para el usuario actual
    $currentUserRoles = Get-AzRoleAssignment -SignInName $currentUser
    
    # Obtener todas las asignaciones de roles a nivel de suscripción
    $allRoleAssignments = Get-AzRoleAssignment
    
    # Formatear la salida para el reporte
    $currentUserRolesOutput = $currentUserRoles | ForEach-Object {
        $scope = if ($_.Scope -eq "/") { "Directorio" } else { $_.Scope }
        "Rol: $($_.RoleDefinitionName)`nAlcance: $scope`nAsignado a: $($_.SignInName)`n---"
    }
    
    $allRolesOutput = $allRoleAssignments | ForEach-Object {
        $scope = if ($_.Scope -eq "/") { "Directorio" } else { $_.Scope }
        "Rol: $($_.RoleDefinitionName)`nAlcance: $scope`nAsignado a: $($_.SignInName)`n---"
    }
    
    # Escribir en el reporte
    Write-Report -Section "ASIGNACIONES DE ROLES DEL USUARIO ACTUAL" -Content ($currentUserRolesOutput -join "`n")
    Write-Report -Section "TODAS LAS ASIGNACIONES DE ROLES" -Content ($allRolesOutput -join "`n")
    
    Write-Log "Asignaciones de roles enumeradas correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al enumerar asignaciones de roles: $_" -Level "ERROR"
    Write-Report -Section "ASIGNACIONES DE ROLES" -Content "Error al obtener información: $_"
}
#endregion

#region 3. Revisión de Políticas de Acceso Condicional
Write-Log "3. Revisando políticas de acceso condicional..." -Level "INFO"

try {
    # Verificar si estamos conectados a Microsoft Graph
    if (Get-Command Get-MgIdentityConditionalAccessPolicy -ErrorAction SilentlyContinue) {
        # Obtener políticas de acceso condicional
        $conditionalAccessPolicies = Get-MgIdentityConditionalAccessPolicy
        
        if ($conditionalAccessPolicies.Count -eq 0) {
            $policiesOutput = "No se encontraron políticas de acceso condicional configuradas."
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
                    
                    if ($policy.GrantControls.BuiltInControls -contains 'compliantDevice') {
                        $output += "  - Requiere dispositivo compatible: Sí`n"
                    }
                    
                    if ($policy.GrantControls.BuiltInControls -contains 'domainJoinedDevice') {
                        $output += "  - Requiere dispositivo unido a dominio: Sí`n"
                    }
                    
                    if ($policy.GrantControls.BuiltInControls -contains 'approvedApplication') {
                        $output += "  - Requiere aplicación aprobada: Sí`n"
                    }
                    
                    if ($policy.GrantControls.BuiltInControls -contains 'compliantApplication') {
                        $output += "  - Requiere aplicación compatible: Sí`n"
                    }
                }
                
                # Sesión
                if ($policy.SessionControls) {
                    if ($policy.SessionControls.ApplicationEnforcedRestrictions.IsEnabled) {
                        $output += "  - Restricciones de aplicación aplicadas: Sí`n"
                    }
                    
                    if ($policy.SessionControls.CloudAppSecurity.IsEnabled) {
                        $output += "  - Uso de Cloud App Security: Sí`n"
                    }
                    
                    if ($policy.SessionControls.SignInFrequency.IsEnabled) {
                        $output += "  - Frecuencia de inicio de sesión: $($policy.SessionControls.SignInFrequency.Value) $($policy.SessionControls.SignInFrequency.Type)`n"
                    }
                    
                    if ($policy.SessionControls.PersistentBrowser.IsEnabled) {
                        $output += "  - Persistencia de sesión de navegador: $($policy.SessionControls.PersistentBrowser.Mode)`n"
                    }
                }
                
                $output += "---`n"
                return $output
            }
        }
        
        Write-Report -Section "POLÍTICAS DE ACCESO CONDICIONAL" -Content ($policiesOutput -join "`n")
        Write-Log "Políticas de acceso condicional revisadas correctamente" -Level "INFO"
    }
    else {
        Write-Log "No se pudo acceder a las políticas de acceso condicional. Verifique los permisos de Microsoft Graph" -Level "WARNING"
        Write-Report -Section "POLÍTICAS DE ACCESO CONDICIONAL" -Content "No se pudo acceder a las políticas de acceso condicional. Verifique los permisos de Microsoft Graph."
    }
}
catch {
    Write-Log "Error al revisar políticas de acceso condicional: $_" -Level "ERROR"
    Write-Report -Section "POLÍTICAS DE ACCESO CONDICIONAL" -Content "Error al obtener información: $_"
}
#endregion

#region 4. Verificación de Configuraciones de MFA y Seguridad de Identidad
Write-Log "4. Verificando configuraciones de MFA y seguridad de identidad..." -Level "INFO"

try {
    # Verificar si estamos conectados a Microsoft Graph
    if (Get-Command Get-MgUser -ErrorAction SilentlyContinue) {
        # Obtener usuarios
        $users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, StrongAuthenticationMethods, StrongAuthenticationPhoneAppDetails
        
        # Analizar estado de MFA
        $mfaStatusOutput = "ESTADO DE MFA POR USUARIO:`n`n"
        
        foreach ($user in $users) {
            $mfaStatusOutput += "Usuario: $($user.DisplayName) ($($user.UserPrincipalName))`n"
            
            # Intentar obtener métodos de autenticación
            try {
                $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id
                
                if ($authMethods) {
                    $mfaStatusOutput += "Métodos de autenticación configurados:`n"
                    
                    foreach ($method in $authMethods) {
                        $methodType = $method.AdditionalProperties.'@odata.type'
                        
                        switch -Wildcard ($methodType) {
                            "*microsoftAuthenticatorMethodConfiguration" { $mfaStatusOutput += "  - Microsoft Authenticator`n" }
                            "*phoneAuthenticationMethodConfiguration" { $mfaStatusOutput += "  - Teléfono`n" }
                            "*passwordAuthenticationMethodConfiguration" { $mfaStatusOutput += "  - Contraseña`n" }
                            "*fido2AuthenticationMethodConfiguration" { $mfaStatusOutput += "  - FIDO2 Security Key`n" }
                            "*windowsHelloForBusinessAuthenticationMethodConfiguration" { $mfaStatusOutput += "  - Windows Hello for Business`n" }
                            "*emailAuthenticationMethodConfiguration" { $mfaStatusOutput += "  - Email`n" }
                            "*temporaryAccessPassAuthenticationMethodConfiguration" { $mfaStatusOutput += "  - Temporary Access Pass`n" }
                            "*softwareOathAuthenticationMethodConfiguration" { $mfaStatusOutput += "  - Software OATH Token`n" }
                            default { $mfaStatusOutput += "  - Otro método: $methodType`n" }
                        }
                    }
                    
                    # Determinar si MFA está habilitado
                    $hasMfa = $authMethods | Where-Object { 
                        $_.AdditionalProperties.'@odata.type' -ne "#microsoft.graph.passwordAuthenticationMethod" -and 
                        $_.AdditionalProperties.'@odata.type' -ne $null
                    }
                    
                    if ($hasMfa) {
                        $mfaStatusOutput += "MFA habilitado: Sí`n"
                    }
                    else {
                        $mfaStatusOutput += "MFA habilitado: No`n"
                    }
                }
                else {
                    $mfaStatusOutput += "No se encontraron métodos de autenticación configurados.`n"
                    $mfaStatusOutput += "MFA habilitado: No`n"
                }
            }
            catch {
                $mfaStatusOutput += "Error al obtener métodos de autenticación: $_`n"
            }
            
            $mfaStatusOutput += "---`n"
        }
        
        # Intentar obtener usuarios en riesgo
        try {
            if (Get-Command Get-MgRiskyUser -ErrorAction SilentlyContinue) {
                $riskyUsers = Get-MgRiskyUser -All
                
                if ($riskyUsers.Count -gt 0) {
                    $riskyUsersOutput = "USUARIOS EN RIESGO:`n`n"
                    
                    foreach ($riskyUser in $riskyUsers) {
                        $riskyUsersOutput += "Usuario: $($riskyUser.UserDisplayName) ($($riskyUser.UserPrincipalName))`n"
                        $riskyUsersOutput += "Nivel de riesgo: $($riskyUser.RiskLevel)`n"
                        $riskyUsersOutput += "Estado de riesgo: $($riskyUser.RiskState)`n"
                        $riskyUsersOutput += "Última actualización: $($riskyUser.RiskLastUpdatedDateTime)`n"
                        $riskyUsersOutput += "---`n"
                    }
                }
                else {
                    $riskyUsersOutput = "No se encontraron usuarios en riesgo.`n"
                }
            }
            else {
                $riskyUsersOutput = "No se pudo acceder a la información de usuarios en riesgo. Verifique los permisos de Microsoft Graph.`n"
            }
        }
        catch {
            $riskyUsersOutput = "Error al obtener usuarios en riesgo: $_`n"
        }
        
        Write-Report -Section "CONFIGURACIÓN DE MFA" -Content $mfaStatusOutput
        Write-Report -Section "USUARIOS EN RIESGO" -Content $riskyUsersOutput
        Write-Log "Configuraciones de MFA y seguridad de identidad verificadas correctamente" -Level "INFO"
    }
    else {
        Write-Log "No se pudo acceder a la información de MFA. Verifique los permisos de Microsoft Graph" -Level "WARNING"
        Write-Report -Section "CONFIGURACIÓN DE MFA" -Content "No se pudo acceder a la información de MFA. Verifique los permisos de Microsoft Graph."
    }
}
catch {
    Write-Log "Error al verificar configuraciones de MFA: $_" -Level "ERROR"
    Write-Report -Section "CONFIGURACIÓN DE MFA" -Content "Error al obtener información: $_"
}
#endregion

#region 5. Análisis de Alertas y Registros de Seguridad
Write-Log "5. Analizando alertas y registros de seguridad..." -Level "INFO"

try {
    # Obtener alertas de seguridad de Microsoft Defender for Cloud
    $securityAlerts = Get-AzSecurityAlert
    
    if ($securityAlerts.Count -eq 0) {
        $alertsOutput = "No se encontraron alertas de seguridad activas.`n"
    }
    else {
        $alertsOutput = $securityAlerts | ForEach-Object {
            "ID: $($_.AlertId)`n"
            "Nombre: $($_.AlertDisplayName)`n"
            "Severidad: $($_.AlertSeverity)`n"
            "Estado: $($_.AlertState)`n"
            "Recurso afectado: $($_.CompromisedEntity)`n"
            "Descripción: $($_.AlertDescription)`n"
            "Fecha de detección: $($_.TimeGeneratedUtc)`n"
            "---`n"
        }
    }
    
    # Obtener registros de actividad recientes (últimos 7 días)
    $startTime = (Get-Date).AddDays(-7)
    $endTime = Get-Date
    
    $activityLogs = Get-AzActivityLog -StartTime $startTime -EndTime $endTime
    
    if ($activityLogs.Count -eq 0) {
        $logsOutput = "No se encontraron registros de actividad en los últimos 7 días.`n"
    }
    else {
        # Filtrar eventos relevantes para seguridad
        $securityLogs = $activityLogs | Where-Object { 
            $_.OperationName.Value -like "*security*" -or 
            $_.OperationName.Value -like "*auth*" -or 
            $_.OperationName.Value -like "*role*" -or 
            $_.OperationName.Value -like "*permission*" -or
            $_.OperationName.Value -like "*key*" -or
            $_.OperationName.Value -like "*secret*" -or
            $_.OperationName.Value -like "*vault*" -or
            $_.OperationName.Value -like "*network*" -or
            $_.OperationName.Value -like "*firewall*" -or
            $_.Level -eq "Warning" -or 
            $_.Level -eq "Error"
        }
        
        if ($securityLogs.Count -eq 0) {
            $logsOutput = "No se encontraron registros de actividad relevantes para seguridad en los últimos 7 días.`n"
        }
        else {
            $logsOutput = $securityLogs | ForEach-Object {
                "Operación: $($_.OperationName.Value)`n"
                "Nivel: $($_.Level)`n"
                "Estado: $($_.Status.Value)`n"
                "Iniciador: $($_.Caller)`n"
                "Recurso: $($_.ResourceId)`n"
                "Fecha: $($_.EventTimestamp)`n"
                "---`n"
            }
        }
    }
    
    Write-Report -Section "ALERTAS DE SEGURIDAD" -Content ($alertsOutput -join "`n")
    Write-Report -Section "REGISTROS DE ACTIVIDAD RELEVANTES PARA SEGURIDAD (ÚLTIMOS 7 DÍAS)" -Content ($logsOutput -join "`n")
    Write-Log "Alertas y registros de seguridad analizados correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al analizar alertas y registros de seguridad: $_" -Level "ERROR"
    Write-Report -Section "ALERTAS Y REGISTROS DE SEGURIDAD" -Content "Error al obtener información: $_"
}
#endregion

#region 6. Revisión de Configuraciones de Recursos
Write-Log "6. Revisando configuraciones de recursos..." -Level "INFO"

try {
    # Obtener Network Security Groups
    $nsgs = Get-AzNetworkSecurityGroup
    
    if ($nsgs.Count -eq 0) {
        $nsgsOutput = "No se encontraron Network Security Groups.`n"
    }
    else {
        $nsgsOutput = "NETWORK SECURITY GROUPS:`n`n"
        
        foreach ($nsg in $nsgs) {
            $nsgsOutput += "Nombre: $($nsg.Name)`n"
            $nsgsOutput += "Grupo de recursos: $($nsg.ResourceGroupName)`n"
            $nsgsOutput += "Ubicación: $($nsg.Location)`n"
            $nsgsOutput += "Reglas de seguridad:`n"
            
            # Reglas de seguridad de entrada
            $nsgsOutput += "  Reglas de entrada:`n"
            foreach ($rule in $nsg.SecurityRules | Where-Object { $_.Direction -eq "Inbound" } | Sort-Object Priority) {
                $nsgsOutput += "    - Nombre: $($rule.Name)`n"
                $nsgsOutput += "      Prioridad: $($rule.Priority)`n"
                $nsgsOutput += "      Acceso: $($rule.Access)`n"
                $nsgsOutput += "      Protocolo: $($rule.Protocol)`n"
                $nsgsOutput += "      Dirección: $($rule.Direction)`n"
                $nsgsOutput += "      Origen: $($rule.SourceAddressPrefix -join ', ')`n"
                $nsgsOutput += "      Puerto origen: $($rule.SourcePortRange -join ', ')`n"
                $nsgsOutput += "      Destino: $($rule.DestinationAddressPrefix -join ', ')`n"
                $nsgsOutput += "      Puerto destino: $($rule.DestinationPortRange -join ', ')`n"
                
                # Marcar reglas potencialmente peligrosas
                if (($rule.Access -eq "Allow") -and 
                    (($rule.SourceAddressPrefix -contains "*") -or ($rule.SourceAddressPrefix -contains "Internet") -or ($rule.SourceAddressPrefix -contains "0.0.0.0/0")) -and
                    (($rule.DestinationPortRange -contains "*") -or ($rule.DestinationPortRange -contains "3389") -or ($rule.DestinationPortRange -contains "22"))) {
                    $nsgsOutput += "      ⚠️ ALERTA: Esta regla permite acceso amplio desde Internet a puertos sensibles`n"
                }
                
                $nsgsOutput += "`n"
            }
            
            # Reglas de seguridad de salida
            $nsgsOutput += "  Reglas de salida:`n"
            foreach ($rule in $nsg.SecurityRules | Where-Object { $_.Direction -eq "Outbound" } | Sort-Object Priority) {
                $nsgsOutput += "    - Nombre: $($rule.Name)`n"
                $nsgsOutput += "      Prioridad: $($rule.Priority)`n"
                $nsgsOutput += "      Acceso: $($rule.Access)`n"
                $nsgsOutput += "      Protocolo: $($rule.Protocol)`n"
                $nsgsOutput += "      Dirección: $($rule.Direction)`n"
                $nsgsOutput += "      Origen: $($rule.SourceAddressPrefix -join ', ')`n"
                $nsgsOutput += "      Puerto origen: $($rule.SourcePortRange -join ', ')`n"
                $nsgsOutput += "      Destino: $($rule.DestinationAddressPrefix -join ', ')`n"
                $nsgsOutput += "      Puerto destino: $($rule.DestinationPortRange -join ', ')`n"
                $nsgsOutput += "`n"
            }
            
            $nsgsOutput += "---`n"
        }
    }
    
    # Obtener cuentas de almacenamiento
    $storageAccounts = Get-AzStorageAccount
    
    if ($storageAccounts.Count -eq 0) {
        $storageOutput = "No se encontraron cuentas de almacenamiento.`n"
    }
    else {
        $storageOutput = "CUENTAS DE ALMACENAMIENTO:`n`n"
        
        foreach ($storage in $storageAccounts) {
            $storageOutput += "Nombre: $($storage.StorageAccountName)`n"
            $storageOutput += "Grupo de recursos: $($storage.ResourceGroupName)`n"
            $storageOutput += "Ubicación: $($storage.Location)`n"
            $storageOutput += "Tipo de cuenta: $($storage.Kind)`n"
            $storageOutput += "Nivel de replicación: $($storage.Sku.Name)`n"
            
            # Verificar si HTTPS está habilitado
            $storageOutput += "HTTPS requerido: $($storage.EnableHttpsTrafficOnly)`n"
            
            # Verificar acceso de red
            $storageOutput += "Acceso de red: $($storage.NetworkRuleSet.DefaultAction)`n"
            
            # Verificar si el acceso público está habilitado para blobs
            try {
                $ctx = $storage.Context
                $blobServices = Get-AzStorageBlobServiceProperty -Context $ctx -ErrorAction SilentlyContinue
                
                if ($blobServices) {
                    $storageOutput += "Acceso público a blobs: $($blobServices.PublicAccess)`n"
                    
                    if ($blobServices.PublicAccess -ne "None") {
                        $storageOutput += "⚠️ ALERTA: El acceso público a blobs está habilitado`n"
                    }
                }
                else {
                    $storageOutput += "No se pudo obtener información de acceso público a blobs`n"
                }
            }
            catch {
                $storageOutput += "Error al verificar acceso público a blobs: $_`n"
            }
            
            # Verificar si el firewall está configurado
            if ($storage.NetworkRuleSet.IpRules.Count -gt 0 -or $storage.NetworkRuleSet.VirtualNetworkRules.Count -gt 0) {
                $storageOutput += "Firewall configurado: Sí`n"
                $storageOutput += "  Reglas IP: $($storage.NetworkRuleSet.IpRules.Count)`n"
                $storageOutput += "  Reglas de red virtual: $($storage.NetworkRuleSet.VirtualNetworkRules.Count)`n"
            }
            else {
                $storageOutput += "Firewall configurado: No`n"
            }
            
            $storageOutput += "---`n"
        }
    }
    
    # Obtener máquinas virtuales
    $vms = Get-AzVM
    
    if ($vms.Count -eq 0) {
        $vmsOutput = "No se encontraron máquinas virtuales.`n"
    }
    else {
        $vmsOutput = "MÁQUINAS VIRTUALES:`n`n"
        
        foreach ($vm in $vms) {
            $vmsOutput += "Nombre: $($vm.Name)`n"
            $vmsOutput += "Grupo de recursos: $($vm.ResourceGroupName)`n"
            $vmsOutput += "Ubicación: $($vm.Location)`n"
            $vmsOutput += "Tamaño: $($vm.HardwareProfile.VmSize)`n"
            $vmsOutput += "Sistema operativo: $($vm.StorageProfile.OsDisk.OsType)`n"
            
            # Verificar si el disco está cifrado
            try {
                $encryption = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ErrorAction SilentlyContinue
                
                if ($encryption) {
                    $vmsOutput += "Cifrado de disco OS: $($encryption.OsVolumeEncrypted)`n"
                    $vmsOutput += "Cifrado de disco de datos: $($encryption.DataVolumesEncrypted)`n"
                    
                    if ($encryption.OsVolumeEncrypted -eq "NotEncrypted") {
                        $vmsOutput += "⚠️ ALERTA: El disco del sistema operativo no está cifrado`n"
                    }
                }
                else {
                    $vmsOutput += "No se pudo obtener información de cifrado de disco`n"
                }
            }
            catch {
                $vmsOutput += "Error al verificar cifrado de disco: $_`n"
            }
            
            $vmsOutput += "---`n"
        }
    }
    
    Write-Report -Section "CONFIGURACIÓN DE NETWORK SECURITY GROUPS" -Content $nsgsOutput
    Write-Report -Section "CONFIGURACIÓN DE CUENTAS DE ALMACENAMIENTO" -Content $storageOutput
    Write-Report -Section "CONFIGURACIÓN DE MÁQUINAS VIRTUALES" -Content $vmsOutput
    Write-Log "Configuraciones de recursos revisadas correctamente" -Level "INFO"
}
catch {
    Write-Log "Error al revisar configuraciones de recursos: $_" -Level "ERROR"
    Write-Report -Section "CONFIGURACIÓN DE RECURSOS" -Content "Error al obtener información: $_"
}
#endregion

#region 7. Verificación de Configuraciones de Aplicaciones y APIs Expuestas
Write-Log "7. Verificando configuraciones de aplicaciones y APIs expuestas..." -Level "INFO"

try {
    # Verificar si estamos conectados a Microsoft Graph
    if (Get-Command Get-MgApplication -ErrorAction SilentlyContinue) {
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
                
                # Verificar permisos delegados
                try {
                    $appServicePrincipals = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"
                    
                    if ($appServicePrincipals) {
                        $sp = $appServicePrincipals[0]
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
                        else {
                            $appsOutput += "Permisos delegados: Ninguno`n"
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
                        else {
                            $appsOutput += "Permisos de aplicación: Ninguno`n"
                        }
                    }
                }
                catch {
                    $appsOutput += "Error al obtener permisos: $_`n"
                }
                
                $appsOutput += "---`n"
            }
        }
        
        Write-Report -Section "APLICACIONES Y APIS EXPUESTAS" -Content $appsOutput
        Write-Log "Configuraciones de aplicaciones y APIs expuestas verificadas correctamente" -Level "INFO"
    }
    else {
        Write-Log "No se pudo acceder a la información de aplicaciones. Verifique los permisos de Microsoft Graph" -Level "WARNING"
        Write-Report -Section "APLICACIONES Y APIS EXPUESTAS" -Content "No se pudo acceder a la información de aplicaciones. Verifique los permisos de Microsoft Graph."
    }
}
catch {
    Write-Log "Error al verificar configuraciones de aplicaciones y APIs: $_" -Level "ERROR"
    Write-Report -Section "APLICACIONES Y APIS EXPUESTAS" -Content "Error al obtener información: $_"
}
#endregion

#region 8. Reporte Final
Write-Log "8. Generando reporte final..." -Level "INFO"

try {
    # Generar resumen ejecutivo
    $resumenEjecutivo = @"
RESUMEN EJECUTIVO DE AUDITORÍA DE SEGURIDAD
===========================================

Fecha de auditoría: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Suscripción auditada: $($selectedSubscription.Name)
Usuario que realizó la auditoría: $((Get-AzContext).Account.Id)

HALLAZGOS PRINCIPALES:

1. ROLES Y PERMISOS:
   - Total de asignaciones de roles: $($allRoleAssignments.Count)
   - Roles del usuario actual: $($currentUserRoles.Count)

2. ACCESO CONDICIONAL:
   - Políticas de acceso condicional: $(if ($conditionalAccessPolicies) { $conditionalAccessPolicies.Count } else { "No disponible" })

3. MFA Y SEGURIDAD DE IDENTIDAD:
   - Usuarios sin MFA: $(if ($users) { ($users | Where-Object { -not ($_.StrongAuthenticationMethods) }).Count } else { "No disponible" })
   - Usuarios en riesgo: $(if ($riskyUsers) { $riskyUsers.Count } else { "No disponible" })

4. ALERTAS DE SEGURIDAD:
   - Alertas activas: $(if ($securityAlerts) { $securityAlerts.Count } else { 0 })

5. CONFIGURACIÓN DE RECURSOS:
   - Network Security Groups: $(if ($nsgs) { $nsgs.Count } else { 0 })
   - Cuentas de almacenamiento: $(if ($storageAccounts) { $storageAccounts.Count } else { 0 })
   - Máquinas virtuales: $(if ($vms) { $vms.Count } else { 0 })

6. APLICACIONES Y APIS:
   - Aplicaciones registradas: $(if ($applications) { $applications.Count } else { "No disponible" })

RECOMENDACIONES GENERALES:

1. Revisar las asignaciones de roles para asegurar el principio de mínimo privilegio.
2. Implementar políticas de acceso condicional para todos los usuarios.
3. Habilitar MFA para todos los usuarios, especialmente aquellos con roles privilegiados.
4. Revisar y resolver todas las alertas de seguridad activas.
5. Asegurar que todas las cuentas de almacenamiento tengan el acceso público deshabilitado.
6. Verificar que todas las máquinas virtuales tengan los discos cifrados.
7. Revisar los permisos de las aplicaciones registradas para eliminar permisos innecesarios.

Para más detalles, consulte las secciones específicas de este reporte.
"@

    # Añadir resumen ejecutivo al inicio del reporte
    $reportContent = Get-Content -Path $reportFile -Raw
    $newReportContent = $resumenEjecutivo + "`n`n" + $reportContent
    Set-Content -Path $reportFile -Value $newReportContent
    
    Write-Log "Reporte final generado correctamente en: $reportFile" -Level "INFO"
    Write-Log "Log de la auditoría guardado en: $logFile" -Level "INFO"
    
    # Mostrar ubicación del reporte
    Write-Host "`nLa auditoría de seguridad ha finalizado correctamente." -ForegroundColor Green
    Write-Host "El reporte completo se encuentra en: $reportFile" -ForegroundColor Cyan
    Write-Host "El log de la auditoría se encuentra en: $logFile" -ForegroundColor Cyan
}
catch {
    Write-Log "Error al generar reporte final: $_" -Level "ERROR"
}
#endregion
