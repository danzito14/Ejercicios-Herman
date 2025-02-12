#Comandos para instalar el servicio y reiniciarlo
Install-WindowsFeature -Name DHCP -IncludeManagementTools

#Instalamos RSAT AD PowerShell, que es Remote Server Administration Tools, algunas veces no viene instalado por defecto
Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature

#Instalamos las herramientas para crear un dominio
Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature
Install-ADDForest -DomainName "midominio.com"

Get-ADDomain

Add-DhcpServerInDC -DnsName WIN-9LSTNUINFQG.midominio.local -IPAddress 192.168.1.8

Add-DhcpServerv4Scope

Get-DhcpServerv4Scope

Set-DhcpServerv4optionValue -ScopeId 192.168.1.0 -DnsServer 192.168.1.86 -DnsDomain midominio.local -Router 192.168.1.8

#Para ver las IP que se han dado
Get-DhcpServerv4Lease