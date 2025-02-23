function instalar_dns{
 Write-Host "Instalando el servicio DNS..."

    # Solicitar datos al usuario
    $dominio = Read-Host "Introduce el nombre del dominio (ejemplo: midominio.com)"
    $ipServidor = Read-Host "Introduce la IP del servidor DNS"
    
    # Instalar el servicio DNS
    Install-WindowsFeature -Name DNS -IncludeManagementTools
    
    # Reiniciar servicio para aplicar cambios
    Restart-Service -Name DNS
    
    # Configurar la zona DNS primaria
    Add-DnsServerPrimaryZone -Name $dominio -ZoneFile "$dominio.dns"
    
    # Agregar registros A en la zona DNS
    Add-DnsServerResourceRecordA -IPv4Address $ipServidor -Name "www" -ZoneName $dominio
    Add-DnsServerResourceRecordA -IPv4Address $ipServidor -Name "@" -ZoneName $dominio

    # Reiniciar servicio DNS después de la configuración
    Restart-Service -Name DNS

    # Verificar la configuración
    Write-Host "Se ha configurado el servidor DNS correctamente."
    Get-DnsServerZone
}


