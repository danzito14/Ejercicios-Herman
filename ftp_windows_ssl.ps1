function userValid {
    param (
        [string]$username
    )

    if ($username -match "^[a-zA-Z][a-zA-Z]{2,19}$") {
        return $true
    } else {
        Write-Host "Nombre de usuario invalido solo pueden ser letras"
        return $false
    }
}

function passwordValid {
    param (
        [string]$password
    )

    if ($password -match "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,14}$") {
        return $true
    } elseif ($password -match "\s") {
        Write-Host "La contraseña no es válida. Debe tener entre 8 y 14 caracteres, al menos una mayúscula, una minúscula, un número y un carácter"
        return $false
    } else {
        Write-Host "La contraseña no es válida. Debe tener entre 8 y 14 caracteres, al menos una mayúscula, una minúscula, un número y un carácter"
        return $false
    }
}

function createGroups {
    net localgroup "Reprobados" /add
    net localgroup "Recursadores" /add
}

function assignGeneralPermissions {
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.Security.authentication.basicAuthentication.enabled -Value 1
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.Security.authentication.anonymousAuthentication.enabled -Value 1
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.userIsolation.mode -Value "IsolateRootDirectoryOnly" 

    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="*";permissions=1} -PSPath IIS:\ -Location "FTP"
    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP" -Filter "system.ftpServer/security/authorization" -Name "." -AtElement @{users="*";roles="";permissions=1}
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="*";permissions=1} -PSPath IIS:\ -Location "FTP"

    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/Publico" -Filter "system.ftpServer/security/authorization" -Name "."
    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/Reprobados" -Filter "system.ftpServer/security/authorization" -Name "."
    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/Recursadores" -Filter "system.ftpServer/security/authorization" -Name "."
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="*";permissions=1} -PSPath IIS:\ -Location "FTP/Publico"
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="Reprobados, Recursadores";permissions=3} -PSPath IIS:\ -Location "FTP/Publico"
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="Reprobados";permissions=3} -PSPath IIS:\ -Location "FTP/Reprobados"
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="Recursadores";permissions=3} -PSPath IIS:\ -Location "FTP/Recursadores"
}

function assignUserPermissions {
    param (
        [string]$user,
        [string]$groupName
    )

    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$user" -Filter "system.ftpServer/security/authorization" -Name "."
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users=$user;permissions=3} -PSPath IIS:\ -Location "FTP/$user"

    if ($groupName -eq "Reprobados") {
        cmd /c mklink /D "C:\FTP\LocalUser\$user\Reprobados" "C:\FTP\Reprobados"
    } else {
        cmd /c mklink /D "C:\FTP\LocalUser\$user\Recursadores" "C:\FTP\Recursadores"
    }

    cmd /c mklink /D "C:\FTP\LocalUser\$user\Publico" "C:\FTP\Publico"
    cmd /c mklink /D "C:\FTP\LocalUser\$user\$user" "C:\FTP\$user"
}

function createUser {
    param (
        [string]$user,
        [string]$pass,
        [string]$groupName
    )

    if (Test-Path "C:\FTP\$user") {
        Write-Host "El usuario '$user' ya existe"
        return
    }

    net user $user $pass /add
    net localgroup $groupName $user /add

    mkdir "C:\FTP\$user"
    mkdir "C:\FTP\LocalUser\$user"

    assignUserPermissions -user $user -groupName $groupName
}

Write-Host "Preparando todo"

Install-WindowsFeature -Name Web-Ftp-Server -IncludeManagementTools
Install-WindowsFeature Web-Server -IncludeManagementTools


Import-Module WebAdministration

mkdir C:\FTP
mkdir C:\FTP\Publico
mkdir C:\FTP\Reprobados
mkdir C:\FTP\Recursadores
mkdir C:\FTP\LocalUser
mkdir C:\FTP\LocalUser\Public

cmd /c mklink /D C:\FTP\LocalUser\Public\Publico C:\FTP\Publico

New-WebFtpSite -Name "FTP" -Port 21 -PhysicalPath C:\FTP

createGroups

assignGeneralPermissions
do{

write-Host "Desea activar el certificado SSL"
$res = read-host "s/n"
if($res -eq "s" -or $res -eq "n"){
	break}
}while($true)
Write-Host "Menú de gestión de usuarios"
    Write-Host "1. Agregar usuario"
    Write-Host "2. Salir"
   $opcion = Read-Host "Seleccione una opción"
  switch ($opcion) {
        "1" {
            do {
                
                do {
                    $user = Read-Host "Ingrese el nombre del usuario"
                } while (-not (userValid -username $user))

                do {
                    $pass = Read-Host "Ingrese la contraseña del usuario"
                } while (-not (passwordValid -password $pass))

                do {
                    $groupName = Read-Host "Ingrese el grupo del usuario (Reprobados o Recursadores)"
                    if ($groupName -eq "Reprobados" -or $groupName -eq "Recursadores") {
                        break
                    }
                    Write-Host "El grupo no existe. Porfavor ingrese Reprobados o Recursadores".
                } while ($true)

                createUser -user $user -pass $pass -groupName $groupName

                $res = Read-Host "¿Desea agregar otro usuario? (s/n)"
            } while ($res -eq "s")
        }
        "2" {
            break
        }
        default {
             Write-Host "Opción inválida. Intente nuevamente."
        }

    }


if ($res -eq "n"){
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
}else{
	Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 1
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 1

}
New-NetFirewallRule -DisplayName "FTP" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow

Restart-WebItem "IIS:\Sites\FTP"

Write-Host "Configuración del servidor FTP completada"