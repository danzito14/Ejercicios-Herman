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
        echo "puerto $2"
        echo "Configurando Ngnix"
        ./configure --prefix=/usr/local/nginx-$1 > /dev/null
        sudo make > /dev/null
        sudo make install > /dev/null
        sudo sed -i "s/listen       80;/listen       $2;/" /usr/local/nginx-$1/conf/nginx.conf
        sudo /usr/local/nginx-$1/sbin/nginx

        echo "NGINX instalado accede a el desde http://localhost:$2."
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
            
            puerto=$(Puerto)
            InstalarNginx $versionlts $puerto
            return 0
        elif [[ $opc -eq 2 ]]; then
            
            puerto=$(Puerto)
            InstalarNginx $versiondev $puerto
            return 0
        else    
            echo "Opcion no valida"
        fi
    done
}


InstalarTomcat(){
   
    ver=$(echo "$1" | cut -d'.' -f1)
    if [[ -d "/opt/tomcat-$1" ]]; then
         while true; do
            echo "Tomcat ya esta en su ultima versión, quiere cambiar el puerto"
            echo "1. Cambiar puerto" 
            echo "2. Salir"
            read opc
                case $opc in 
                1)
                    sudo sed -i -E "s/Connector port=\"[0-9]+\"/Connector port=\"$2\"/" /opt/tomcat-$1/conf/server.xml
                    sudo /opt/tomcat-$1/bin/shutdown.sh
                    sudo /opt/tomcat-$1/bin/startup.sh
                    echo "Reiniciando Tomcat con el nuevo puerto"
                    return 0
                    ;;
                2)
                    echo "Saliendo.."
                    return 0
                    ;;
                *)
                    echo "Opcion invalida."
                    ;;
            esac
        done

    else
        
        url="https://dlcdn.apache.org/tomcat/tomcat-$ver/v$1/bin/apache-tomcat-$1.tar.gz"
        
        echo "Descargando tomcat"
        wget -q "$url" -O "/tmp/tomcat-$1.tar.gz"
        echo "puerto $2"
        sudo mkdir -p /opt/tomcat-$1
        echo "Extrayendo tomcat y configurando"
        sudo tar -xzf "/tmp/tomcat-$1.tar.gz" -C /opt/tomcat-$1 --strip-components=1    
        sudo sed -i "s/Connector port=\"8080\"/Connector port=\"$2\"/" /opt/tomcat-$1/conf/server.xml

        sudo /opt/tomcat-$1/bin/startup.sh

        echo "Tomcat instalado accede a el desde http://localhost:$2.$2."


    fi

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
        echo "Instalacion de Tomcat"
        echo "1.- Tomcat versión LTS" 
        echo "2.- Tomcat version dev-build"
        echo "¿Que versión de Apache quiere instalar?"
        read  opc
        
        if [[ $opc -eq 1 ]]; then
            
            puerto=$(Puerto)
            InstalarTomcat $versionlts $puerto
            return 0
        elif [[ $opc -eq 2 ]]; then
            
            puerto=$(Puerto)
            InstalarTomcat $versiondev $puerto
            return 0
        else    
            echo "Opcion invalida"
        fi
    done
}



if sudo ufw status | grep -q "Status: inactive"; then
        sudo ufw enable
        sudo ufw allow 22/tcp
        
fi

Paquetes

while true; do

    opc=0
    echo "1. Instalar Apache"
    echo "2. Instalar Nginx"
    echo "3. Instalar Tomcat"
    echo "Presione cualquier tecla distinta para salir"
    echo "¿Que servicio quiere instalar?"
    read opc

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
        *)
            break
            ;;

    esac
done
