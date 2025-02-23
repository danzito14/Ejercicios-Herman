#!/bin/bash

# Función para instalar y configurar el servicio DNS
configurar_dns() {
    read -p "Ingrese la IP del servidor DNS: " IP_SERVIDOR
    read -p "Ingrese el nombre del dominio (ejemplo: midominio.com): " DOMINIO
    
    # Obtener la red base eliminando el último octeto
    RED_BASE=$(echo $IP_SERVIDOR | awk -F '.' '{print $1"."$2"."$3".0"}')
    
    # Construir la zona inversa eliminando el último octeto e invirtiendo los demás
    ZONA_INVERSA=$(echo $RED_BASE | awk -F '.' '{print $3"."$2"."$1}')
    
    echo "La IP del servidor es: $IP_SERVIDOR"
    echo "Zona inversa generada: $ZONA_INVERSA.in-addr.arpa"
    
    # Instalamos el servicio DNS sin pedir confirmación
    sudo apt install -y bind9 bind9-utils
    sudo ufw allow bind9
    
    # Configuración en named.conf.options
    sudo sed -i 's/listen-on-v6 { any; };/listen-on { any; };/g' /etc/bind/named.conf.options
    sudo sed -i 's/dnssec-validation auto;/dnssec-validation no;/' /etc/bind/named.conf.options
    sudo sed -i 's/-u bind"/-u bind -4"/' /etc/default/named
    
    # Reiniciar servicio
    sudo systemctl restart bind9
    
    # Crear carpeta para zonas si no existe
    sudo mkdir -p /etc/bind/zonas
    
    # Configurar named.conf.local con el dominio ingresado
    sudo tee /etc/bind/named.conf.local > /dev/null <<EOL
zone "$DOMINIO" IN {
    type master;
    file "/etc/bind/zonas/db.$DOMINIO";
};

zone "$ZONA_INVERSA.in-addr.arpa" IN {
    type master;
    file "/etc/bind/zonas/db.$ZONA_INVERSA";
};
EOL
    
    # Crear archivo de zona directa
    sudo tee /etc/bind/zonas/db.$DOMINIO > /dev/null <<EOL
;
; BIND data file for $DOMINIO
;
\$TTL    604800
@       IN      SOA     servidor.$DOMINIO. admin.$DOMINIO. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
        IN      NS      servidor.$DOMINIO.
servidor IN      A       $IP_SERVIDOR
www      IN      CNAME   servidor.$DOMINIO.
EOL
    
    # Crear archivo de zona inversa
    sudo tee /etc/bind/zonas/db.$ZONA_INVERSA > /dev/null <<EOL
;
; BIND data file for reverse lookup zone
;
\$TTL    604800
@       IN      SOA     $DOMINIO. admin.$DOMINIO. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
        IN      NS      servidor.$DOMINIO.
$(echo $IP_SERVIDOR | awk -F '.' '{print $4}')      IN      PTR     servidor.$DOMINIO.
EOL
    
    # Verificar configuración y reiniciar servicio
    sudo named-checkconf
    sudo named-checkzone $DOMINIO /etc/bind/zonas/db.$DOMINIO
    sudo named-checkzone $ZONA_INVERSA.in-addr.arpa /etc/bind/zonas/db.$ZONA_INVERSA
    sudo systemctl restart bind9
}




instalar_dhcp_server() {
    # Expresión Regular para validar IPs
    Regx="^((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0]?[0-9]?[0-9]))\.((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0]?[0-9]?[0-9]))\.((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0]?[0-9]?[0-9]))\.((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0]?[0-9]?[0-9]))$"

    # Instalar el servidor DHCP si no está instalado
    sudo apt-get install -y isc-dhcp-server

    # Solicitar la IP fija del servidor
    echo "Ingrese la IP fija del servidor DHCP"
    IPFija=""
    while [[ ! $IPFija =~ $Regx ]]; do
        read IPFija
        if [[ ! $IPFija =~ $Regx ]]; then
           echo "La IP no tiene el formato correcto, favor de ingresarla correctamente"
        fi
    done

    # Obtener la subred automáticamente
    Subred="$(echo $IPFija | awk -F. '{print $1"."$2"."$3}')"

    # Solicitar el rango de IPs para asignar dentro de la misma subred
    echo "Ingrese la IP de rango inicial (Debe estar en $Subred.X)"
    IP_inicial=""
    while [[ ! $IP_inicial =~ $Regx || $IP_inicial != $Subred.* ]]; do
        read IP_inicial 
        if [[ ! $IP_inicial =~ $Regx || $IP_inicial != $Subred.* ]]; then
           echo "La IP no es válida o no está dentro de la subred $Subred.X, ingrésela nuevamente"
        fi
    done

    echo "Ingrese la IP de rango final (Debe estar en $Subred.X)"
    IP_final=""
    while [[ ! $IP_final =~ $Regx || $IP_final != $Subred.* ]]; do
        read IP_final
        if [[ ! $IP_final =~ $Regx || $IP_final != $Subred.* ]]; then
           echo "La IP no es válida o no está dentro de la subred $Subred.X, ingrésela nuevamente"
        fi
    done

    # Detectar automáticamente la interfaz de red activa
    INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(e|w)' | head -n 1)
    if [[ -z "$INTERFACE" ]]; then
        echo "No se detectó una interfaz de red válida. Especifique manualmente en /etc/default/isc-dhcp-server."
        exit 1
    fi

    # Configurar DHCP
    sudo tee /etc/dhcp/dhcpd.conf > /dev/null <<EOL
option domain-name "example.org";
option domain-name-servers $IPFija;
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;

subnet $Subred.0 netmask 255.255.255.0 {
        range $IP_inicial $IP_final;
        option subnet-mask 255.255.255.0;
        option routers $Subred.1;
        option broadcast-address $Subred.255;
}
EOL

    # Configurar la interfaz de red en el DHCP
    sudo tee /etc/default/isc-dhcp-server > /dev/null <<EOL
INTERFACESv4="$INTERFACE"
INTERFACESv6=""
EOL

    # Reiniciar y habilitar el servicio DHCP
    sudo systemctl restart isc-dhcp-server
    sudo systemctl enable isc-dhcp-server

    echo "Instalación y configuración del Servidor DHCP completada con éxito."
}

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

echo "Seleccione una opción:"
echo "1. Configurar la IP (ponerla fija o activar el DHCP)"
echo "2. Instalar el servicio de DNS"
echo "3. Instalar el servicio de DHCP "
read -p "Eliga una opción: " opcion

# Switch en Bash usando 'case'
case $opcion in
    1)
        read -p "¿Quieres configurar la IP manualmente (1) o activar DHCP (2)? " opcion

        if [ "$opcion" -eq "1" ]; then
            ip_fija
        elif [ "$opcion" -eq "2" ]; then
            usar_dhcp
        else
            echo "Opción no válida, ejecuta el script nuevamente."
        fi
        ;;
    2)
        configurar_dns
        ;;
    3)
       instalar_dhcp_server
        ;;
    *)
        echo "Opción no válida"
        ;;
esac

