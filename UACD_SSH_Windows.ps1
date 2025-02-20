#Para obtener los datos de los adaptadores funciona igual que ipconfig
Get-NetIPConfiguration

#Para instalar el servicio de SSH, se ocupa internet para esta acción
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

#Comando para iniciar el servicio de manera automatica cuando se encienda el equipo
set-service -Name ssh-agent -StartupType 'Automatic'
set-service -Name sshd -StartupType 'Automatic'

#iniciar el servicio 
start-service sshd

#verificar que el servicio este corriendo
Get-NetTCPConnection -State Listen|where {$_.LocalPort -eq '22'}

#agregar una regla al firewall para el ssh
Enable-NetFirewallRule -name *OpenSSH-Server*
#Ver que si se creo la regla en el firewall
Get-NetFirewallRule -Group "OpenSSH Server"