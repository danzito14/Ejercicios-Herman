New-NetFirewallRule -DisplayName "Permitir Ping" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow

# Instalar el servicio DNS junto con las herramientas de administración
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Configurar una dirección IP fija para el servidor
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.86 -PrefixLength 24 -DefaultGateway 192.168.1.1

# Reiniciar el servicio DNS para aplicar los cambios
Restart-Service -Name DNS

# Crear una zona DNS primaria para el dominio "reprobados.com"
Add-DnsServerPrimaryZone -Name reprobados.com -ZoneFile reprobados.com.dns

# Agregar registros A para resolver nombres dentro del dominio
Add-DnsServerResourceRecordA -IPv4Address 192.168.1.86 -Name www -ZoneName reprobados.com
Add-DnsServerResourceRecordA -IPv4Address 192.168.1.86 -Name "@" -ZoneName reprobados.com

# Reiniciar el servicio DNS nuevamente para aplicar la configuración
Restart-Service -Name DNS

# Verificar que la zona DNS se haya creado correctamente
Get-DnsServerZone

Get-NetFirewallRule -DisplayName "Permitir Ping" | Format-Table Name, DisplayName, Enabled, Action
