function instalar_dhcp {
    # Mostrar IPs actuales con sus interfaces
    Write-Host "La IP actual del equipo es:"
    Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize

    # Obtener la IP actual manualmente configurada
    $IPActual = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq "Manual" -and $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress

    if (-not $IPActual) {
        Write-Host "No hay IP manual configurada actualmente."
        $IPActual = Read-Host "Ingrese la IP que desea usar para el servidor DHCP"
    }

    # Preguntar si el usuario quiere cambiar la IP
    $CambiarIP = Read-Host "¿Desea cambiar la IP del servidor? (S/N)"

    if ($CambiarIP -match "[Ss]") {
        ip-fija  # Llamar a la función para configurar una IP fija
        # Actualizar la IP después del cambio
        $IPActual = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq "Manual" -and $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
    }

    # Verificar si $IPActual tiene valor después del posible cambio
    if (-not $IPActual) {
        Write-Host "No se configuró una IP válida. Saliendo del script..."
        return
    }

    # Configurar la IP fija del servidor DHCP
    $IPFija = $IPActual
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
