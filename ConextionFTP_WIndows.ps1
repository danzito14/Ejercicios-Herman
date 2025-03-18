# Definir variables
$ftpServer = "192.168.1.79"
$ftpUser = "user"
$ftpPassword = "Repro1*3"
$downloadFolder = "$env:USERPROFILE\Downloads"



function solicitar_puerto {
    param (
        [string]$mensaje,
        [int]$limite_superior = 65535,
        [int]$limite_inferior = 1,
        [int]$puerto_existente = -1  # Para evitar repetir el puerto normal si estás pidiendo el SSL
    )

    do {
        $puerto = Read-Host $mensaje

        if ($puerto -match "^\d+$") {
            $puerto = [int]$puerto

            # Verifica si está en el rango permitido
            if ($puerto -lt $limite_inferior -or $puerto -gt $limite_superior) {
                Write-Host "Opción inválida: el puerto debe estar entre $limite_inferior y $limite_superior"
                continue
            }

            # Verifica si es igual al puerto normal (si aplica)
            if ($puerto -eq $puerto_existente -and $puerto_existente -ne -1) {
                Write-Host "Este puerto ya está siendo usado por otro servicio, elija otro."
                continue
            }

            # Llama a tu función de validación
            if (-not (validar_puerto -puerto $puerto)) {
                continue
            }

            # Verifica si está ocupado
            $portInUse = (Test-NetConnection -ComputerName $env:COMPUTERNAME -Port $puerto -InformationLevel Quiet)
            if ($portInUse) {
                Write-Host "El puerto $puerto ya está en uso. Intente con otro."
                continue
            }

            return $puerto  # ¡Todo válido!
        }
        else {
            Write-Host "Opción inválida: debe ingresar solo números."
        }
    } while ($true)
}



function validar_puerto {
    param (
        [int]$puerto
    )
    $puertos_ocupados = @(20,21,22,23,25,53,67,68,80,110,123,143,161,389,443,445,465,587,993,995,3306,3389,5432,5900,6379)

    if ($puerto -lt 1 -or $puerto -gt 65535) {
        Write-Host "Puerto inválido"
        return $false
    }
    elseif ($puerto -in $puertos_ocupados) {
        Write-Host "No se puede usar un puerto reservado"
        return $false
    }
    else {
        return $true
    }
}


function instalar_apache24 {

            param (
                [string]$fileName
             )

            # Condicional para verificar que version instalar


                if (Test-Path 'C:\Apache24' -PathType Container) {
                     Set-Location 'C:\Apache24\bin'
                    
                     Remove-Item -Path 'C:\Apache24' -Recurse -Force
                     Write-Host "El directorio 'C:\Apache24' ha sido eliminado."
                } else {
                     Write-Host "El directorio 'C:\Apache24' no existe."
                }
                Write-HOst "Descargando c++"
                (New-Object System.Net.WebClient).DownloadFile("https://vcredist.com/install.ps1", "C:\Users\Administrador\Downloads\vc.ps1")
                write-host "C++ descargado extrayendo archivos"
                # Nos posicionamos en esta ruta para expandir lo que hemos descargado
                Set-Location "C:\Users\Administrador\Downloads\"
                # Extraemos lo Apache y lo copeamos en la carpeta C:\
                Expand-Archive -Path "C:\Users\Administrador\Downloads\$fileName" -DestinationPath "C:\" -Force
                .\vc.ps1 

                # Nos posicionamos de nuevo en la ruta para instalar el servicio
                Set-Location "C:\Apache24\bin"
                .\httpd.exe -k install -n "Apache24LTS"

                # Nos devolvemos a la otra ruta
                Set-Location "C:\Apache24\bin"
                $res_ssl = $null
                do {
                    Write-Host "Quiere instalar el certificado SSL"
                    $res_ssl = Read-Host "Seleccione s/n"
                    if ($res_ssl -eq "s" -or $res_ssl -eq "n"){
                        Write-Host "Usted ha seleccionado que $res_ssl"
                        break
                    }else{
                        Write-Host "Ingrese s o n"
                }
                }while($true)


                write-host "Ha seleccionado que $res_ssl" -ForegroundColor Green


                if ($res_ssl -eq "n" ){

                     # Bucle para preguntar por un puerto no utilizado
                # Primero pedimos el puerto normal
                $port = solicitar_puerto -mensaje "Ingrese el puerto para el servicio (1-65535)" -limite_superior 65535
                 Write-Host "Puerto normal: $port"
 

                    # Ruta del archivo httpd.conf
                    $filePath = 'C:\Apache24\conf\httpd.conf'
                    # Obtenemos el contenido del contenido de http.conf
                    $fileContent = Get-Content -Path $filePath
                    # Reemplazamos el puerto 
                    $fileContent = $fileContent -replace 'Listen 80', "Listen $port"
                    $fileContent | Set-Content -Path $filePath
                    #Modificamos para que acepte conexiones desde cualquier IP en la red:
                    $fileContent = $fileContent -replace '#ServerName www.example.com:80', "ServerName localhost"
                    $fileContent | Set-Content -Path $filePath

                    # Iniciamos el servicio
                    net start "Apache24LTS"


                }elseif ($res_ssl -eq "s"){
                     # Bucle para preguntar por un puerto no utilizado
                # Primero pedimos el puerto normal
                $port = solicitar_puerto -mensaje "Ingrese el puerto para el servicio (1-65535)" -limite_superior 65535

                # Ahora pedimos el puerto SSL, asegurándonos que no sea igual al anterior
                $portssl = solicitar_puerto -mensaje "Ingrese el puerto para el servicio SSL (1-65535)" -limite_superior 65535 -puerto_existente $port

                Write-Host "Puerto normal: $port"
                Write-Host "Puerto SSL: $portssl"


                        $filePath = 'C:\Apache24\conf\httpd.conf'
                    # Obtenemos el contenido del contenido de http.conf
                    $fileContent = Get-Content -Path $filePath

                    $fileContent = $fileContent -replace 'Listen 80', "Listen $port"
                    $fileContent | Set-Content -Path $filePath

                    $fileContent = $fileContent -replace '#ServerName www.example.com:80', "ServerName localhost"
                    $fileContent | Set-Content -Path $filePath

                    #Descomentamos estas lineas del conf
                    $fileContent = $fileContent -replace '#LoadModule ssl_module modules/mod_ssl.so', 'LoadModule ssl_module modules/mod_ssl.so'
                    $fileContent | Set-Content -Path $filePath
               
                    $fileContent = $fileContent -replace '#Include conf/extra/httpd-ssl.conf', 'Include conf/extra/httpd-ssl.conf'
                    $fileContent | Set-Content -Path $filePath
                                        
                    $filePath_SSL = 'C:\Apache24\conf\extra\httpd-ssl.conf'

                    $fileContent_SSL = Get-Content -Path $filePath_SSL

                    $fileContent_SSL = $fileContent_SSL -replace 'Listen 443', "Listen $portssl"
                    $fileContent_SSL | Set-Content -Path $filePath_SSL

                    $fileContent_SSL = $fileContent_SSL -replace 'ServerName www.example.com:443', "ServerName localhost:$portssl"
                    $fileContent_SSL | Set-Content -Path $filePath_SSL

                    $fileContent = $fileContent -replace '#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so', 'LoadModule socache_shmcb_module modules/mod_socache_shmcb.so'
                    $fileContent | Set-Content -Path $filePath
                     
                    $fileContent_SSL = $fileContent_SSL -replace '<VirtualHost _default_:443>', "<VirtualHost _default_:$portssl>"                   
                    $fileContent_SSL | Set-Content -Path $filePath_SSL
                    #Aqui vamos a copear los certificados desde el escritorio hasta  a C:\Apache24\conf
                    Copy-Item -Path "C:\Users\Administrador\Desktop\server.key" -Destination "C:\Apache24\conf"

                    Copy-Item -Path "C:\Users\Administrador\Desktop\server.crt" -Destination "C:\Apache24\conf"
                    # Iniciamos el servicio
                    net start "Apache24LTS"
                
                }

                                # Sacamos la direcciÃ³n IP del adaptador que estemos usando
                $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
                # Mnesajes finales para probar el servicio
                Write-Host 'Se ha instalado  la version 2.4.63'
                Write-Host "La pagina default esta en $ipAddress`:$port o http://localhost:$port"
      

}



function instalar_nginx (){

            param (
                [string]$fileName
             )

                
                               # Nos posicionamos en esta ruta para expandir lo que hemos descargado
                Set-Location "C:\Users\Administrador\Downloads\"
                Expand-Archive -Path "C:\Users\Administrador\Downloads\$fileName" -DestinationPath "C:\" -Force

                #Preguntamos si quiere usar SSL
                 $res_ssl = $null
                do {
                    Write-Host "Quiere instalar el certificado SSL"
                    $res_ssl = Read-Host "Seleccione s/n"
                    if ($res_ssl -eq "s" -or $res_ssl -eq "n"){
                        Write-Host "Usted ha seleccionado que $res_ssl"
                        break
                    }else{
                        Write-Host "Ingrese s o n"
                }
                }while($true)


                write-host "Ha seleccionado que $res_ssl" -ForegroundColor Green


                if($res_ssl -eq "n"){
                        # Bucle para preguntar por un puerto no utilizado
                        # Primero pedimos el puerto normal
                         $port = solicitar_puerto -mensaje "Ingrese el puerto para el servicio (1-65535)" -limite_superior 65535

                         Write-Host "Puerto normal: $port"
                        # Ruta del archivo httpd.conf
                        $filePath = 'C:\nginx-1.26.3\conf\nginx.conf'
                        $fileContent = Get-Content -Path $filePath
                        $fileContent = $fileContent -replace 'listen       80', "listen       $port"
                        $fileContent | Set-Content -Path $filePath

                        # Iniciamos el servicio 
                        Set-Location "C:\nginx-1.26.3"
                        start .\nginx.exe

                        # Sacamos la direcciÃ³n IP del adaptador que estemos usando
                        $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                        # Mnesajes finales para probar el servicio
                        Write-Host 'Se ha instalado la versiÃ³n Ngnix LTS 1.26.3'
                        Write-Host "Ve a $ipAddress`:$port"
                        Write-Host ' '
                
                        break
               }
               elseif($res_ssl-eq "s"){
                        # Primero pedimos el puerto normal
                        $port = solicitar_puerto -mensaje "Ingrese el puerto para el servicio (1-65535)" -limite_superior 65535

                        # Ahora pedimos el puerto SSL, asegurándonos que no sea igual al anterior
                        $portssl = solicitar_puerto -mensaje "Ingrese el puerto para el servicio SSL (1-65535)" -limite_superior 65535 -puerto_existente $port

                        Write-Host "Puerto normal: $port"
                        Write-Host "Puerto SSL: $portssl"

                        # Ruta del archivo httpd.conf
                        $filePath = 'C:\nginx-1.26.3\conf\nginx.conf'
                        $fileContent = Get-Content -Path $filePath
                        $fileContent = $fileContent -replace 'listen       80', "listen       $port"
                        $fileContent | Set-Content -Path $filePath
                        
                        $fileContent[97] = "     server {"
                        $fileContent | Set-Content -Path $filePath

                        $fileContent = $fileContent -replace "    #    listen       443 ssl;", "        listen       $portssl ssl;"
                        $fileContent | Set-Content -Path $filePath
                        $fileContent = $fileContent -replace "    #    server_name  localhost;", '         server_name  localhost;'
                        $fileContent | Set-Content -Path $filePath
                        
                        $fileContent = $fileContent -replace "    #    ssl_certificate      cert.pem;", '         ssl_certificate      server.crt;'
                        $fileContent | Set-Content -Path $filePath
                        $fileContent = $fileContent -replace "    #    ssl_certificate_key  cert.key;", '         ssl_certificate_key  server.key;'
                        $fileContent | Set-Content -Path $filePath
                        
                        $fileContent = $fileContent -replace "    #    ssl_session_cache    shared:SSL:1m;", '        ssl_protocols TLSv1.2 TLSv1.3;'
                        $fileContent | Set-Content -Path $filePath
                        $fileContent[110] = "         location / {"
                        $fileContent | Set-Content -Path $filePath
                        $fileContent[111] = "             root   html;"
                        $fileContent | Set-Content -Path $filePath
                        $fileContent[112] = "             index  index.html index.htm;"
                        $fileContent | Set-Content -Path $filePath
                        $fileContent[113] = "         }"
                        $fileContent | Set-Content -Path $filePath
                        $fileContent[114] = "     }"
                        $fileContent | Set-Content -Path $filePath
                        # Iniciamos el servicio 

                        Copy-Item -Path "C:\Users\Administrador\Desktop\server.key" -Destination "C:\nginx-1.26.3\conf"

                        Copy-Item -Path "C:\Users\Administrador\Desktop\server.crt" -Destination "C:\nginx-1.26.3\conf"

                        Set-Location "C:\nginx-1.26.3"
                        start .\nginx.exe

                        # Sacamos la direcciÃ³n IP del adaptador que estemos usando
                        $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                        # Mnesajes finales para probar el servicio
                        Write-Host 'Se ha instalado la versiÃ³n Ngnix LTS 1.26.3'
                        Write-Host "Ve a $ipAddress`:$port"
                        Write-Host "Ve a $ipAddress`:$portssl"
                        Write-Host ' '

               }
  
}



function instalar_tomcat{
          param (
                [string]$fileName
             )
            # Condicional para verificar que version instalar


            Write-Host "Instalando Tomcat"
            Set-Location "C:\Users\Administrador\Downloads\"
            Expand-Archive -Path "C:\Users\Administrador\Downloads\$fileName" -DestinationPath "C:\" -Force
            $res_ssl = $null
                do {
                    Write-Host "Quiere instalar el certificado SSL"
                    $res_ssl = Read-Host "Seleccione s/n"
                    if ($res_ssl -eq "s" -or $res_ssl -eq "n"){
                        Write-Host "Usted ha seleccionado que $res_ssl"
                        break
                    }else{
                        Write-Host "Ingrese s o n"
                }
                }while($true)


                write-host "Ha seleccionado que $res_ssl" -ForegroundColor Green


                if($res_ssl -eq "n"){

                        # Primero pedimos el puerto normal
                        $port = solicitar_puerto -mensaje "Ingrese el puerto para el servicio (1-65535)" -limite_superior 65535

                        Write-Host "Puerto normal: $port"

                        $filePath = "C:\apache-tomcat-11.0.5\conf\server.xml"

                        $fileContent = Get-Content -Path $filePath

                        $fileContent = $fileContent -replace '<Connector port="8080" protocol="HTTP/1.1"', "   <Connector port=$port protocol=`"HTTP/1.1`""

                        $fileContent | Set-Content -Path $filePath

                        Copy-Item -Path "C:\Users\Administrador\Desktop\keystore.p12" -Destination "C:\apache-tomcat-11.0.5\conf"

                        Set-Location "C:\apache-tomcat-11.0.5\bin"
                        start ./tomcat11.exe

                        $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                         # Mnesajes finales para probar el servicio
                        Write-Host 'Se ha instalado la versiÃ³n Tomcat 11.0.5'
                        Write-Host "Ve a $ipAddress`:$port"
                        Write-Host "Ve a $ipAddress`:$portssl"
                        Write-Host ' '

                        }
               elseif($res_ssl-eq "s"){
                           # Primero pedimos el puerto normal
                            $port = solicitar_puerto -mensaje "Ingrese el puerto para el servicio (1-65535)" -limite_superior 65535

                            # Ahora pedimos el puerto SSL, asegurándonos que no sea igual al anterior
                            $portssl = solicitar_puerto -mensaje "Ingrese el puerto para el servicio SSL (1-65535)" -limite_superior 65535 -puerto_existente $port

                            Write-Host "Puerto normal: $port"
                            Write-Host "Puerto SSL: $portssl"

                            $filePath = "C:\apache-tomcat-11.0.5\conf\server.xml"

                            $fileContent = Get-Content -Path $filePath


                            $fileContent = $fileContent -replace '<Connector port="8080" protocol="HTTP/1.1"', "   <Connector port=`"$port`" protocol=`"HTTP/1.1`""

                            $fileContent | Set-Content -Path $filePath

                            $fileContent[86] = " "
                            $fileContent | Set-Content -Path $filePath
                            $fileContent[95] = " "
                            $fileContent | Set-Content -Path $filePath

                            $fileContent = $fileContent -replace ' <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"', " <Connector port=`"$portssl`" protocol=`"org.apache.coyote.http11.Http11NioProtocol`""
                            $fileContent | Set-Content -Path $filePath

                            $fileContent = $fileContent -replace '            <Certificate certificateKeystoreFile="conf/localhost-rsa.jks"', '                        <Certificate certificateKeystoreFile="conf/keystore.jks"'
                            $fileContent | Set-Content -Path $filePath

                            $fileContent = $fileContent -replace '                         certificateKeystorePassword="changeit" type="RSA" />', '                         certificateKeystorePassword="Password123" type="RSA"/>'

                            Copy-Item -Path "C:\Users\Administrador\Desktop\keystore.p12" -Destination "C:\apache-tomcat-11.0.5\conf"

                            Set-Location "C:\apache-tomcat-11.0.5\bin"
                            start ./service.bat "Install"
                            start-service -name Tomcat11

                            $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                             # Mnesajes finales para probar el servicio
                            Write-Host 'Se ha instalado la versiÃ³n Tomcat 11.0.5'
                            Write-Host "Ve a $ipAddress`:$port"
                            Write-Host "Ve a $ipAddress`:$portssl"
                            Write-Host ' '
                      }

        Write-Host "Por favor, reinicia el sistema o tu consola para aplicar los cambios de entorno."
    } else {
        Write-Host "No se encontró el JDK en la ruta esperada. Verifica manualmente."
    }


}



# Cambiar directorio a Descargas
Set-Location -Path $downloadFolder
Write-Host "Cambiado a la carpeta de descargas: $downloadFolder"

# Función para listar directorios y archivos FTP
function Get-FTPDirectory {
    param ([string]$ftpPath)
    
    $ftpRequest = [System.Net.FtpWebRequest]::Create($ftpPath)
    $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $ftpRequest.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPassword)
    
    try {
        $ftpResponse = $ftpRequest.GetResponse()
        $streamReader = New-Object System.IO.StreamReader $ftpResponse.GetResponseStream()
        $directoryList = $streamReader.ReadToEnd()
        $streamReader.Close()
        $ftpResponse.Close()
        
        $folders = @()
        $files = @()
        foreach ($line in ($directoryList -split "`n")) {
            $trimmedLine = $line.Trim()
            if ($trimmedLine -match "^d" -or $trimmedLine -match "<DIR>") {
                $folderName = ($trimmedLine -split "\s{2,}")[-1]
                $folders += $folderName.Trim()
            } else {
                $fileName = ($trimmedLine -split "\s{2,}")[-1]

                # Eliminar un posible prefijo numérico seguido de un espacio
                $fileName = $fileName -replace "^\d+\s", ""

                if ($fileName -match "\.tar$|\.zip$") {
                    $files += $fileName.Trim()
                }
            }
        }

        return @{Folders=$folders; Files=$files}
    } catch {
        Write-Host "Error al obtener la lista de directorios: $_"
        return @{Folders=@(); Files=@()}
    }
}


# Función para identificar el tipo de archivo
function Identify-FileType {
    param (
        [string]$fileName
    )
    
    if ($fileName -match "Apache") {
        Write-Host $fileName -ForegroundColor red
        Write-Host "Procediendo con la instalación"
        instalar_apache24 -fileName $fileName
    } elseif ($fileName -match "Nginx") {
        Write-Host $fileName -ForegroundColor Green
    } elseif ($fileName -match "Tomcat") {
        Write-Host $fileName -ForegroundColor Yellow
    } else {
        Write-Host $fileName
    }
}

# Función para descargar archivos usando Get
function Download-FTPFile {
    param (
        [string]$ftpPath,
        [string]$fileName
    )
    
    # Identificar el tipo de archivo antes de la descarga
    Identify-FileType -fileName $fileName
    
    $localFile = "$downloadFolder\$fileName"
    $ftpFullPath = "$ftpPath$fileName"
    
    Write-Host "Descargando $ftpFullPath a $localFile..."
    
    $ftpRequest = [System.Net.FtpWebRequest]::Create($ftpFullPath)
    $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
    $ftpRequest.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPassword)
    
    try {
        $ftpResponse = $ftpRequest.GetResponse()
        $responseStream = $ftpResponse.GetResponseStream()
        $fileStream = [System.IO.File]::Create($localFile)
        $responseStream.CopyTo($fileStream)
        $fileStream.Close()
        $responseStream.Close()
        $ftpResponse.Close()
        
        Write-Host "Archivo descargado exitosamente: $localFile"
    } catch {
        Write-Host "Error al descargar el archivo: $_"
    }
}

# Menú principal
$baseFtpPath = "ftp://$ftpServer/Servicios_http/"
do {
    Write-Host "\nContenido en: $baseFtpPath"
    $items = Get-FTPDirectory -ftpPath $baseFtpPath
    
    if ($items.Folders.Count -eq 0 -and $items.Files.Count -eq 0) {
        Write-Host "No se encontraron carpetas ni archivos en el servidor FTP."
        exit
    }
    
    Write-Host "\nCarpetas disponibles:"
    for ($i = 0; $i -lt $items.Folders.Count; $i++) {
        Write-Host "[$i] $($items.Folders[$i])"
    }
    Write-Host "[b] Volver a la carpeta anterior"
    Write-Host "[q] Salir"
    
    Write-Host "\nArchivos .tar y .zip en la carpeta actual:"
    for ($j = 0; $j -lt $items.Files.Count; $j++) {
        Write-Host "[$j] $($items.Files[$j])"
    }
    
    $choice = Read-Host "Seleccione una carpeta para entrar, un archivo para copiar o 'b' para volver"
    
    if ($choice -match "^\d+$" -and [int]$choice -lt $items.Folders.Count) {
        $baseFtpPath = "$baseFtpPath$($items.Folders[$choice])/"
    }
    elseif ($choice -eq 'b') {
        $baseFtpPath = $baseFtpPath -replace "[^/]+/$", ""
    }
    elseif ($choice -eq 'q') {
        break
    }
    elseif ($choice -match "^\d+$" -and [int]$choice -lt $items.Files.Count) {
        $fileName = $items.Files[[int]$choice]
        Download-FTPFile -ftpPath $baseFtpPath -fileName $fileName
    }
    else {
        Write-Host "Selección no válida. Intente nuevamente."
    }
} while ($true)
