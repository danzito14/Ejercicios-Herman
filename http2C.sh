#!/bin/bash
Paquetes(){
    echo "Preparando todo"
    sudo apt-get update > /dev/null 

    if ! dpkg -l | grep -q "libcurl4-openssl-dev"; then
    echo "Descargando libcurl"
    sudo apt-get install -y libcurl4-openssl-dev > /dev/null
    else
    echo "libcurl4-openssl-dev ya está instalado"
    fi

    for pkg in libapr1-dev libaprutil1-dev libpcre3 libpcre3-dev; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "Instalando $pkg..."
        sudo apt-get install -y $pkg > /dev/null
    else
        echo "$pkg ya está instalado."
    fi
    done

    # Verificar si build-essential, wget, curl, y tar están instalados
    for pkg in build-essential wget curl tar; do
    if ! dpkg -l | grep -q "$pkg"; then
        echo "Descargando $pkg"
        sudo apt-get install -y $pkg > /dev/null
    else
        echo "$pkg ya está instalado"
    fi
    done

    # Verificar si libjansson-dev está instalado
    if ! dpkg -l | grep -q "libjansson-dev"; then
    echo "Descargando libjansson"
    sudo apt-get install -y libjansson-dev > /dev/null
    else
    echo "libjansson-dev ya está instalado"
    fi

    # Verificar si libnghttp2-dev está instalado
    if ! dpkg -l | grep -q "libnghttp2-dev"; then
    echo "Descargando libnghttp2"
    sudo apt-get install -y libnghttp2-dev > /dev/null
    else
    echo "libnghttp2-dev ya está instalado"
    fi

    # Verificar si libssl-dev y zlib1g-dev están instalados
    for pkg in libssl-dev zlib1g-dev; do
    if ! dpkg -l | grep -q "$pkg"; then
        echo "Descargando $pkg"
        sudo apt-get install -y $pkg > /dev/null
    else
        echo "$pkg ya está instalado"
    fi
    done

        # Verificar si default-jdk está instalado para Tomcat
    if ! dpkg -l | grep -q "default-jdk"; then
    echo "Instalando default-jdk..."
    sudo apt-get install -y default-jdk > /dev/null
    else
    echo "default-jdk ya está instalado"
    fi

}

#!/bin/bash

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
        echo "Descargando Apache"
                puerto=$(Puerto)
        wget -q "https://downloads.apache.org/httpd/httpd-2.4.63.tar.gz" -O "/tmp/httpd-2.4.63.tar.gz"

        
        echo "Configurando Apache"
        tar -xzf "/tmp/httpd-2.4.63.tar.gz" -C /tmp
        cd "/tmp/httpd-2.4.63" || exit 1
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


Apache(){
    # Descargar HTML de la página
    url=$(curl -s "https://httpd.apache.org/download.cgi")
    versions_raw=$(echo "$url" | grep -oP 'httpd-\d+\.\d+\.\d+' | sed 's/httpd-//')
    versionlts=$(echo "$versions_raw" | grep '^2\.4' | head -n 1)
    versions=("$version_lts")
    
    
    while true; do
        echo "Instalacion de Apache24"
        echo "1.- Apache versión LTS" 
        echo "2.- Apache version dev-build"
        echo "¿Que versión de Apache quiere instalar?"
        read  opc
        
        if [[ $opc -ne 1 && $opc -ne 2 ]]; then
            echo "Opcion invalida"
        else
            echo $puerto
            InstalarApache ${versions[0]}
            return 0      
        fi
    done

}

InstalarNginx(){
    sudo apt-get install -y libpcre3 libpcre3-dev > /dev/null

        echo "Descargando Ngnix"
        wget -q "https://nginx.org/download/nginx-$1.tar.gz" -O "/tmp/nginx-$1.tar.gz"
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

Nginx(){

    html=$(curl -s "https://nginx.org/en/download.html")
    versiondev=$(echo "$html" | grep -A5 "Mainline version" | grep -oP 'nginx-\d+\.\d+\.\d+' | head -n1 | sed 's/nginx-//')
    mainline_major_minor=$(echo "$versiondev" | cut -d '.' -f1,2)
    versionlts=$(echo "$html" | grep -A5 "Stable version" | grep -oP 'nginx-\d+\.\d+\.\d+' | grep -v "${mainline_major_minor}\." | head -n1 | sed 's/nginx-//')

    
    versions=("$versionlts" "$versiondev")

    while true; do
        echo "Instalacion de Nginx"
        echo "1.- Nginx versión LTS" 
        echo "2.- Nginx version dev-build"
        echo "¿Que versión de Apache quiere instalar?"
        read  opc
        
        if [[ $opc -eq 1 ]]; then
            
            InstalarNginx $versionlts $puerto
            return 0
        elif [[ $opc -eq 2 ]]; then
            
            InstalarNginx $versiondev $puerto
            return 0
        else    
            echo "Opcion no valida"
        fi
    done
}


InstalarTomcat(){
   
    ver=$(echo "$1" | cut -d'.' -f1)
    
        
        url="https://dlcdn.apache.org/tomcat/tomcat-$ver/v$1/bin/apache-tomcat-$1.tar.gz"
        
        echo "Descargando tar"
        wget -q "$url" -O "/tmp/tomcat-$1.tar.gz"

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


Tomcat(){     
    url=$(curl -s "https://tomcat.apache.org/index.html")
    urls=$(echo "$url" | grep -oP 'https://tomcat.apache.org/download-\d+\.cgi')
    tomcat_url_lts=""
    tomcat_url_dev=""

    while read -r url; do
        version_number=$(echo "$url" | grep -oP '\d+')

        if [[ "$version_number" -lt 11 ]]; then
            tomcat_url_lts="$url"
        fi
        if [[ "$version_number" -eq 11 ]]; then
            tomcat_url_dev="$url"
        fi
    done <<< "$urls"

    
    html_lts=$(curl -s "$tomcat_url_lts")
    versionlts=$(echo "$html_lts" | grep -oP 'v\d+\.\d+\.\d+' | head -n 1 | sed 's/v//')
    html_dev=$(curl -s "$tomcat_url_dev")
    versiondev=$(echo "$html_dev" | grep -oP 'v\d+\.\d+\.\d+' | head -n 1 | sed 's/v//')
    versions=("$versionlts" "$versiondev")


    while true; do
        echo "Seleccione la versión de Tomcat:"
        echo "1- Versión LTS" 
        echo "2- Version DEV"
        read -p "Opcion: " opc
        
        if [[ $opc -eq 1 ]]; then
            
            puerto=$(Puerto)
            InstalarTomcat $versionlts $puerto
            return 0
        elif [[ $opc -eq 2 ]]; then
            
            puerto=$(Puerto)
            InstalarTomcat $versiondev $puerto
            return 0
        else    
            echo "Opcion no valida"
        fi
    done
}



if sudo ufw status | grep -q "Status: inactive"; then
        sudo ufw enable
        sudo ufw allow 22/tcp
        
fi

Paquetes

# Pregunta inicial
while true; do
    echo "¿Desea hacer la instalación por HTTP o FTP?"
    echo "1. HTTP"
    echo "2. FTP"
    echo "3. Salir"
    read -rp "Seleccione una opción [1-3]: " tipo_instalacion

    case $tipo_instalacion in
        1)
            echo "Instalación por HTTP seleccionada."

            while true; do
                echo "   Menú de Instalación HTTP"
                echo "1. Instalar Apache"
                echo "2. Instalar Nginx"
                echo "3. Instalar Tomcat"
                echo "4. Volver al menú principal"
                echo "Seleccione una opción:"
                read -rp "Opción: " opc

                case $opc in 
                    1)
                        Apache
                        ;;
                    2)
                        Nginx
                        ;;
                    3)  
                        Tomcat
                        ;;
                    4)
                        break
                        ;;
                    *)
                        echo "Opción inválida. Intente nuevamente."
                        ;;
                esac
            done
            ;;

        2)
            echo "Instalación por FTP seleccionada."
            if [[ -f "./conec_ftp_linux.sh" ]]; then
                chmod +x ./conec_ftp_linux.sh
                ./conec_ftp_linux.sh
            else
                echo "El script conec_ftp_linux.sh no se encuentra en el directorio actual."
            fi
            ;;

        3)
            echo "Saliendo del script. ¡Hasta luego!"
            exit 0
            ;;

        *)
            echo "Opción inválida. Intente nuevamente."
            ;;
    esac
done
