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

    do{
            Write-Host 'InstalaciÃ³n de Apache24'
            Write-Host '1.- Apache2 version LTS'
            Write-Host '2.- Apache2 version dev-build'
            $selectVersion = Read-Host 'Que version del Apache2 quiere instalar? '

             if ($selectVersion -match "^\d+$") {
        break
            } else {
            Write-Host "OpciÃ³n invalida."
            }
    }while ($true)

            # Condicional para verificar que version instalar
            if ($selectVersion -eq 1) {

                if (Test-Path 'C:\Apache24' -PathType Container) {
                     Set-Location 'C:\Apache24\bin'
                    
                     Remove-Item -Path 'C:\Apache24' -Recurse -Force
                     Write-Host "El directorio 'C:\Apache24' ha sido eliminado."
                } else {
                     Write-Host "El directorio 'C:\Apache24' no existe."
                }
                # LTS
                # Descargamos los paquetes que vayamos a necesitar
                write-host "Descargando Apache"
                (New-Object System.Net.WebClient).DownloadFile("https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.63-250207-win64-VS17.zip", "C:\Users\Administrador\Downloads\serviceApache.zip")
                Write-HOst "Descargando c++"
                (New-Object System.Net.WebClient).DownloadFile("https://vcredist.com/install.ps1", "C:\Users\Administrador\Downloads\vc.ps1")
                write-host "C++ descargado extrayendo archivos"
                # Nos posicionamos en esta ruta para expandir lo que hemos descargado
                Set-Location "C:\Users\Administrador\Downloads\"
                # Extraemos lo Apache y lo copeamos en la carpeta C:\
                Expand-Archive -Path "C:\Users\Administrador\Downloads\serviceApache.zip" -DestinationPath "C:\" -Force
                write-host "Instalando C++"
                .\vc.ps1 
                write-host "C++ Instalado" -ForegroundColor Red

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
                break
            }
            elseif ($selectVersion -eq 2) {
                              if (Test-Path 'C:\Apache24' -PathType Container) {
                     Set-Location 'C:\Apache24\bin'
                    
                     Remove-Item -Path 'C:\Apache24' -Recurse -Force
                     Write-Host "El directorio 'C:\Apache24' ha sido eliminado."
                } else {
                     Write-Host "El directorio 'C:\Apache24' no existe."
                }
                # LTS
                # Descargamos los paquetes que vayamos a necesitar
                write-host "Descargando Apache"
                (New-Object System.Net.WebClient).DownloadFile("https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.63-250207-win64-VS17.zip", "C:\Users\Administrador\Downloads\serviceApache.zip")
                Write-HOst "Descargando c++"
                (New-Object System.Net.WebClient).DownloadFile("https://vcredist.com/install.ps1", "C:\Users\Administrador\Downloads\vc.ps1")
                write-host "C++ descargado extrayendo archivos"
                # Nos posicionamos en esta ruta para expandir lo que hemos descargado
                Set-Location "C:\Users\Administrador\Downloads\"
                # Extraemos lo Apache y lo copeamos en la carpeta C:\
                Expand-Archive -Path "C:\Users\Administrador\Downloads\serviceApache.zip" -DestinationPath "C:\" -Force
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
                break
            }
            else {
                Write-Host 'OpciÃ³n invalida. Seleccione 1 o 2.'
            }

}


function instalar_nginx (){
    do{
            Write-Host 'Instalacion de Nginx'
            Write-Host '1.- Nginx version LTS'
            Write-Host '2.- Nginx version dev-build'
            $selectVersion = Read-Host 'Que version del Nginx quiere instalar? '

             if ($selectVersion -match "^\d+$") {
        break
            } else {
            Write-Host "OpciÃ³n invalida."
            }
    }while($true)
            # Condicional para verificar que version instalar
            if ($selectVersion -eq 1) {
                 if (Test-Path 'C:\nginx-1.26.3' -PathType Container) {
                     Remove-Item -Path 'C:\nginx-1.26.3' -Recurse -Force
                     Write-Host "El directorio C:\nginx ha sido eliminado."
                } else {
                     Write-Host "El directorio C:\nginx no existe."
                }
                if (Test-Path 'C:\nginx-1.27.4' -PathType Container) {
                     Remove-Item -Path 'C:\nginx-1.27.4' -Recurse -Force
                     Write-Host "El directorio C:\nginx ha sido eliminado."
                } else {
                     Write-Host "El directorio C:\nginx no existe."
                }
                
                # LTS
                # Descargamos la paqueterÃ­a necesario para el instalar la versiÃ³n DEV
                (New-Object System.Net.WebClient).DownloadFile("https://nginx.org/download/nginx-1.26.3.zip", "C:\Users\Administrador\Downloads\serviceNginx.zip")

                # Nos posicionamos en esta ruta para expandir lo que hemos descargado
                Set-Location "C:\Users\Administrador\Downloads\"
                Expand-Archive -Path "C:\Users\Administrador\Downloads\serviceNginx.zip" -DestinationPath "C:\" -Force

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
                
                        break
               
               }
            }
            elseif ($selectVersion -eq 2) {

                if (Test-Path 'C:\nginx-1.27.4' -PathType Container) {
                     Remove-Item -Path 'C:\nginx-1.27.4' -Recurse -Force
                     Write-Host "El directorio C:\nginx ha sido eliminado."
                } else {
                     Write-Host "El directorio C:\nginx no existe."
                }
                if (Test-Path 'C:\nginx-1.26.3' -PathType Container) {
                     Remove-Item -Path 'C:\nginx-1.26.3' -Recurse -Force
                     Write-Host "El directorio C:\nginx ha sido eliminado."
                } else {
                     Write-Host "El directorio C:\nginx no existe."
                }
                # dev-build
                # Descargamos la paqueterÃ­a necesario para el instalar la versiÃ³n DEV
                (New-Object System.Net.WebClient).DownloadFile("https://nginx.org/download/nginx-1.27.4.zip", "C:\Users\Administrador\Downloads\serviceNginx-dev.zip")

                # Nos posicionamos en esta ruta para expandir lo que hemos descargado
                Set-Location "C:\Users\Administrador\Downloads\"
                Expand-Archive -Path "C:\Users\Administrador\Downloads\serviceNginx-dev.zip" -DestinationPath "C:\" -Force

                # Bucle para preguntar por un puerto no utilizado
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
                        $filePath = 'C:\nginx-1.27.4\conf\nginx.conf'
                        $fileContent = Get-Content -Path $filePath
                        $fileContent = $fileContent -replace 'listen       80', "listen       $port"
                        $fileContent | Set-Content -Path $filePath

                        # Iniciamos el servicio 
                        Set-Location "C:\nginx-1.27.4"
                        start .\nginx.exe

                        # Sacamos la direcciÃ³n IP del adaptador que estemos usando
                        $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                        # Mnesajes finales para probar el servicio
                        Write-Host 'Se ha instalado la versiÃ³n nginx-1.27.4'
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
                        $filePath = 'C:\nginx-1.27.4\conf\nginx.conf'
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

                        Copy-Item -Path "C:\Users\Administrador\Desktop\server.key" -Destination "C:\nginx-1.26.3\conf"

                        Copy-Item -Path "C:\Users\Administrador\Desktop\server.crt" -Destination "C:\nginx-1.26.3\conf"
                        # Iniciamos el servicio 
                        Set-Location "C:\nginx-1.27.4"
                        start .\nginx.exe

                        # Sacamos la direcciÃ³n IP del adaptador que estemos usando
                        $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                        # Mnesajes finales para probar el servicio
                        Write-Host 'Se ha instalado la versiÃ³n nginx-1.27.4'
                        Write-Host "Ve a $ipAddress`:$port"
                        Write-Host "Ve a $ipAddress`:$portssl"
                        Write-Host ' '
                
                        break
               
               }
            else {
                Write-Host 'OpciÃ³n invalida. Seleccione 1 o 2.'
            }
            break
            }
}


function instalar_iis () {

        # IIS
         # Comando para instalarr IIS, se necesita Internet
            Install-WindowsFeature web-server -IncludeManagementTools > $null 2>&1
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
            
                        Write-Host "Cambiando IIS al puerto $port..."
                        Set-WebBinding -Name "Default Web Site" -BindingInformation "*:80:" -PropertyName Port -Value $port

                        # Reinicia IIS para aplicar cambios
                        Write-Host "Reiniciando IIS..."
                        iisreset

                        # Abre el puerto en el Firewall
                        Write-Host "Abriendo el puerto $puerto en el firewall..."
                        New-NetFirewallRule -DisplayName "IIS Port $puerto" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $puerto


                        $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                        Write-Host 'Se ha instalado  IIS'
                        Write-Host "La pagina default esta en $ipAddress`:$port o http://localhost:$port"

            break
            }
            elseif($res_ssl-eq "s"){
                                            # Pedir puertos
                    $port = Read-Host "Ingrese el puerto para el servicio HTTP (1-65535)"
                    $portssl = Read-Host "Ingrese el puerto para el servicio HTTPS (1-65535)"

                    Write-Host "Puerto normal: $port"
                    Write-Host "Puerto SSL: $portssl"

                    # Ruta del certificado PFX
                    $pfxFilePath = "C:\Users\Administrador\Desktop\server.pfx"
                    $certPassword = ConvertTo-SecureString -String "pepezila99" -AsPlainText -Force

                    # Importar certificado
                    $cert = Import-PfxCertificate -FilePath $pfxFilePath -Password $certPassword -CertStoreLocation Cert:\LocalMachine\My
                    $certThumbprint = $cert.Thumbprint

                    # Eliminar bindings anteriores si existen
                    Remove-WebBinding -Name "Default Web Site" -Protocol "https" -Port 443 -ErrorAction SilentlyContinue
                    Remove-WebBinding -Name "Default Web Site" -Protocol "https" -Port $portssl -ErrorAction SilentlyContinue

                    # Crear nuevo binding HTTPS
                    New-WebBinding -Name "Default Web Site" -Protocol "https" -Port $portssl

                    # Asociar certificado con el binding usando netsh
                    netsh http delete sslcert ipport=0.0.0.0:$portssl > $null 2>&1
                    netsh http add sslcert ipport=0.0.0.0:$portssl certhash=$certThumbprint appid='{00112233-4455-6677-8899-AABBCCDDEEFF}' certstorename=MY

                    # Reiniciar IIS
                    iisreset

                    # Abrir puerto en el firewall
                    New-NetFirewallRule -DisplayName "IIS Port $portssl" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $portssl

                    # Mostrar dirección final
                    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.*' }).IPAddress | Select-Object -First 1
                    Write-Host "Sitio disponible en https://$ip`:$portssl"





                }

        }
while ($true) {
    # Preguntar por el método de instalación
    Write-Host 'Seleccione el método de instalación:'
    Write-Host '1.- HTTP'
    Write-Host '2.- FTP'
    
    $methodOption = Read-Host '¿Cómo desea instalar los servicios?'
    
    if ($methodOption -eq '2') {
        # Si elige FTP, ejecutar el script y salir
        Write-Host 'Ejecutando instalación por FTP...'
        & .\conect_ftp.ps1
        break
    } elseif ($methodOption -ne '1') {
        Write-Host 'Opción no válida. Intente de nuevo.'
        continue
    }

    # Si elige HTTP, continuar con el menú original
    while ($true) {
        Write-Host '1.- servicio2'
        Write-Host '2.- Servicio Nginx'
        Write-Host '3.- Servicio IIS'
        Write-Host 'Presione cualquier tecla para salir'

        $serviceOption = Read-Host '¿Qué servicio quiere instalar?'

        switch ($serviceOption) {
            '1' { instalar_apache24 }
            '2' { instalar_nginx }
            '3' { instalar_iis }
            default { Write-Host 'Opción no válida.' }
        }

        $continueInstallation = Read-Host '¿Quiere continuar? Presione S para continuar, otra tecla para terminar'
        if ($continueInstallation -ne 'S' -and $continueInstallation -ne 's') {
            break
        }
    }
    
    break  # Salir del bucle principal después de completar la instalación por HTTP
}
