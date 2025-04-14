# Script mejorado para comprobar registros DNS sin leases DHCP asociados

# Importar módulos necesarios
Import-Module DhcpServer
Import-Module DnsServer
Import-Module ActiveDirectory

# Variables - ajustar según tu entorno
$dnsServer = "TuDomainController"  # Nombre del servidor DNS para consultar
$zoneName = "tudominio.local"      # Nombre de la zona DNS

# Obtener todos los servidores DHCP autorizados en el dominio
Write-Host "Obteniendo servidores DHCP autorizados en el dominio..." -ForegroundColor Cyan
$dhcpServers = Get-DhcpServerInDC

if ($dhcpServers.Count -eq 0) {
    Write-Host "No se encontraron servidores DHCP autorizados en el dominio." -ForegroundColor Red
    exit
}

Write-Host "Servidores DHCP encontrados: $($dhcpServers.Count)" -ForegroundColor Green
$dhcpServers | ForEach-Object { Write-Host " - $($_.DnsName)" -ForegroundColor Gray }

# Obtener todos los leases DHCP de todos los servidores y todos los scopes
$dhcpLeases = @()

foreach ($dhcpServer in $dhcpServers) {
    $serverName = $dhcpServer.DnsName
    Write-Host "`nObteniendo leases del servidor DHCP: $serverName" -ForegroundColor Cyan
    
    try {
        $allScopes = Get-DhcpServerv4Scope -ComputerName $serverName -ErrorAction Stop
        
        foreach ($scope in $allScopes) {
            Write-Host "Procesando scope $($scope.ScopeId) en $serverName..." -ForegroundColor Gray
            try {
                $scopeLeases = Get-DhcpServerv4Lease -ComputerName $serverName -ScopeId $scope.ScopeId -ErrorAction Stop
                $dhcpLeases += $scopeLeases
                Write-Host " - Leases en este scope: $($scopeLeases.Count)" -ForegroundColor Gray
            }
            catch {
                Write-Host " - Error al obtener leases del scope $($scope.ScopeId): $_" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "Error al conectar con el servidor DHCP $serverName: $_" -ForegroundColor Red
    }
}

$totalLeases = $dhcpLeases.Count
Write-Host "`nTotal de leases DHCP encontrados en todos los servidores: $totalLeases" -ForegroundColor Green

# Obtener todos los registros A de DNS
Write-Host "`nObteniendo registros DNS de $zoneName en $dnsServer..." -ForegroundColor Cyan
$dnsRecords = Get-DnsServerResourceRecord -ComputerName $dnsServer -ZoneName $zoneName -RRType A

Write-Host "Total de registros DNS encontrados: $($dnsRecords.Count)" -ForegroundColor Green

# Crear un hashtable con las IPs de los leases DHCP para búsqueda rápida
$dhcpIpTable = @{}
foreach ($lease in $dhcpLeases) {
    $dhcpIpTable[$lease.IPAddress.ToString()] = $lease
}

# Encontrar registros DNS sin lease DHCP correspondiente
$orphanedDnsRecords = @()

foreach ($dnsRecord in $dnsRecords) {
    # Obtener la dirección IP del registro DNS
    $ipAddress = $dnsRecord.RecordData.IPv4Address.ToString()
    
    # Comprobar si esta IP tiene un lease DHCP
    if (-not $dhcpIpTable.ContainsKey($ipAddress)) {
        $orphanedDnsRecords += $dnsRecord
    }
}

# Mostrar resultados
Write-Host "`nRegistros DNS sin lease DHCP asociado: $($orphanedDnsRecords.Count)" -ForegroundColor Yellow

if ($orphanedDnsRecords.Count -gt 0) {
    Write-Host "`nLista de registros DNS sin lease DHCP:" -ForegroundColor Yellow
    $orphanedDnsRecords | Format-Table HostName, RecordType, @{
        Name = 'IP Address'; 
        Expression = { $_.RecordData.IPv4Address.ToString() }
    } -AutoSize
    
    # Opcionalmente, exportar a CSV
    $csvPath = "$env:USERPROFILE\Desktop\OrphanedDnsRecords.csv"
    $orphanedDnsRecords | Select-Object HostName, RecordType, @{
        Name = 'IPAddress'; 
        Expression = { $_.RecordData.IPv4Address.ToString() }
    } | Export-Csv -Path $csvPath -NoTypeInformation
    
    Write-Host "`nLos resultados también se han exportado a: $csvPath" -ForegroundColor Green
}
else {
    Write-Host "No se encontraron registros DNS sin lease DHCP asociado." -ForegroundColor Green
}
