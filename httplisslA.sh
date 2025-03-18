#!/bin/bash

# Instalación de vsftpd
VSFTPD_CONF="/etc/vsftpd.conf"
echo "Instalando vsftpd..."
sudo apt update && sudo apt install vsftpd openssl -y

# Creación de grupos
echo "Preparando todo"
sudo groupadd Reprobados
sudo groupadd Recursadores

# Creación de directorios FTP
echo "Creando estructura de directorios..."
sudo mkdir -p /srv/ftp/{Publico,Reprobados,Recursadores,usuarios}
sudo mkdir -p /srv/ftp/public/Publico

# Enlazar carpetas públicas
echo "Configurando enlaces de carpetas..."
mount --bind /srv/ftp/public/Publico /srv/ftp/Publico
echo "/srv/ftp/public/Publico /srv/ftp/Publico none bind 0 0" | sudo tee -a /etc/fstab

# Configuración de permisos
echo "Configurando permisos..."
sudo chmod -R 777 /srv/ftp/Publico
sudo chmod -R 755 /srv/ftp/usuarios
sudo chown -R :Reprobados /srv/ftp/Reprobados
sudo chmod -R 775 /srv/ftp/Reprobados
sudo chown -R :Recursadores /srv/ftp/Recursadores
sudo chmod -R 775 /srv/ftp/Recursadores
sudo chmod -R g+s /srv/ftp/Reprobados
sudo chmod -R g+s /srv/ftp/Recursadores

# Preguntar si se desea configurar SSL
read -p "¿Desea configurar SSL para vsftpd? (s/n): " SSL_CONFIRM
if [[ "$SSL_CONFIRM" == "s" || "$SSL_CONFIRM" == "S" ]]; then
    echo "Generando certificado SSL..."
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem \
      -subj "/C=MX/ST=Estado/L=Ciudad/O=Empresa/OU=Departamento/CN=ftp.example.com"

    echo "Configurando vsftpd con SSL..."
    cat <<EOF | sudo tee /etc/vsftpd.conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=002
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
anon_root=/srv/ftp/public

chroot_local_user=YES
allow_writeable_chroot=YES
user_sub_token=\$USER
local_root=/srv/ftp/usuarios/\$USER

pasv_min_port=30000
pasv_max_port=30100

ssl_enable=YES
rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem
force_local_logins_ssl=YES
force_local_data_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH
EOF
else
    echo "Configuración SSL omitida."
fi

# Configuración del firewall
echo "Configurando firewall..."
sudo ufw allow 20,21/tcp
sudo ufw allow 30000:30100/tcp
sudo ufw --force enable

# Reiniciar y habilitar vsftpd
echo "Reiniciando servicio vsftpd..."
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd

echo "Instalación y configuración de vsftpd completada."
