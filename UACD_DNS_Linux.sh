#!/bin/bash

# Instalamos el servicio DNS sin pedir confirmación
sudo apt install -y bind9 bind9-utils
sudo ufw allow bind9
sudo systemctl status bind9

# Variable que guarda la dirección
archivo="/etc/bind/named.conf.options"

# Ingresamos la configuración
sudo sed -i 's/listen-on-v6 { any; };/listen-on { any; };\n    allow-query { localhost; 192.168.1.0\/24; };\n    forwarders {\n 192.168.1.86;\n    };/' /etc/bind/named.conf.options

sudo sed -i 's/dnssec-validation auto;/dnssec-validation no;/' /etc/bind/named.conf.options

# Configuramos solo para IPv4
sudo sed -i 's/-u bind"/-u bind -4"/' /etc/default/named
sudo named-checkconf
sudo systemctl restart bind9
sudo systemctl status bind9

# Ahora agregamos las zonas
sudo mkdir -p /etc/bind/zonas

sudo tee -a /etc/bind/named.conf.local > /dev/null <<EOL
zone "reprobados.com" IN {
    type master;
    file "/etc/bind/zonas/db.reprobados.com";
};

zone "1.168.192.in-addr.arpa" IN {
    type master;
    file "/etc/bind/zonas/db.1.168.192";
};
EOL

# Creación del archivo de zona directa
sudo cp /etc/bind/db.local /etc/bind/zonas/db.reprobados.com

sudo sed -i 's/localhost. root.localhost./servidor.reprobados.com. root.reprobados.com./' /etc/bind/zonas/db.reprobados.com

# Modificamos el archivo de zona para incluir www.reprobados.com
sudo sed -i ':a;N;$!ba; s/@\s\+IN\s\+NS\s\+localhost\.\n@\s\+IN\s\+A\s\+127.0.0.1\n@\s\+IN\s\+AAAA\s\+::1/@       IN      NS      servidor.reprobados.com.\nservidor       IN      A       192.168.1.86\nwww            IN      CNAME   servidor.reprobados.com.\nequipo01       IN      A       192.168.1.86\nreprobadosc     IN      CNAME   servidor.reprobados.com./' /etc/bind/zonas/db.reprobados.com

# Ahora de la zona inversa
sudo cp /etc/bind/zonas/db.reprobados.com /etc/bind/zonas/db.1.168.192

# Configuración de la zona inversa
sudo tee /etc/bind/zonas/db.1.168.192 > /dev/null <<EOL
;
; BIND data file for reverse lookup zone
;
\$TTL    604800
@       IN      SOA     reprobados.com. admin.reprobados.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
        IN      NS      servidor.reprobados.com.
86      IN      PTR     servidor.reprobados.com.
EOL

# Comprobamos la configuración
sudo named-checkconf /etc/bind/named.conf.local
sudo named-checkzone reprobados.com /etc/bind/zonas/db.reprobados.com
sudo named-checkzone 1.168.192.in-addr.arpa /etc/bind/zonas/db.1.168.192

# Reiniciamos bind9
sudo systemctl restart bind9
sudo systemctl status bind9
