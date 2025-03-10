function instalar_ftp () {
    New-NetFirewallRule -DisplayName "Abrir el Puerto FTP 21" -Protocol TCP -LocalPort 21 -Action Allow -Direction Inbound
    Install-WindowsFeature web-server -IncludeManagementTools
    # Instalar el FTP server incluyendo las caracteristicas del servidor
    Install-WindowsFeature Web-FTP-Server -IncludeAllSubFeature
    #Instalamos la identificacion basica
    Install-WindowsFeature Web-Basic-Auth
    

    #creamos los directiorio para el servidor
    mkdir 'C:\FTP'
    #Por ultimo creamos nuestro servidor
      New-WebftpSite -Name "FTP" -Port  21 -PhysicalPath "C:\FTP\"
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";roles="$grupo_seleccionado";permissions=3} -PSPath IIS:\ -location "FTP"
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true

    New-WebBinding -Name "FTP" -IPAddress "*" -Port 21 -HostHeader "ftp.caro.com"

    Restart-WebItem "IIS:\Sites\FTP"
}

function creargrupos_default {
    #aqui vamos a crear los grupos reprobados y recursadores
    #primero creamos su carpeta
    mkdir 'C:\FTP\reprobados'
    #Ahora el grupo
    #Variable para el nombre
    $FTPUserGroupName = "Reprobados"
    #Aqui metemos el nombre de nuestra maquina
    $ADSI = [ADSI]"WinNT://$env:ComputerName"
    #Ahora creamos el grupo
    $FTPUserGroup = $ADSI.Create("Group","$FTPUserGroupName")
    #Actualiza
    $FTPUserGroup.SetInfo()
    #Añadimos una descripcion
    $FTPUserGroup.Description = "Grupo Reprobados, grupo creado con el nombre que se nos a indicado"
    $FTPUserGroup.SetInfo()

    #Ahora es el turno de recursadores
        mkdir 'C:\FTP\recursadores'
    #Ahora el grupo
    #Variable para el nombre
    $FTPUserGroupName2 = "Recursadores"
    #Aqui metemos el nombre de nuestra maquina
    $ADSI2 = [ADSI]"WinNT://$env:ComputerName"
    #Ahora creamos el grupo
    $FTPUserGroup2 = $ADSI.Create("Group","$FTPUserGroupName2")
    #Actualiza
    $FTPUserGroup2.SetInfo()
    #Añadimos una descripcion
    $FTPUserGroup2.Description = "Grupo Recursadores, grupo creado con el nombre que se nos a indicado"
    $FTPUserGroup2.SetInfo()

    #Carpeta publica
    mkdir 'C:\FTP\publica'
    
}

$global:FTPUserName = ''
$global:grupo_seleccionado = ''

function crear_usuario {
    # Solicitar usuario y contraseña
    $global:FTPUserName = Read-Host "Ingrese el nombre de usuario"
    $FTPPassword = ''
    $regex = '^[a-zA-Z0-9!#$%&^*().]{8,15}$'

    while ($FTPPassword -notmatch $regex) {
        $FTPPassword = Read-Host "Ingrese una contraseña (8-15 caracteres, sin espacios)"
    }

    # Añadir usuario al sistema
    $ADSI = [ADSI]"WinNT://$env:ComputerName"
    $CreateUserFTPUser = $ADSI.Create("User", "$global:FTPUserName")
    $CreateUserFTPUser.SetPassword("$FTPPassword")
    $CreateUserFTPUser.SetInfo()

    # Obtener grupos disponibles
    $carpetas = Get-ChildItem C:\FTP -Directory | Select-Object -ExpandProperty Name
    $grupos = Get-LocalGroup | Select-Object -ExpandProperty Name
    $iguales = $carpetas | Where-Object { $grupos -contains $_ }

    if (-not $iguales) {
        Write-Host "No hay grupos coincidentes con carpetas en C:\FTP"
        exit
    }

    # Solicitar grupo
    Write-Host "Grupos disponibles:"
    $iguales | ForEach-Object { Write-Host $_ }

    do {
        $global:grupo_seleccionado = Read-Host "Escriba el grupo al que quiere pertenecer"
    } while ($global:grupo_seleccionado -notin $iguales)

    # Agregar usuario al grupo
    $Group = [ADSI]"WinNT://$env:ComputerName/$global:grupo_seleccionado,Group"
    $User = [ADSI]"WinNT://$env:ComputerName/$global:FTPUserName"
    $Group.Add($User.Path)

    # Crear carpeta de usuario y enlaces simbólicos
    $userPath = "C:\FTP\$global:FTPUserName"
    $userRootPath = "$userPath\$global:FTPUserName"

    mkdir $userRootPath -ErrorAction SilentlyContinue
    New-Item -ItemType SymbolicLink -Path "$userPath\grupo" -Target "C:\FTP\$global:grupo_seleccionado" -ErrorAction SilentlyContinue
    New-Item -ItemType SymbolicLink -Path "$userPath\publica" -Target "C:\FTP\publica" -ErrorAction SilentlyContinue

    # Configurar permisos NTFS
    icacls $userPath /inheritance:r
    icacls $userPath /grant "`"$global:FTPUserName`":(OI)(CI)F"
    icacls $userRootPath /grant "`"$global:FTPUserName`":(OI)(CI)F"

    # Configurar aislamiento de usuario en IIS
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.userIsolation.mode -Value 2

    # Crear directorio virtual en IIS para el usuario
    New-WebVirtualDirectory -Site "FTP" -Name "$global:FTPUserName" -PhysicalPath "IIS:\FTP\$global:FTPUserName\$global:FTPUserName"

    # Configurar permisos FTP en IIS
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";users="$global:FTPUserName";permissions=3} -PSPath IIS:\ -location "FTP"

    Write-Host "Usuario $global:FTPUserName creado con éxito y aislado en $userRootPath"
}


instalar_ftp
creargrupos_default
crear_usuario
$global:FTPUserName
$global:grupo_seleccionado
Restart-WebItem "IIS:\Sites\FTP"

