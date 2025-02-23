function get-adaptador {
    Write-Host "Configuramos la IP"
    Get-NetAdapter | FT -AutoSize
    $script:interfaz = Read-Host "Introduce la interfaz (findex)"
    $script:nombre = Read-Host "Introduce el nombre (name)"

    Remove-NetIPAddress -InterfaceIndex $interfaz -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $interfaz -Confirm:$false -ErrorAction SilentlyContinue
}

function ip-fija {
    get-adaptador

    $ip = Read-Host "Introduzca la IP"
    $mascara = Read-Host "Introduzca la máscara de red (Ejemplo: 24 para /24)"
    $gateway = Read-Host "Introduzca la puerta de enlace"
    $dns = Read-Host "Introduzca el DNS"
    $dns2 = Read-Host "Introduzca el DNS secundario"

    # Configura IP estática
    New-NetIPAddress -InterfaceIndex $interfaz -IPAddress $ip -PrefixLength $mascara -DefaultGateway $gateway
    Set-DnsClientServerAddress -InterfaceIndex $interfaz -ServerAddresses ($dns, $dns2)
}

function usar-dhcp {
    get-adaptador

    # Activa DHCP en el adaptador seleccionado
    Set-NetIPInterface -InterfaceIndex $interfaz -Dhcp Enabled
    Write-Host "Se ha configurado el adaptador en modo DHCP."
}

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
    New-NetFirewallRule -DisplayName "Permitir Ping" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow

    # Verificar la configuración
    Write-Host "Se ha configurado el servidor DNS correctamente."
    Get-DnsServerZone
}

function instalar_dhcp {
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
}



Write-Output "¿Qué desea hacer?"
write-output "1. Configurar la IP (ponerla fija o activar el DHCP)"
write-output "2. Instalar el servicio de DNS"
Write-Output "3. Instalar el servicio de DHCP"
$eleccion = Read-Host "Eliga una opción"
switch -Wildcard ($eleccion)
{

   1 { 
        # Pregunta si se quiere configurar IP manualmente o usar DHCP
        $opcion = Read-Host "¿Quieres configurar la IP manualmente (1) o activar DHCP (2)?"

        if ($opcion -eq "1") {
            ip-fija
        } elseif ($opcion -eq "2") {
            usar-dhcp
        } else {
            Write-Host "Opción no válida, ejecuta el script nuevamente."
        }
    }

   2 {
        instalar_dns
   }

   3{
    instalar_dhcp
    }
}