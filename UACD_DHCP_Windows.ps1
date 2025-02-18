# Solicitar la IP fija del servidor DHCP
$IPFija = Read-Host "Ingrese la IP fija"

# Obtener la subred automáticamente
$Subred = $IPFija -replace "\.\d+$", ".0"

# Instalar el servicio DHCP con herramientas de administración
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# Registrar el servidor DHCP en el dominio
Add-DhcpServerInDC -IPAddress $IPFija

# Solicitar el rango de IPs para asignar
$IPInicio = Read-Host "Ingrese la IP de rango inicial"
$IPFinal = Read-Host "Ingrese la IP de rango final"

# Crear el ámbito DHCP con la IP fija ingresada
Add-DhcpServerv4Scope -StartRange $IPInicio -EndRange $IPFinal -SubnetMask 255.255.255.0 -State Active

# Configurar opciones del servidor (DNS y puerta de enlace)
Set-DhcpServerv4OptionValue -ScopeId $Subred -DnsServer $IPFija -Router $IPFija

# Reiniciar el servicio DHCP
Restart-Service dhcpserver

# Mostrar las IPs asignadas por el servidor
Write-Host "Mostrando las IPs asignadas por el servidor DHCP:"
Get-DhcpServerv4Lease
