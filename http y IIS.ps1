function instalar_apache24 {

    do{
            Write-Host 'Instalación de Apache24'
            Write-Host '1.- Apache2 version LTS'
            Write-Host '2.- Apache2 version dev-build'
            $selectVersion = Read-Host 'Que version del Apache2 quiere instalar? '

             if ($selectVersion -match "^\d+$") {
        break
            } else {
            Write-Host "Opción invalida."
            }
    }while ($true)

            # Condicional para verificar que version instalar
            if ($selectVersion -eq 1) {

                if (Test-Path 'C:\Apache24' -PathType Container) {
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

                # Bucle para preguntar por un puerto no utilizado
                $port = $null
                do {
                    
                        do {
                        $port = Read-Host 'Seleccione un puerto para instalar el servicio (debe ser un número menor a 500)'

                        # Validar si es un número
                        if ($port -match "^\d+$") {
                            $port = [int]$port  # Convertir a entero
                            if ($port -lt 500) {
                                break  # Si es válido, salir del bucle interno
                            } else {
                                Write-Host "Opción inválida: El número debe ser menor a 500"
                            }
                        } else {
                            Write-Host "Opción inválida: Debe ingresar solo números"
                        }
                    } while ($true)

                    $portInUse = (Test-NetConnection -ComputerName $env:COMPUTERNAME -Port $port -InformationLevel Quiet)

                    if ($portInUse -eq $true) {
                        Write-Host "Puerto en uso. Seleccione otro"
                    }

                } while ($portInUse -eq $true)

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

                # Sacamos la dirección IP del adaptador que estemos usando
                $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                # Mnesajes finales para probar el servicio
                Write-Host 'Se ha instalado  la version 2.4.63'
                Write-Host "La pagina default esta en $ipAddress`:$port o http://localhost:$port"
                break
            }
            elseif ($selectVersion -eq 2) {
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

                # Bucle para preguntar por un puerto no utilizado
                $port = $null
                do {
                    
                        do {
                        $port = Read-Host 'Seleccione un puerto para instalar el servicio (debe ser un número menor a 500)'

                        # Validar si es un número
                        if ($port -match "^\d+$") {
                            $port = [int]$port  # Convertir a entero
                            if ($port -lt 500) {
                                break  # Si es válido, salir del bucle interno
                            } else {
                                Write-Host "Opción inválida: El número debe ser menor a 500"
                            }
                        } else {
                            Write-Host "Opción inválida: Debe ingresar solo números"
                        }
                    } while ($true)

                    $portInUse = (Test-NetConnection -ComputerName $env:COMPUTERNAME -Port $port -InformationLevel Quiet)

                    if ($portInUse -eq $true) {
                        Write-Host "Puerto en uso. Seleccione otro"
                    }

                } while ($portInUse -eq $true)

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

                # Sacamos la dirección IP del adaptador que estemos usando
                $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                # Mnesajes finales para probar el servicio
                Write-Host 'Se ha instalado  la version 2.4.63'
                Write-Host "La pagina default esta en $ipAddress`:$port o http://localhost:$port"
                break
            }
            else {
                Write-Host 'Opción invalida. Seleccione 1 o 2.'
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
            Write-Host "Opción invalida."
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
                # Descargamos la paquetería necesario para el instalar la versión DEV
                (New-Object System.Net.WebClient).DownloadFile("https://nginx.org/download/nginx-1.26.3.zip", "C:\Users\Administrador\Downloads\serviceNginx.zip")

                # Nos posicionamos en esta ruta para expandir lo que hemos descargado
                Set-Location "C:\Users\Administrador\Downloads\"
                Expand-Archive -Path "C:\Users\Administrador\Downloads\serviceNginx.zip" -DestinationPath "C:\" -Force

                # Bucle para preguntar por un puerto no utilizado
                $port = $null
                do {
                    
                    do {
                        $port = Read-Host 'Seleccione un puerto para instalar el servicio (debe ser un número menor a 500)'

                        # Validar si es un número
                        if ($port -match "^\d+$") {
                            $port = [int]$port  # Convertir a entero
                            if ($port -lt 500) {
                                break  # Si es válido, salir del bucle interno
                            } else {
                                Write-Host "Opción inválida: El número debe ser menor a 500"
                            }
                        } else {
                            Write-Host "Opción inválida: Debe ingresar solo números"
                        }
                    } while ($true)


                    $portInUse = (Test-NetConnection -ComputerName $env:COMPUTERNAME -Port $port -InformationLevel Quiet)

                    if ($portInUse -eq $true) {
                        Write-Host "Puerto en uso. Seleccione otro"
                    }

                } while ($portInUse -eq $true)
                # Ruta del archivo httpd.conf
                $filePath = 'C:\nginx-1.26.3\conf\nginx.conf'
                $fileContent = Get-Content -Path $filePath
                $fileContent = $fileContent -replace 'listen       80', "listen       $port"
                $fileContent | Set-Content -Path $filePath

                # Iniciamos el servicio 
                Set-Location "C:\nginx-1.26.3"
                start .\nginx.exe

                # Sacamos la dirección IP del adaptador que estemos usando
                $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                # Mnesajes finales para probar el servicio
                Write-Host 'Se ha instalado la versión Ngnix LTS 1.26.3'
                Write-Host "Ve a $ipAddress`:$port"
                Write-Host ' '
                
                break
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
                # Descargamos la paquetería necesario para el instalar la versión DEV
                (New-Object System.Net.WebClient).DownloadFile("https://nginx.org/download/nginx-1.27.4.zip", "C:\Users\Administrador\Downloads\serviceNginx-dev.zip")

                # Nos posicionamos en esta ruta para expandir lo que hemos descargado
                Set-Location "C:\Users\Administrador\Downloads\"
                Expand-Archive -Path "C:\Users\Administrador\Downloads\serviceNginx-dev.zip" -DestinationPath "C:\" -Force

                # Bucle para preguntar por un puerto no utilizado
                $port = $null

                do {
                    
                        do {
                        $port = Read-Host 'Seleccione un puerto para instalar el servicio (debe ser un número menor a 500)'

                        # Validar si es un número
                        if ($port -match "^\d+$") {
                            $port = [int]$port  # Convertir a entero
                            if ($port -lt 500) {
                                break  # Si es válido, salir del bucle interno
                            } else {
                                Write-Host "Opción inválida: El número debe ser menor a 500"
                            }
                        } else {
                            Write-Host "Opción inválida: Debe ingresar solo números"
                        }
                    } while ($true)

                    $portInUse = (Test-NetConnection -ComputerName $env:COMPUTERNAME -Port $port -InformationLevel Quiet)

                    if ($portInUse -eq $true) {
                        Write-Host "Puerto en uso. Seleccione otro"
                    }

                } while ($portInUse -eq $true)

                # Ruta del archivo httpd.conf
                $filePath = 'C:\nginx-1.27.4\conf\nginx.conf'
                $fileContent = Get-Content -Path $filePath
                $fileContent = $fileContent -replace 'listen       80', "listen       $port"
                $fileContent | Set-Content -Path $filePath

                # Iniciamos el servicio 
                Set-Location "C:\nginx-1.27.4"
                start .\nginx.exe

                # Sacamos la dirección IP del adaptador que estemos usando
                $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

                # Mnesajes finales para probar el servicio
                Write-Host 'Se ha instalado  nginx Dev-Build 1.27.4'
                Write-Host "La pagina default esta en $ipAddress`:$port o http://localhost:$port"

                break
            }
            else {
                Write-Host 'Opción invalida. Seleccione 1 o 2.'
            }
            break

}


function instalar_iis () {

        # IIS
         # Comando para instalarr IIS, se necesita Internet
            Install-WindowsFeature web-server -IncludeManagementTools > $null 2>&1

            $port = $null
              do {
                    
                        do {
                        $port = Read-Host 'Seleccione un puerto para instalar el servicio (debe ser un número menor a 500)'

                        # Validar si es un número
                        if ($port -match "^\d+$") {
                            $port = [int]$port  # Convertir a entero
                            if ($port -lt 500) {
                                break  # Si es válido, salir del bucle interno
                            } else {
                                Write-Host "Opción inválida: El número debe ser menor a 500"
                            }
                        } else {
                            Write-Host "Opción inválida: Debe ingresar solo números"
                        }
                    } while ($true)

                    $portInUse = (Test-NetConnection -ComputerName $env:COMPUTERNAME -Port $port -InformationLevel Quiet)

                    if ($portInUse -eq $true) {
                        Write-Host "Puerto en uso. Seleccione otro"
                    }

                } while ($portInUse -eq $true)
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
        

while ($true) {
    Write-Host '1.- servicio2'
    Write-Host '2.- Servicio Nginx'
    Write-Host '3.- Servicio IIS'
    Write-Host 'Presione cualquier tecla para salir'

    $serviceOption = Read-Host 'Que servicio quiere instalar? '

    switch ($serviceOption) {
        1 {
            instalar_apache24}
        2 {
            instalar_nginx
                   }
        3 {
            instalar_iis
        }
    }

    $continueInstallation = Read-Host '¿Quiere continuar presione S, otra tecla para terminar'
    if ($continueInstallation -ne 'S' -and $continueInstallation -ne 's') {
        break
    }


}

