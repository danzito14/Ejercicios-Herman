
Install-WindowsFeature -Name DNS -IncludeManagementTools

Write-Output "Descargado hMailServer"
$downlandUrl = "https://www.hmailserver.com/files/hMailServer-5.6.8-B2574.exe"
$installerPath = "C:\hMailServer-5.6.8-B2574.exe"
Invoke-WebRequest -Uri $downlandUrl -OutFile $installerPath


Write-Output "Descargando thunderbird"
$downlandUrl2 = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/136.0.1/win64/es-ES/Thunderbird%20Setup%20136.0.1.exe"
$installerPath2 = "C:\Thunderbird20Setup20136.0.1.exe"
Invoke-WebRequest -Uri $downlandUrl2 -OutFile $installerPath2


Write-Output "Instalando el hMailServer"
Start-Process -FilePath $installerPath -ArgumentList "/SILENT" -Wait
Write-Output "Instalando ThunderBirnd"
Start-Process -FilePath $installerPath2 -ArgumentList "/SILENT" -Wait



# Solicitar la nueva IP al usuario
$newIP = Read-Host "Ingrese la nueva IP fija"

# Obtener el nombre de la interfaz de red principal
$interfaceName = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).Name

# Cambiar a IP fija
Write-Output "Cambiando la configuración de red..."
try {
    # Desactivar DHCP
    Write-Output "Desactivando DHCP en la interfaz $interfaceName..."
    Set-NetIPInterface -InterfaceAlias $interfaceName -Dhcp Disabled

    # Asignar la nueva IP fija con una máscara de subred por defecto (24)
    Write-Output "Configurando IP fija..."
    New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $newIP -PrefixLength 24

    Write-Output "Configuración de IP fija completada."
} catch {
    Write-Output "Error al cambiar la configuración de IP: $_"
}


$filepathini = "C:\Program Files (x86)\hMailServer\Bin\hMailServer.INI"
$fileContent = Get-Content -Path $filepathini
$fileContent = $fileContent -replace 'AdministratorPassword=d41d8cd98f00b204e9800998ecf8427e','AdministratorPassword='
$fileContent | Set-Content $filepathini





# Cargar la API de hMailServer
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace hMailServer
{
    [ComImport, Guid("DADAF7DA-DEF3-49EC-8D3B-6645B515B8FA")]
    public interface hMailServerApplication
    {
        void Authenticate(string username, string password);
        object Domains { get; }
    }

    [ComImport, Guid("DADAF7DA-DEF3-49EC-8D3B-6645B515B8FA")]
    public class hMailServerApplicationClass
    {
    }
}
"@

# Crear instancia de hMailServer
$app = New-Object -ComObject hMailServer.Application

# Intentar autenticarse
try {
    $app.Authenticate("Administrator", "")  # Reemplaza con tu contraseña
} catch {
    Write-Output "Error: Autenticación fallida. Verifica el nombre de usuario y la contraseña."
    exit 1
}

# Crear un nuevo dominio
#$domainName = "danzito.com"  # Reemplaza con el nombre del dominio que deseas crear
# Expresión regular para validar un nombre de dominio
$domainRegex = '^[a-zA-Z0-9-]+\.(com|net|org|local|info|co|edu)$'
$Regexnombre = '^[a-zA-Z]+$'
$Regexcontra = '^[a-ZA-Z0-9]+$'

# Ciclo While para asegurar que el dominio sea válido
while ($true) {
    $domainName = Read-Host "Ingrese un nombre para el dominio, ejemplo nombre.com o nombre.local"

    # Verificar si el dominio coincide con la expresión regular
    if ($domainName -match $domainRegex) {
        Write-Output "Dominio válido: $domainName"
        break  # Salir del ciclo si es válido
    } else {
        Write-Output "Error: El dominio '$domainName' no es válido. Asegúrese de usar un formato como nombre.com o nombre.local"
    }
}

# Crear el objeto de dominio
$domain = $app.Domains.Add()
$domain.Name = $domainName  # Nombre del dominio
$domain.Active = $true       # Activar el dominio

# Guardar el dominio
$domain.Save()

Write-Output "Dominio '$domainName' creado exitosamente."

$domain = $app.Domains.ItemByName($domainName)

if ($domain -eq $null) {
    Write-Output "Error: El dominio '$domainName' no existe."
    exit 1
}


while($true){
    $nombrecorreo = Read-Host "Ingrese un nombre de usuario, solo el nombre el @'$domainName' se agrega solo"
    if ($nombrecorreo -match $Regexnombre){
       $nombrecorreo = $nombrecorreo + "@" + $domainName
       Write-Host $nombrecorreo
       break
    }else{
        Write-Host "Porfavor solo ingrese el nombre"
    }
}

while($true){
    $correocontraseña = Read-Host "Ingrese una contraseña solo se aceptan letras o numeros"
    if($correocontraseña -match $Regexcontra){
        Write-Host $correocontraseña
        break
    }else{
        Write-Host "Contraseña invalida"
    }
}

# Crear el usuario
$account = $domain.Accounts.Add()
$account.Address = $nombrecorreo  # Reemplaza con el nuevo correo
$account.Password = $correocontraseña   # Reemplaza con la contraseña deseada
$account.Save()

Write-Output "Usuario creado exitosamente en hMailServer."

Write-Output "Dominio '$domainName' creado exitosamente."

