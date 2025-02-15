#!/bin/bash

# Expresión Regxular para validar IPs
Regx="^((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0]?[0-9]?[0-9]))\.((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0]?[0-9]?[0-9]))\.((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0]?[0-9]?[0-9]))\.((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([0]?[0-9]?[0-9]))$"

# Instalar el servidor DHCP si no está instalado
sudo apt-get install -y isc-dhcp-server

IP_LOCAL=$(hostname -I | awk '{print $1}')
echo "Ingrese la IP de rango inicial, que conincida con su IP $IP_LOCAL "
IP_inicial=""
while [[ ! $IP_inicial =~ $Regx || ! $IP_inicial =~ ^192\.168\.1\.[0-9]+$ ]]; do
    read IP_inicial 
    if [[ ! $IP_inicial =~ $Regx || ! $IP_inicial =~ ^192\.168\.1\.[0-9]+$ ]]; then
       echo "La IP no tiene el formato correcto o no está en el rango 192.168.1.x, favor de ingresarla correctamente"
    fi
done

echo "Ingrese la IP de rango final (debe estar en 192.168.1.x)"
IP_final=""
while [[ ! $IP_final =~ $Regx || ! $IP_final =~ ^192\.168\.1\.[0-9]+$ ]]; do
    read IP_final
    if [[ ! $IP_final =~ $Regx || ! $IP_final =~ ^192\.168\.1\.[0-9]+$ ]]; then
       echo "La IP no tiene el formato correcto o no está en el rango 192.168.1.x, favor de ingresarla correctamente"
    fi
done

# Configurar DHCP
sudo tee /etc/dhcp/dhcpd.conf > /dev/null <<EOL
option domain-name "example.org";
option domain-name-servers 192.168.1.86;
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;

subnet 192.168.1.0 netmask 255.255.255.0 {
        range $IP_inicial $IP_final;
        option subnet-mask 255.255.255.0;
        option routers 192.168.1.254;
        option broadcast-address 192.168.1.255;
}
EOL

# Configurar la interfaz de red utilizada por el DHCP (verifica tu interfaz con 'ip a')
sudo tee /etc/default/isc-dhcp-server > /dev/null <<EOL
INTERFACESv4="enp0s3"
INTERFACESv6=""
EOL

# Reiniciar el servicio DHCP
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

echo "Se ha terminado la instalacion del Servidor DHCP"

