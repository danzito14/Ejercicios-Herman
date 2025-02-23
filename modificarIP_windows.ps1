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

 # Pregunta si se quiere configurar IP manualmente o usar DHCP
$opcion = Read-Host "¿Quieres configurar la IP manualmente (1) o activar DHCP (2)?"

if ($opcion -eq "1") {
    ip-fija
} elseif ($opcion -eq "2") {
            usar-dhcp
} else {
    Write-Host "Opción no válida, ejecuta el script nuevamente."
}