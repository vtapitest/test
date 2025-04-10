<#
.SYNOPSIS
    Script para determinar si los usuarios de Active Directory tienen su buzón en Exchange On-Premises o en Exchange Online.

.DESCRIPTION
    Este script analiza los atributos de Exchange de los usuarios de Active Directory para determinar
    la ubicación de sus buzones en un entorno híbrido (Exchange On-Premises y Exchange Online).
    Clasifica a cada usuario según sus atributos y exporta los resultados a un archivo CSV.

.PARAMETER OutputPath
    Ruta completa donde se guardará el archivo CSV. Si no se especifica, se guardará en el directorio actual.

.EXAMPLE
    .\Get-MailboxLocation.ps1
    Ejecuta el script y guarda el CSV en el directorio actual.

.EXAMPLE
    .\Get-MailboxLocation.ps1 -OutputPath "C:\Informes\estado_buzones.csv"
    Ejecuta el script y guarda el CSV en la ruta especificada.

.NOTES
    Nombre: Get-MailboxLocation.ps1
    Autor: v0 Assistant
    Fecha: 10/04/2025
    Requisitos: PowerShell 5.1 o superior, Módulo ActiveDirectory
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ""
)

# Importar el módulo de Active Directory
Import-Module ActiveDirectory

# Función para interpretar el valor de msExchRecipientTypeDetails
function Get-RecipientTypeInterpretation {
    param (
        [Parameter(Mandatory=$false)]
        [Nullable[long]]$RecipientTypeDetails
    )

    if ($null -eq $RecipientTypeDetails) {
        return "No definido"
    }

    switch ($RecipientTypeDetails) {
        # Buzones locales (On-Premises)
        1 { return "UserMailbox" }
        2 { return "LinkedMailbox" }
        4 { return "SharedMailbox" }
        16 { return "RoomMailbox" }
        32 { return "EquipmentMailbox" }
        128 { return "MailUser" }
        
        # Buzones remotos (Exchange Online)
        2147483648 { return "RemoteUserMailbox" }
        8589934592 { return "RemoteRoomMailbox" }
        17179869184 { return "RemoteEquipmentMailbox" }
        34359738368 { return "RemoteSharedMailbox" }
        
        default { return "Otro ($RecipientTypeDetails)" }
    }
}

# Función para clasificar la ubicación del buzón con verificaciones adicionales
function Get-MailboxLocation {
    param (
        [Parameter(Mandatory=$false)]
        [Nullable[long]]$RecipientTypeDetails,
        
        [Parameter(Mandatory=$false)]
        [string]$Mail,
        
        [Parameter(Mandatory=$false)]
        [string[]]$ProxyAddresses,
        
        [Parameter(Mandatory=$false)]
        [string]$TargetAddress,
        
        [Parameter(Mandatory=$false)]
        [string]$RemoteRoutingAddress,
        
        [Parameter(Mandatory=$false)]
        [string]$HomeMDB,
        
        [Parameter(Mandatory=$false)]
        [string]$HomeServerName,
        
        [Parameter(Mandatory=$false)]
        [byte[]]$MailboxGuid,
        
        [Parameter(Mandatory=$false)]
        [Nullable[int]]$RemoteRecipientType,
        
        [Parameter(Mandatory=$false)]
        [string]$ExchangeVersion,
        
        [Parameter(Mandatory=$false)]
        [string]$LegacyExchangeDN
    )

    # Valores para buzones locales (On-Premises)
    $onPremValues = @(1, 2, 4, 16, 32)
    
    # Valores para buzones remotos (Exchange Online)
    $onlineValues = @(2147483648, 8589934592, 17179869184, 34359738368)

    # Verificación principal basada en msExchRecipientTypeDetails
    if ($null -ne $RecipientTypeDetails) {
        if ($onPremValues -contains $RecipientTypeDetails) {
            return "Exchange On-Premises"
        }
        elseif ($onlineValues -contains $RecipientTypeDetails) {
            # Verificación adicional para Exchange Online
            if ($TargetAddress -match "\.mail\.onmicrosoft\.com$" -or $RemoteRoutingAddress -match "\.mail\.onmicrosoft\.com$") {
                return "Exchange Online (Verificado)"
            }
            return "Exchange Online"
        }
        elseif ($RecipientTypeDetails -eq 128) {
            return "Sin buzón (MailUser)"
        }
    }
    else {
        # Verificaciones adicionales cuando msExchRecipientTypeDetails es nulo
        
        # Verificación 1: Si no tiene ningún atributo de correo, es "Sin buzón"
        if ([string]::IsNullOrEmpty($Mail) -and 
            ($null -eq $ProxyAddresses -or $ProxyAddresses.Count -eq 0) -and 
            [string]::IsNullOrEmpty($TargetAddress)) {
            return "Sin buzón"
        }
        
        # Verificación 2: Comprobar atributos específicos de Exchange On-Premises
        if (-not [string]::IsNullOrEmpty($HomeMDB) -or -not [string]::IsNullOrEmpty($HomeServerName)) {
            return "Exchange On-Premises (por HomeMDB/HomeServer)"
        }
        
        # Verificación 3: Comprobar si tiene un GUID de buzón
        if ($null -ne $MailboxGuid -and $MailboxGuid.Length -gt 0) {
            # Si tiene GUID de buzón pero no tiene HomeMDB, podría ser Exchange Online
            if ([string]::IsNullOrEmpty($HomeMDB) -and [string]::IsNullOrEmpty($HomeServerName)) {
                # Buscar pistas adicionales para Exchange Online
                if ($ProxyAddresses -match "\.onmicrosoft\.com$" -or $TargetAddress -match "\.onmicrosoft\.com$") {
                    return "Exchange Online (por MailboxGuid y dominio)"
                }
                return "Probable Exchange Online (por MailboxGuid)"
            }
            return "Probable Exchange On-Premises (por MailboxGuid)"
        }
        
        # Verificación 4: Comprobar RemoteRecipientType
        if ($null -ne $RemoteRecipientType) {
            # RemoteRecipientType = 1 (ProvisionedMailbox) o 4 (Migrated)
            if ($RemoteRecipientType -eq 1 -or $RemoteRecipientType -eq 4) {
                return "Exchange Online (por RemoteRecipientType)"
            }
        }
        
        # Verificación 5: Buscar dominios onmicrosoft.com en proxyAddresses
        if ($null -ne $ProxyAddresses) {
            foreach ($address in $ProxyAddresses) {
                if ($address -match "\.onmicrosoft\.com$") {
                    return "Probable Exchange Online (por dominio onmicrosoft.com)"
                }
            }
        }
        
        # Verificación 6: Comprobar LegacyExchangeDN
        if (-not [string]::IsNullOrEmpty($LegacyExchangeDN)) {
            if ($LegacyExchangeDN -match "/o=ExchangeLabs/") {
                return "Probable Exchange Online (por LegacyExchangeDN)"
            }
            elseif ($LegacyExchangeDN -match "/o=") {
                return "Probable Exchange On-Premises (por LegacyExchangeDN)"
            }
        }
        
        # Si llegamos aquí, sigue siendo indeterminado pero con atributos de correo
        return "Indeterminado (con atributos de correo)"
    }

    return "Indeterminado"
}

# Determinar la ruta para el archivo CSV de salida
if ([string]::IsNullOrEmpty($OutputPath)) {
    # Usar el directorio de trabajo actual (donde se ejecuta el script)
    $currentPath = (Get-Location).Path
    $csvPath = Join-Path -Path $currentPath -ChildPath "estado_buzones.csv"
} else {
    $csvPath = $OutputPath
    
    # Verificar si la carpeta existe, si no, crearla
    $directory = Split-Path -Path $csvPath -Parent
    if (!(Test-Path -Path $directory -PathType Container) -and $directory -ne "") {
        try {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
            Write-Host "Se ha creado el directorio: $directory" -ForegroundColor Yellow
        } catch {
            Write-Host "Error al crear el directorio: $($_.Exception.Message)" -ForegroundColor Red
            exit
        }
    }
}

# Obtener todos los usuarios de Active Directory con los atributos necesarios (ampliados)
Write-Host "Obteniendo usuarios de Active Directory..." -ForegroundColor Cyan
$users = Get-ADUser -Filter * -Properties DisplayName, SamAccountName, mail, msExchRecipientTypeDetails, 
    proxyAddresses, targetAddress, msExchRemoteRecipientType, homeMDB, msExchHomeMDBBL, 
    msExchHomeServerName, msExchMailboxGuid, msExchVersion, legacyExchangeDN

# Crear un array para almacenar los resultados
$results = @()

# Procesar cada usuario
$totalUsers = $users.Count
$currentUser = 0

foreach ($user in $users) {
    $currentUser++
    Write-Progress -Activity "Analizando usuarios" -Status "$currentUser de $totalUsers" -PercentComplete (($currentUser / $totalUsers) * 100)
    
    # Obtener la interpretación del tipo de recipiente
    $recipientTypeInterpretation = Get-RecipientTypeInterpretation -RecipientTypeDetails $user.msExchRecipientTypeDetails
    
    # Obtener la dirección de enrutamiento remoto (si existe)
    $remoteRoutingAddress = $user.proxyAddresses | Where-Object { $_ -match "^SMTP:.*\.mail\.onmicrosoft\.com$" } | Select-Object -First 1
    if ($remoteRoutingAddress) {
        $remoteRoutingAddress = $remoteRoutingAddress.Substring(5) # Quitar el prefijo "SMTP:"
    }
    
    # Clasificar la ubicación del buzón con verificaciones adicionales
    $mailboxLocation = Get-MailboxLocation -RecipientTypeDetails $user.msExchRecipientTypeDetails `
                                          -Mail $user.mail `
                                          -ProxyAddresses $user.proxyAddresses `
                                          -TargetAddress $user.targetAddress `
                                          -RemoteRoutingAddress $remoteRoutingAddress `
                                          -HomeMDB $user.homeMDB `
                                          -HomeServerName $user.msExchHomeServerName `
                                          -MailboxGuid $user.msExchMailboxGuid `
                                          -RemoteRecipientType $user.msExchRemoteRecipientType `
                                          -ExchangeVersion $user.msExchVersion `
                                          -LegacyExchangeDN $user.legacyExchangeDN
    
    # Crear un objeto personalizado para este usuario
    $userObject = [PSCustomObject]@{
        Nombre = $user.DisplayName
        SamAccountName = $user.SamAccountName
        Mail = $user.mail
        msExchRecipientTypeDetails = $user.msExchRecipientTypeDetails
        Interpretacion = $recipientTypeInterpretation
        Clasificacion = $mailboxLocation
        TargetAddress = $user.targetAddress
        RemoteRoutingAddress = $remoteRoutingAddress
        HomeMDB = $user.homeMDB
        HomeServerName = $user.msExchHomeServerName
        TieneMailboxGuid = if ($null -ne $user.msExchMailboxGuid -and $user.msExchMailboxGuid.Length -gt 0) { "Sí" } else { "No" }
        RemoteRecipientType = $user.msExchRemoteRecipientType
        LegacyExchangeDN = $user.legacyExchangeDN
    }
    
    # Agregar el objeto al array de resultados
    $results += $userObject
}

# Mostrar los resultados en formato de tabla
Write-Host "`nResultados del análisis:" -ForegroundColor Green
$results | Format-Table -Property Nombre, SamAccountName, Mail, msExchRecipientTypeDetails, Interpretacion, Clasificacion -AutoSize

# Exportar los resultados a un archivo CSV
try {
    $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nLos resultados han sido exportados a: $csvPath" -ForegroundColor Yellow
} catch {
    Write-Host "`nError al exportar el archivo CSV: $($_.Exception.Message)" -ForegroundColor Red
}

# Mostrar un resumen
$summary = $results | Group-Object -Property Clasificacion | Select-Object Name, Count
Write-Host "`nResumen por clasificación:" -ForegroundColor Cyan
$summary | Format-Table -AutoSize
