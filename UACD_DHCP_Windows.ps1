#Comandos para instalar el servicio y reiniciarlo
Install-WindowsFeature -Name DHCP -IncludeManagementTools

Add-DhcpServerInDC -IPAddress 192.168.1.86
#COmando para añadir un rango, pedira ip inicial, fina, mascara de red etc
Add-DhcpServerv4Scope
Get-DchpServerv4ScopeS

#aqui acompleta los datos faltantes
et-DhcpServerv4optionValue -ScopeId 192.168.1.0 -DnsServer 192.168.1.86


#Para ver las IP que se han dado
Get-DhcpServerv4Lease