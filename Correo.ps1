
Install-WindowsFeature -Name DNS -IncludeManagementTools

Write-Output "Descargado hMailServer"
$downlandUrl = "https://www.hmailserver.com/files/hMailServer-5.6.8-B2574.exe"
$installerPath = "C:\hMailServer-5.6.8-B2574.exe"
Invoke-WebRequest -Uri $downlandUrl -OutFile $installerPath

Write-Output "Instalando el hMailServer"
Start-Process -FilePath $installerPath -ArgumentList "/SILENT" -Wait

Write-Output "Descargando thunderbird"
$downlandUrl2 = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/136.0.1/win64/es-ES/Thunderbird%20Setup%20136.0.1.exe"
$installerPath2 = "C:\Thunderbird20Setup20136.0.1.exe"
Invoke-WebRequest -Uri $downlandUrl2 -OutFile $installerPath2

Write-Output "Instalando ThunderBirnd"
Start-Process -FilePath $installerPath2 -ArgumentList "/SILENT" -Wait

# Script para cambiar de IP dinámica (DHCP) a IP fija en Windows

# Solicitar al usuario la interfaz de red y la IP deseada
$interfaceName = Read-Host "Ingrese el nombre de la interfaz de red"
$newIP = Read-Host "Ingrese la nueva IP fija"
$subnetMask = Read-Host "Ingrese la máscara de subred (por ejemplo, 255.255.255.0)"
$gateway = Read-Host "Ingrese la puerta de enlace predeterminada"
$dns = Read-Host "Ingrese el servidor DNS"

# Verificar si la interfaz existe
if (!(Get-NetAdapter -Name $interfaceName -ErrorAction SilentlyContinue)) {
    Write-Output "Error: La interfaz '$interfaceName' no existe."
    exit 1
}

# Cambiar a IP fija
Write-Output "Cambiando la configuración de red..."
try {
    # Desactivar DHCP
    Write-Output "Desactivando DHCP..."
    Set-NetIPInterface -InterfaceAlias $interfaceName -Dhcp Disabled

    # Asignar la nueva IP fija
    Write-Output "Configurando IP fija..."
    New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $newIP -PrefixLength (Test-Connection $gateway -Count 1).Address.length -DefaultGateway $gateway

    # Configurar el servidor DNS
    Write-Output "Configurando servidor DNS..."
    Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses $dns

    Write-Output "Configuración de IP fija completada."
} catch {
    Write-Output "Error al cambiar la configuración de IP: $_"
}


