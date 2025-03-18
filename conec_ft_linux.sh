#!/bin/bash

# Datos de conexión
FTP_USER="user"
FTP_PASS="Repro1*3"
FTP_SERVER="192.168.1.83"

# Ruta base
BASE_PATH="/Servicios_http/linux"

# Directorios disponibles
DIRS=("Apache" "Nginx" "Tomcat")

# Crear carpeta local para descargas
DOWNLOAD_DIR="/tmp"

Puerto() {
    local port
    local puertos_ocupados=(20 21 22 23 25 53 67 68 80 87 110 123 143 161 389 443 445 465 587 993 995 3306 3389 5432 5900 6379)

    sudo ufw status | grep -q "inactive" && sudo ufw enable > /dev/null

    while true; do
        read -p "Ingrese un puerto: " port
        [[ $port =~ ^[0-9]+$ ]] || continue
        ((port < 1 || port > 65535)) && continue
        [[ " ${puertos_ocupados[*]} " =~ " $port " ]] && continue
        sudo ss -tuln | grep -q ":$port " && continue
        break
    done

    sudo ufw allow $port/tcp > /dev/null
    echo "$port"
}


InstalarApache(){
        cd "./descargas_ftp"
        puerto=$(Puerto)
        echo "Configurando Apache"
        tar -xzf "/tmp/Apache-$1.tar.gz" -C /tmp
        cd "/tmp/httpd-$1" || exit 1
        ./configure --prefix=/usr/local/apache2 --enable-so > /dev/null
        echo "puerto $puerto"
        make > /dev/null
        sudo make install > /dev/null
    
        sudo sed -i "s/Listen 80/Listen $puerto/" /usr/local/apache2/conf/httpd.conf
        sudo sed -i "s/#ServerName www.example.com:80/ServerName localhost:$puerto/" /usr/local/apache2/conf/httpd.conf

        sudo /usr/local/apache2/bin/apachectl start
        echo "Apache instalado accede a el desde http://localhost:$puerto."
        while true; do
            read -p "¿Quiere configurar el SSL? (s/n): " opcion_ssl

            if [[ "$opcion_ssl" == "s" ]]; then
                portssl=$(Puerto)

                echo "Configurando módulo SSL en Apache..."
                sudo sed -i "s/#LoadModule ssl_module modules\\/mod_ssl.so/LoadModule ssl_module modules\\/mod_ssl.so/" /usr/local/apache2/conf/httpd.conf
                sudo sed -i "s/#Include conf\\/extra\\/httpd-ssl.conf/Include conf\\/extra\\/httpd-ssl.conf/" /usr/local/apache2/conf/httpd.conf
                sudo sed -i "s/#LoadModule socache_shmcb_module modules\\/mod_socache_shmcb.so/LoadModule socache_shmcb_module modules\\/mod_socache_shmcb.so/" /usr/local/apache2/conf/httpd.conf

                echo "Ajustando configuración en httpd-ssl.conf..."
                sudo sed -i "s/^Listen 443/Listen $portssl/" /usr/local/apache2/conf/extra/httpd-ssl.conf
                sudo sed -i "s/^ServerName .*/ServerName localhost:$portssl/" /usr/local/apache2/conf/extra/httpd-ssl.conf
                sudo sed -i "s/<VirtualHost _default_:443>/<VirtualHost _default_:$portssl>/" /usr/local/apache2/conf/extra/httpd-ssl.conf

                echo "Copiando certificados desde el escritorio..."
                sudo cp /home/urielcaro/Desktop/server.key /usr/local/apache2/conf/
                sudo cp /home/urielcaro/Desktop/server.crt /usr/local/apache2/conf/

                echo "Abriendo puerto SSL en firewall..."
                sudo ufw allow "$portssl"/tcp > /dev/null

                echo "Reiniciando Apache con soporte SSL..."
                sudo /usr/local/apache2/bin/apachectl restart
                break

            elif [[ "$opcion_ssl" == "n" ]]; then
                echo "SSL no será configurado."
                break

            else
                echo "Opción inválida. Ingrese 's' o 'n'."
            fi
        done
        echo "Reiniciando Apache con soporte SSL..."
                sudo /usr/local/apache2/bin/apachectl restart
    
}

InstalarNginx(){
            cd "./descargas_ftp"
    sudo apt-get install -y libpcre3 libpcre3-dev > /dev/null

        tar -xzf "/tmp/nginx-$1.tar.gz" -C /tmp
        cd "/tmp/nginx-$1" || exit 1
        puerto=$(Puerto)
        echo "puerto $puerto"
        echo "Configurando Ngnix"
        ./configure --prefix=/usr/local/nginx-$1 --with-http_ssl_module > /dev/null
        sudo make > /dev/null
        sudo make install > /dev/null
        sudo sed -i "s/listen       80;/listen       $puerto;/" /usr/local/nginx-$1/conf/nginx.conf
        sudo /usr/local/nginx-$1/sbin/nginx

       echo "NGINX instalado accede a el desde http://localhost:$puerto."

while true; do
    read -p "¿Quiere configurar el SSL? (s/n): " opcion_ssl

    if [[ "$opcion_ssl" == "s" ]]; then
        portssl=$(Puerto)

        echo "Copiando certificados desde el escritorio..."
        sudo cp /home/urielcaro/Desktop/server.key /usr/local/nginx-$1/conf/server.key
        sudo cp /home/urielcaro/Desktop/server.crt /usr/local/nginx-$1/conf/server.crt

        echo "Agregando bloque SSL al nginx.conf..."
        sed -i '$d' /usr/local/nginx-$1/conf/nginx.conf

        # Añadir bloque SSL al final del archivo nginx.conf
        sudo tee -a /usr/local/nginx-$1/conf/nginx.conf > /dev/null <<EOF

server {
    listen $portssl ssl;
    server_name localhost;

    ssl_certificate     /usr/local/nginx-$1/conf/server.crt;
    ssl_certificate_key /usr/local/nginx-$1/conf/server.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        root   html;
        index  index.html index.htm;
    }
}
}
EOF

        echo "Habilitando puerto $portssl en firewall..."
        sudo ufw allow $portssl/tcp > /dev/null

        echo "Reiniciando Nginx..."
        sudo /usr/local/nginx-$1/sbin/nginx -s reload
        break

    elif [[ "$opcion_ssl" == "n" ]]; then
        echo "SSL no será configurado."
        break

    else
        echo "Opción inválida. Ingrese 's' o 'n'."
    fi
done
echo "Reiniciando Nginx..."
        sudo /usr/local/nginx-$1/sbin/nginx -s reload


}


InstalarTomcat(){
   
    ver=$(echo "$1" | cut -d'.' -f1)
    
         cd "./descargas_ftp"
      
        sudo mkdir -p /opt/tomcat-$1
        echo "Extrayendo Tar"
        sudo tar -xzf "/tmp/tomcat-$1.tar.gz" -C /opt/tomcat-$1 --strip-components=1

        echo "Estableciendo Puerto"
        sudo sed -i "s/Connector port=\"8080\"/Connector port=\"$2\"/" /opt/tomcat-$1/conf/server.xml
            
    while true; do
    read -p "¿Quiere configurar el SSL? (s/n): " opcion_ssl

    if [[ "$opcion_ssl" == "s" ]]; then
    
        portssl=$(Puerto)
        # Ruta al archivo server.xml
        filePath="/opt/tomcat-$1/conf/server.xml"

        # Reemplazo de líneas específicas (equivalente a vaciar líneas 86 y 95 en PowerShell)
        # En Bash no puedes editar por índice fácilmente, así que puedes comentarlas o borrarlas así:
        sudo sed -i '91s/.*/ /' "$filePath"
        sudo sed -i '102s/.*/ /' "$filePath"

        # Reemplazar el puerto del conector SSL
        sudo sed -i "s/<Connector port=\"8443\" protocol=\"org.apache.coyote.http11.Http11NioProtocol\"/<Connector port=\"$portssl\" protocol=\"org.apache.coyote.http11.Http11NioProtocol\"/" "$filePath"

        # Reemplazar la ruta del keystore
        sudo sed -i 's|<Certificate certificateKeystoreFile="conf/localhost-rsa.jks"|<Certificate certificateKeystoreFile="conf/keystore.jks"|' "$filePath"

        # Reemplazar la contraseña del keystore
        sudo sed -i 's|certificateKeystorePassword="changeit" type="RSA" />|certificateKeystorePassword="Password123" type="RSA"/>|' "$filePath"

        sudo cp /home/urielcaro/Desktop/keystore.jks /opt/tomcat-$1/conf
        break
 elif [[ "$opcion_ssl" == "n" ]]; then
        echo "SSL no será configurado."
        break

    else
        echo "Opción inválida. Ingrese 's' o 'n'."
    fi
done


        sudo /opt/tomcat-$1/bin/startup.sh

        echo "Tomcat instalado accede a el desde http://localhost:$puerto"


}

# Verificación de lftp
if ! command -v lftp &>/dev/null; then
    echo "lftp no está instalado. Instalándolo..."
    sudo apt update && sudo apt install -y lftp
fi

# Función para extraer versión del archivo
identificar_version() {
    local filename="$1"
    local tipo_software="$2"
    
    # Buscar versión: números separados por puntos luego del guion
    # Ej: apache24-10.1.24.tar.gz → versión=10.1.24
    if [[ "$filename" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        local version="${BASH_REMATCH[1]}"
        echo "Tipo de software: $tipo_software"
        echo "Archivo: $filename"
        echo "Versión detectada: $version"
         if [[ "$filename" == *"Apache"* ]]; then
        echo "Selecciono Apache"
        InstalarApache "$version"
         elif [[ "$filename" == *"nginx"* ]]; then
        echo "Selecciono Nginx"
        InstalarNginx "$version"
        elif [[ "$filename" == *"tomcat"* ]]; then
        echo "Selecciono Tomcat"
          puerto=$(Puerto)
        InstalarTomcat $version $puerto
        fi
    else
        echo "No se pudo extraer la versión del nombre del archivo."
    fi
}

while true; do
    echo "============================"
    echo " MENÚ DE DESCARGA POR FTP"
    echo "============================"
    echo "Seleccione el servicio para ver sus archivos:"
    select dir in "${DIRS[@]}" "Salir"; do
        if [[ "$REPLY" -ge 1 && "$REPLY" -le ${#DIRS[@]} ]]; then
            SELECTED_DIR="${DIRS[$REPLY-1]}"
            echo "Navegando: $BASE_PATH/$SELECTED_DIR"

            echo "Listando archivos .tar.gz en $SELECTED_DIR:"
            lftp -u "$FTP_USER","$FTP_PASS" "$FTP_SERVER" <<EOF
                lcd $DOWNLOAD_DIR
                cd $BASE_PATH/$SELECTED_DIR
                cls -1 *.tar.gz > /tmp/ftp_file_list.txt
                bye
EOF

            if [[ -s /tmp/ftp_file_list.txt ]]; then
                echo "Archivos disponibles:"
                mapfile -t FILES < /tmp/ftp_file_list.txt

                select file in "${FILES[@]}" "Volver al menú principal"; do
                    if [[ "$REPLY" -ge 1 && "$REPLY" -le ${#FILES[@]} ]]; then
                        SELECTED_FILE="${FILES[$REPLY-1]}"
                        echo "⬇Descargando $SELECTED_FILE..."

                        lftp -u "$FTP_USER","$FTP_PASS" "$FTP_SERVER" <<EOF
                            lcd $DOWNLOAD_DIR
                            cd $BASE_PATH/$SELECTED_DIR
                            get "$SELECTED_FILE"
                            bye
EOF

                        echo "Archivo descargado en: $DOWNLOAD_DIR/$SELECTED_FILE"
                        identificar_version "$SELECTED_FILE" "$SELECTED_DIR"
                        break
                    elif [[ "$REPLY" -eq $((${#FILES[@]} + 1)) ]]; then
                        break
                    else
                        echo "Opción inválida."
                    fi
                done
            else
                echo "No se encontraron archivos .tar.gz en esta carpeta."
            fi
            break

        elif [[ "$REPLY" -eq $((${#DIRS[@]} + 1)) ]]; then
            echo "Saliendo del script."
            exit 0
        else
            echo "Opción inválida."
        fi
    done
done
