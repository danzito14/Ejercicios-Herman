#Comandos para instalar el servicio y reiniciarlo
Install-WindowsFeature -Name DHCP -IncludeManagementTools

try{
 $pdc = (Get-ADDomain).PDCEmulator

     Add-DhcpServerInDC -DnsName WIN-9LSTNUINFQG.midominio.local -IPAddress 192.168.1.86

    Add-DhcpServerv4Scope

    Get-DhcpServerv4Scope

    Set-DhcpServerv4optionValue -ScopeId 192.168.1.0 -DnsServer 192.168.1.86 -DnsDomain midominio.local -Router 192.168.1.86


}catch{
    Write-Output "Ha surgido un error, su servidor no cuenta con las herramientas \nnecesarias para ver y o crear su propio dominio"
    Write-Output "Desea instalar y crear su propio dominio, al final de la instalacion se reiniciara la maquina sola"
    confirm = $confirmacion

    if ($confirmacion = 'si' ){

        #Instalamos RSAT AD PowerShell, que es Remote Server Administration Tools, algunas veces no viene instalado por defecto
        Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature

        #Instalamos las herramientas para crear un dominio
        Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature

        Write-Output "Ingrese un nombre de dominio para su servidor"
        Install-ADDForest -DomainName "midominio.com"
    } elseif ($confirmacion = 'no'){
        Write-Output "Usted a decido no crear un dominio"
        Write-Output "Se seguira la creacion del servidor DHCP sin un dominio"

        Add-DhcpServerInDC -IPAddress 192.168.1.86
        Add-DhcpServerv4Scope
        Get-DchpServerv4Scope
        Set-DhcpServerv4optionValue -ScopeId 192.168.1.0 -DnsServer 192.168.1.86
    }

}

#Para ver las IP que se han dado
Get-DhcpServerv4Lease