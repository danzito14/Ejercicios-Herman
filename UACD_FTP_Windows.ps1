function instalar_ftp () {
    
    Install-WindowsFeature web-server -IncludeManagementTools
    # Instalar el FTP server incluyendo las caracteristicas del servidor
    Install-WindowsFeature Web-FTP-Server -IncludeAllSubFeature
    #Instalamos la identificacion basica
    Install-WindowsFeature Web-Bassic-Auth
    

    #creamos los directiorio para el servidor
    mkdir 'C:\FTP'
    #Por ultimo creamos nuestro servidor
      New-WebftpSite -Name "FTP" -Port  21 -PhysicalPath "C:\FTP\reprobados"

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

function crear_usuario () {
    #Solicitamos un usuario y contraseña
    $FTPUserName = Read-Host "Ingrese el nombre de usuario"
    $FTPPassword = Read-Host "Ingrese una contraseña"
    #Añadimos y actualizamos las credenciales
    $CreateUserFTPUser = $ADSI.Create("User", "$FTPUserName")
    $CreateUserFTPUser.SetInfo()
    $CreateUSerFTPUser.SetPassword("$FTPPassword")
    $CreateUserFTPUser.SetInfo()

    #seleccionamos a que grupo se quiere agregar
    #Para ello creamos un objeto
    $UserAccount = New-Object System.Security.Principal.NTAccount("$FTPUserName")
    $SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier]) 

    #Obtenemos las carpetas de los grupo excluyendo la carpeta public
    $grupos = Get-ChildItem C:\FTP -Directory | Where-Object { $_.Name -ne "public" } | Select-Object -ExpandProperty Name
    #Ahora lo mostramos
    $grupos | Format-Table -AutoSize
    #Ahora pedimos que seleccione un grupo
    $grupo_seleccionado = Read-Host "Escriba a que grupo quiere pertenecer"

    #Verificamos que si ingreso un nombre valido
    if ($grupos -contains $grupo_seleccionado){
        $FTPUserGroupName = $grupo_seleccionado

       $Group = [ADSI]"WinNT://$env:ComputerName/$FTPUserGroupName,Group"
       $User = [ADSI]"WinNT://$SID"
       $Group.Add($User.Path)
       mkdir "C:\FTP\$FTPUserName"
       Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true
       Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";roles="$grupo_seleccionado";permissions=3} -PSPath IIS:\ -location "FTP"
       Set-ItemProperty "II:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
       Set-ItemProperty "II:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
       Restart-WebItem "IIS:\Sites\FTP"

       $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" })[0].IPAddress

       Add-DnsServerResourceRecordCName -Name "ftp" -IPAddres $ip -AllowUpdateAny -HostNameAlias servidor.danzito.local
        }
 }

function configurar_permisos ($FTPUserName, $grupo_seleccionado) {
    $usuario = "$env:ComputerName\$FTPUserName"
    $grupo = "$env:ComputerName\$grupo_seleccionado"

    # Establecer permisos NTFS en la carpeta del usuario
    icacls "C:\FTP\$FTPUserName" /inheritance:r
    icacls "C:\FTP\$FTPUserName" /grant "$usuario:(OI)(CI)F"

    # Establecer permisos en la carpeta del grupo
    icacls "C:\FTP\$grupo_seleccionado" /grant "$usuario:(OI)(CI)R"

    # Permitir acceso a la carpeta pública
    icacls "C:\FTP\publica" /grant "$usuario:(OI)(CI)R"

    Write-Host "Permisos establecidos correctamente."
}

function configurar_reglas_ftp ($FTPUserName, $grupo_seleccionado) {
    $rutaFTP = "IIS:\Sites\FTP"

    # Habilitar autenticación básica
    Set-ItemProperty "$rutaFTP" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true

    # Permitir acceso a la carpeta del usuario
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";users="$FTPUserName";permissions=3} -PSPath IIS:\ -location "FTP"

    # Permitir acceso al grupo del usuario
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";roles="$grupo_seleccionado";permissions=1} -PSPath IIS:\ -location "FTP"

    # Permitir acceso a la carpeta pública
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";users="*";permissions=1} -PSPath IIS:\ -location "FTP\publica"

    Write-Host "Reglas de autorización FTP configuradas."
}



instalar_ftp
creargrupos_default
crear_usuario
configurar_permisos $FTPUserName $grupo_seleccionado
configurar_reglas_ftp $FTPUserName $grupo_seleccionado

