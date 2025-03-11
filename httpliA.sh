#!/bin/bash
Paquetes(){
    echo "Instalando los paquetes, apenas asi me jala"
    sudo apt-get update > /dev/null 

    if ! dpkg -l | grep -q "libcurl4-openssl-dev"; then
    echo "Descargando libcurl"
    sudo apt-get install -y libcurl4-openssl-dev > /dev/null
    else
    echo "libcurl4 instalado"
    fi

    for pkg in libapr1-dev libaprutil1-dev libpcre3 libpcre3-dev; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "Instalando $pkg..."
        sudo apt-get install -y $pkg > /dev/null
    else
        echo "$pkg instalado."
    fi
    done

    # Verificar si build-essential, wget, curl, y tar están instalados
    for pkg in build-essential wget curl tar; do
    if ! dpkg -l | grep -q "$pkg"; then
        echo "Descargando $pkg"
        sudo apt-get install -y $pkg > /dev/null
    else
        echo "$pkg instalado"
    fi
    done

    # Verificar si libjansson-dev está instalado
    if ! dpkg -l | grep -q "libjansson-dev"; then
    echo "Descargando libjansson"
    sudo apt-get install -y libjansson-dev > /dev/null
    else
    echo "libjansson-dev instalado"
    fi

    # Verificar si libnghttp2-dev está instalado
    if ! dpkg -l | grep -q "libnghttp2-dev"; then
    echo "Descargando libnghttp2"
    sudo apt-get install -y libnghttp2-dev > /dev/null
    else
    echo "libnghttp2-dev instalado"
    fi

    # Verificar si libssl-dev y zlib1g-dev están instalados
    for pkg in libssl-dev zlib1g-dev; do
    if ! dpkg -l | grep -q "$pkg"; then
        echo "Descargando $pkg"
        sudo apt-get install -y $pkg > /dev/null
    else
        echo "$pkg instalado"
    fi
    done

        # Verificar si default-jdk está instalado
    if ! dpkg -l | grep -q "default-jdk"; then
    echo "Instalando default-jdk..."
    sudo apt-get install -y default-jdk > /dev/null
    else
    echo "default-jdk instalado"
    fi

}

Puerto(){
    if sudo ufw status | grep -q "Status: inactive"; then
        sudo ufw enable > /dev/null
    fi

    # Solicitar un puerto válido
    while true; do
        while true; do
            read -p "Seleccione un puerto para instalar el servicio (debe ser un número menor a 500): " port

            # Validar si la entrada es un número
            if [[ $port =~ ^[0-9]+$ ]]; then
                port=$((port))  # Convertir a entero

                # Validar si está disponible
                if validar_puerto "$port"; then
                    if [[ $port -lt 65535 ]]; then
                        echo -e "\e[32mPuerto válido: $port\e[0m"
                        break
                    else
                        echo -e "\e[31mOpción inválida: El número debe ser menor a 65535.\e[0m"
                    fi
                fi
            else
                echo -e "\e[31mOpción inválida: Debe ingresar solo números.\e[0m"
            fi
        done

        # Verificar si el puerto está en uso
        if puerto_en_uso "$port"; then
            echo -e "\e[31mPuerto en uso. Seleccione otro.\e[0m"
        else
            break
        fi
    done

    echo "El puerto $port está disponible y se puede usar."

}

#!/bin/bash

validar_puerto() {
    local puerto=$1
    local puertos_ocupados=(20 21 22 23 25 53 67 68 80 110 123 143 161 
                            389 443 445 465 587 993 995 3306 3389 5432 
                            5900 6379 8080 8443)

    # Validar el rango del puerto
    if [[ $puerto -lt 1 || $puerto -gt 65535 ]]; then
        echo -e "\e[31mPuerto inválido (debe estar entre 1 y 65535).\e[0m"
        return 1
    fi

    # Verificar si el puerto está en la lista de reservados
    for reservado in "${puertos_ocupados[@]}"; do
        if [[ $puerto -eq $reservado ]]; then
            echo -e "\e[33mNO se puede usar el puerto $puerto, está reservado.\e[0m"
            return 1
        fi
    done

    return 0  # Puerto válido
}

# Función para verificar si un puerto está en uso
puerto_en_uso() {
    local puerto=$1
    if sudo netstat -tuln | grep -q ":$puerto "; then
        return 0  # Puerto en uso
    else
        return 1  # Puerto libre
    fi
}



InstalarApache(){
        local repo_file="/etc/apt/sources.list.d/apache.list"  # Archivo de repositorio (puede variar)

        # Verificar si el archivo del repositorio existe
        if [[ -f "$repo_file" ]]; then
            echo -e "\e[33mEl repositorio de Apache 2.4 existe. Eliminándolo...\e[0m"
            sudo rm -f "$repo_file"

            # Actualizar la lista de paquetes después de eliminar el repo
            sudo apt update > /dev/null
            echo -e "\e[32mRepositorio eliminado y lista de paquetes actualizada.\e[0m"
        else
            echo -e "\e[32mEl repositorio de Apache 2.4 no está configurado.\e[0m"
        fi


          echo "Descargando .tar de Apache"
        wget -q "https://downloads.apache.org/httpd/httpd-2.4.63.tar.gz"

        tar -xzf "/tmp/httpd-2.4.63.tar.gz" -C /tmp
        cd "/tmp/httpd-2.4.63" || exit 1
        
        ./configure --prefix=/usr/local/apache2 --enable-so > /dev/null

        make > /dev/null
        sudo make install > /dev/null
    
        sudo sed -i "s/Listen 80/Listen $2/" /usr/local/apache2/conf/httpd.conf
        sudo sed -i "s/#ServerName www.example.com:80/ServerName localhost:$2/" /usr/local/apache2/conf/httpd.conf

        sudo /usr/local/apache2/bin/apachectl start
        echo "Apache instalado con el puerto $2."

    
}


Apache(){
    # Descargar HTML de la página
    url=$(curl -s "https://httpd.apache.org/download.cgi")
    versions_raw=$(echo "$url" | grep -oP 'httpd-\d+\.\d+\.\d+' | sed 's/httpd-//')
    versionlts=$(echo "$versions_raw" | grep '^2\.4' | head -n 1)
    versions=("$version_lts")
    
    
    while true; do
        echo "Seleccione la versión de $servicio:"
        echo "1.- Versión LTS: ${versions[0]}" 
        read -p "Opcion: " opc
        
        if [[ $opc -ne 1 ]]; then
            echo "Opcion no valida"
        else
            
            puerto=$(Puerto)
            echo $puerto
            InstalarApache ${versions[0]} $puerto
            return 0
            
        fi
    done

}


InstalarTomcat(){
   
    local repo_file="/etc/apt/sources.list.d/tomcat.list"

        # Verificar si el archivo del repositorio existe
        if [[ -f "$repo_file" ]]; then
            echo -e "\e[33mEl repositorio de Tomcat existe. Eliminándolo...\e[0m"
            sudo rm -f "$repo_file"

            # Actualizar la lista de paquetes después de eliminar el repo
            sudo apt update > /dev/null
            echo -e "\e[32mRepositorio eliminado y lista de paquetes actualizada.\e[0m"
        else
            echo -e "\e[32mEl repositorio de Tomcat no está configurado.\e[0m"
        fi
        
        url="https://dlcdn.apache.org/tomcat/tomcat-$ver/v$1/bin/apache-tomcat-$1.tar.gz"
        
        echo "Descargando tar"
        wget -q "$url" -O "/tmp/tomcat-$1.tar.gz"

        sudo mkdir -p /opt/tomcat-$1
        echo "Extrayendo Tar"
        sudo tar -xzf "/tmp/tomcat-$1.tar.gz" -C /opt/tomcat-$1 --strip-components=1

        echo "Estableciendo Puerto"
        sudo sed -i "s/Connector port=\"8080\"/Connector port=\"$2\"/" /opt/tomcat-$1/conf/server.xml

        sudo /opt/tomcat-$1/bin/startup.sh

        echo "Tomcat instalado en el puerto $2."


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
        echo "1- Versión LTS: $versionlts" 
        echo "2- Version DEV: $versiondev"
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

InstalarNginx(){
    sudo apt-get install -y libpcre3 libpcre3-dev > /dev/null

    
    local repo_file="/etc/apt/sources.list.d/nginx.list"

        # Verificar si el archivo del repositorio existe
        if [[ -f "$repo_file" ]]; then
            echo -e "\e[33mEl repositorio de Nginx existe. Eliminándolo...\e[0m"
            sudo rm -f "$repo_file"

            # Actualizar la lista de paquetes después de eliminar el repo
            sudo apt update > /dev/null
            echo -e "\e[32mRepositorio eliminado y lista de paquetes actualizada.\e[0m"
        else
            echo -e "\e[32mEl repositorio de Nginx no está configurado.\e[0m"
        fi
     
        wget -q "https://nginx.org/download/nginx-$1.tar.gz" -O "/tmp/nginx-$1.tar.gz"
        tar -xzf "/tmp/nginx-$1.tar.gz" -C /tmp
        cd "/tmp/nginx-$1" || exit 1

        echo "Compilando NGINX (esto puede tardar)..."
        ./configure --prefix=/usr/local/nginx-$1 > /dev/null
        sudo make > /dev/null
        sudo make install > /dev/null
        sudo sed -i "s/listen       80;/listen       $2;/" /usr/local/nginx-$1/conf/nginx.conf
        sudo /usr/local/nginx-$1/sbin/nginx

        echo "NGINX $1 instalado y configurado en el puerto $2."
}

Nginx(){

    html=$(curl -s "https://nginx.org/en/download.html")
    versiondev=$(echo "$html" | grep -A5 "Mainline version" | grep -oP 'nginx-\d+\.\d+\.\d+' | head -n1 | sed 's/nginx-//')
    mainline_major_minor=$(echo "$versiondev" | cut -d '.' -f1,2)
    versionlts=$(echo "$html" | grep -A5 "Stable version" | grep -oP 'nginx-\d+\.\d+\.\d+' | grep -v "${mainline_major_minor}\." | head -n1 | sed 's/nginx-//')

    
    versions=("$versionlts" "$versiondev")

    while true; do
        echo "Seleccione la versión de Tomcat:"
        echo "1- Versión LTS: $versionlts" 
        echo "2- Version Mainline: $versiondev"
        read -p "Opcion: " opc
        
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

echo "Hola"
if sudo ufw status | grep -q "Status: inactive"; then
        sudo ufw enable
        sudo ufw allow 22/tcp
        
fi

Paquetes

while true; do
    echo "1. Instalar Apache"
    echo "2. Tomcat"
    echo "3. Instalar Nginx"
    echo "Presione una tecla diferente para salir"
    echo "Ingrese una opcion"
    read opc

    case $opc in 
        1)
            Apache
            ;;
        2)
            Tomcat
            ;;
        3)  
            Nginx
            ;;
        *)
            break
            ;;
    esac
done