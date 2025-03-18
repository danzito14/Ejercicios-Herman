#!/bin/bash

# Instalación de vsftpd
VSFTPD_CONF="/etc/vsftpd.conf"
echo "Instalando vsftpd..."
sudo apt update && sudo apt install vsftpd -y

# Creación de grupos
echo "Preparando todo"
sudo groupadd Servicios_http


# Creación de directorios FTP
echo "Creando estructura de directorios..."
sudo mkdir -p /srv/ftp/{Publico,Servicios_http,usuarios}
sudo mkdir -p /srv/ftp/public/Publico

# Enlazar carpetas públicas
echo "Configurando enlaces de carpetas..."
mount --bind /srv/ftp/public/Publico /srv/ftp/Publico
echo "/srv/ftp/public/Publico /srv/ftp/Publico none bind 0 0" | sudo tee -a /etc/fstab

# Asignación de permisos
echo "Configurando permisos..."
sudo chmod -R 777 /srv/ftp/Publico
sudo chmod -R 755 /srv/ftp/usuarios
sudo chown -R :Servicios_http /srv/ftp/Servicios_http
sudo chmod -R 775 /srv/ftp/Servicios_http
sudo chmod -R g+s /srv/ftp/Servicios_http


# Función para validar nombre de usuario
userValid() {
    local username="$1"
    if [[ "$username" =~ ^[a-zA-Z][a-zA-Z]{2,19}$ ]]; then
        return 0
    else
        echo "Nombre de usuario invalido solo pueden ser letras "
        return 1
    fi
}

# Función para validar contraseña
passwordValid() {
    local password="$1"

    if [[ ${#password} -lt 8 || ${#password} -gt 14 ]]; then
        echo "Error: La contraseña debe tener entre 8 y 14 caracteres."
        return 1
    fi
    if [[ ! "$password" =~ [a-z] ]]; then
        echo "Error: La contraseña debe contener al menos una letra minúscula."
        return 1
    fi
    if [[ ! "$password" =~ [A-Z] ]]; then
        echo "Error: La contraseña debe contener al menos una letra mayúscula."
        return 1
    fi
    if [[ ! "$password" =~ [0-9] ]]; then
        echo "Error: La contraseña debe contener al menos un número."
        return 1
    fi
    if [[ ! "$password" =~ [^a-zA-Z0-9] ]]; then
        echo "Error: La contraseña debe contener al menos un carácter especial."
        return 1
    fi
    return 0
}

# Función para crear usuario FTP
createUser() {
    local usuario=$1
    local pass=$2
    local grupo=$3

    if id "$usuario" &>/dev/null; then
        echo "Error El usuario '$usuario' ya existe."
        return 1
    fi

    # Crear directorios del usuario
    sudo mkdir -p /srv/ftp/usuarios/$usuario/{Publico,$grupo,$usuario}

    # Crear usuario en el sistema
    sudo useradd -m -d /srv/ftp/usuarios/$usuario/$usuario -s /bin/bash -G $grupo $usuario
    echo "$usuario:$pass" | sudo chpasswd

    # Asignar permisos
    sudo chown -R $usuario:$grupo /srv/ftp/usuarios/$usuario/$usuario
    sudo chmod -R 700 /srv/ftp/usuarios/$usuario/$usuario

    # Enlazar directorios del grupo y público
    mount --bind /srv/ftp/$grupo /srv/ftp/usuarios/$usuario/$grupo
    echo "/srv/ftp/$grupo /srv/ftp/usuarios/$usuario/$grupo none bind 0 0" | sudo tee -a /etc/fstab
    mount --bind /srv/ftp/Publico /srv/ftp/usuarios/$usuario/Publico
    echo "/srv/ftp/Publico /srv/ftp/usuarios/$usuario/Publico none bind 0 0" | sudo tee -a /etc/fstab

    echo "Usuario $usuario creado correctamente en el grupo $grupo."
}

# Bucle para agregar usuarios
while true; do
    read -p "¿Desea agregar un usuario? 1.- Agregar usuarios 2.- Salir: " respuesta
        case "$respuesta" in
            1)
                echo "Agregando usuario"
               
                while true; do
                    read -p "Ingrese el nombre de usuario: " nombreUsuario
                    userValid "$nombreUsuario" && break
                done

                while true; do
                    read -s -p "Ingrese la contraseña debe de incluir una letra mayuscula, minuscula, un numero y un caracter especial " passUsuario
                    echo
                    passwordValid "$passUsuario" && break
                done

                while true; do
                    read -p "Ingrese el grupo para el usuario $nombreUsuario (Servicios_http): " nombreGrupo
                    if [[ "$nombreGrupo" == "Servicios_http" ]]; then
                        break
                    fi
                    echo "El grupo no existe.Porfavor  ingrese Servicios_http."
                done

                createUser $nombreUsuario $passUsuario $nombreGrupo

            ;;
            2)
                echo "Saliendo"
                break
                ;;
            *)
                echo "Opción inválida. Intente nuevamente."
                ;;
        esac
done

# Configuración de vsftpd
echo "Configurando vsftpd..."
cat <<EOF | sudo tee /etc/vsftpd.conf
listen=YES
anonymous_enable=YES
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
EOF


# Habilitar el acceso anónimo
echo "Habilitando acceso anónimo"
sudo sed -i 's/^#anonymous_enable=YES/anonymous_enable=YES/' $VSFTPD_CONF
sudo sed -i 's/^#anon_upload_enable=YES/anon_upload_enable=NO/' $VSFTPD_CONF   # Deshabilitar subida anónima
sudo sed -i 's/^#anon_mkdir_write_enable=YES/anon_mkdir_write_enable=NO/' $VSFTPD_CONF  # Deshabilitar creación de carpetas anónimas
sudo sed -i 's/^#anon_other_write_enable=YES/anon_other_write_enable=NO/' $VSFTPD_CONF  # Deshabilitar otros permisos de escritura anónimos

# Configuración del firewall
echo "Configurando firewall..."
sudo ufw allow 20,21/tcp
sudo ufw allow 30000:30100/tcp
sudo ufw --force enable

# Reiniciar y habilitar vsftpd
echo "Reiniciando servicio vsftpd..."
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd

