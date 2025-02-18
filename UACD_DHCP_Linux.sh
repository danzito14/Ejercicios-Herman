#!/bin/bash

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
