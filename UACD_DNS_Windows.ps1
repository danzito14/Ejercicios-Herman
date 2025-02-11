#Primero instalamos el servicio de DNS
Install-WindowsFeature -Name DNS -IncludeManagementTools

#reiniciamos el servicio
Restart-Service -Name DNS

#Añadimos al servidor dns nuestro dominio en este caso reprobados.com
Add-DnsServerPrimaryZone -Name reprobados.com -ZonaFile reprobados.com.dns

#Luego añadimos un nombre para que se pueda encontrar
Add-DnsServerResourceRecordA -IPv4Address 192.168.1.86 -Name www -ZonaName reprobados.com
Add-DnsServerResourceRecordA -IPv4Address 192.168.1.86 -Name "@" -ZoneName reprobados.com

Restart-Service -Name DNS

#Aqui vemos que se creo corecctamente
Get-DnsServerZone