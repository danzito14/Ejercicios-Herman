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
function crear_usuario () {
    # Solicitar usuario y contraseña
    $global:FTPUserName = Read-Host "Ingrese el nombre de usuario"
    $FTPPassword = Read-Host "Ingrese una contraseña"

    # Añadir usuario
    $ADSI = [ADSI]"WinNT://$env:ComputerName"
    $CreateUserFTPUser = $ADSI.Create("User", "$global:FTPUserName")
    $CreateUserFTPUser.SetInfo()
    $CreateUserFTPUser.SetPassword("$FTPPassword")
    $CreateUserFTPUser.SetInfo()

    # Obtener grupos disponibles
    $grupos = Get-ChildItem C:\FTP -Directory | Where-Object { $_.Name -ne "publica" } | Select-Object -ExpandProperty Name
    $grupos | Format-Table -AutoSize

    # Solicitar grupo
    $global:grupo_seleccionado = Read-Host "Escriba a qué grupo quiere pertenecer"

    # Verificar que el grupo existe
    if ($grupos -contains $global:grupo_seleccionado) {
        $FTPUserGroupName = $global:grupo_seleccionado
        $Group = [ADSI]"WinNT://$env:ComputerName/$FTPUserGroupName,Group"
        $User = [ADSI]"WinNT://$env:ComputerName/$global:FTPUserName"
        $Group.Add($User.Path)

        mkdir "C:\FTP\$global:FTPUserName"
        Write-Host "FTPS habilitado."

        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" })[0].IPAddress
        Add-DnsServerResourceRecordCName -Name "ftp" -HostNameAlias "caro.com" -ZoneName "caro.com"



    

    $usuario = "$env:ComputerName\$global:FTPUserName"
    $grupo = "$env:ComputerName\$global:grupo_seleccionado"
    
    # Verificar si las carpetas existen
    if (-not (Test-Path "C:\FTP\$global:FTPUserName")) {
        mkdir "C:\FTP\$global:FTPUserName"
    }

    # Establecer permisos NTFS en la carpeta del usuario
    icacls "C:\FTP\$global:FTPUserName" /inheritance:r
    icacls "C:\FTP\$global:FTPUserName" /grant "`"$usuario`":(OI)(CI)F"


    # Establecer permisos en la carpeta del grupo
    icacls "C:\FTP\$global:grupo_seleccionado" /grant "`"$usuario`":(OI)(CI)F"

    # Permitir acceso a la carpeta pública
    icacls "C:\FTP\publica" /grant "`"$usuario`":(OI)(CI)F"

    Write-Host "Permisos establecidos correctamente."


    $rutaFTP = "IIS:\Sites\FTP"

    # Habilitar autenticación básica
    Set-ItemProperty "$rutaFTP" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true

    # Permitir acceso a la carpeta del usuario
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";users="$FTPUserName";permissions=3} -PSPath IIS:\ -location "FTP"

    # Permitir acceso al grupo del usuario
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";roles="$grupo_seleccionado";permissions=1} -PSPath IIS:\ -location "FTP"

    # Permitir acceso a la carpeta pública
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";users="*";permissions=1} -PSPath IIS:\ -location "FTP/publica"

    attrib +h "C:\FTP\*" /s /d
    attrib -h "C:\FTP\$global:FTPUserName"
    attrib -h "C:\FTP\$global:grupo_seleccionado"
    attrib -h "C:\FTP\publica"

    icacls "C:\FTP" /deny Usuarios:(M)
    icacls "C:\FTP\$global:FTPUserName" /grant $global:FTPUserName:(M)
    icacls "C:\FTP\$global:grupo_seleccionado" /grant $global:FTPUserName:(M)
    icacls "C:\FTP\publica" /grant $global:FTPUserName:(M)

    Write-Host "Reglas de autorización FTP configuradas."
    } else {
        Write-Host "Error: Grupo no válido."
    }
}





instalar_ftp
creargrupos_default
crear_usuario
$global:FTPUserName
$global:grupo_seleccionado
Restart-WebItem "IIS:\Sites\FTP"

