#!/bin/bash

# Función para obtener el adaptador de red
get_adapter() {
    echo "Configurando la IP"
    # Listar interfaces de red activas
    ip a | grep -oP '^\d+: \K.*(?=:)' 
    read -p "Introduce el nombre del adaptador (por ejemplo: eth0, enp3s0): " interfaz
}

# Función para configurar IP fija
ip_fija() {
    get_adapter

    read -p "Introduzca la IP (Ejemplo: 192.168.1.10): " ip
    read -p "Introduzca la máscara de red (Ejemplo: 24 para /24): " mascara
    read -p "Introduzca la puerta de enlace (Gateway): " gateway
    read -p "Introduzca el DNS primario: " dns
    read -p "Introduzca el DNS secundario: " dns2

    # Configura IP estática
    sudo ip addr flush dev $interfaz
    sudo ip addr add $ip/$mascara dev $interfaz
    sudo ip route add default via $gateway
    sudo resolvectl dns $interfaz $dns $dns2

    echo "IP estática configurada en $interfaz"
}

# Función para activar DHCP
usar_dhcp() {
    get_adapter

    # Activa DHCP en el adaptador seleccionado
    sudo dhclient $interfaz

    echo "Se ha configurado el adaptador $interfaz en modo DHCP."
}

# Menú para preguntar si se desea configurar IP estática o usar DHCP
read -p "¿Quieres configurar la IP manualmente (1) o activar DHCP (2)? " opcion

if [ "$opcion" -eq "1" ]; then
    ip_fija
elif [ "$opcion" -eq "2" ]; then
    usar_dhcp
else
    echo "Opción no válida, ejecuta el script nuevamente."
fi
