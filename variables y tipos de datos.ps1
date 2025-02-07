#1 Variables y datos
Write-Output "Variables y datos -----------------------------------------------------------"
$variable1 = "Now"
$variable2 = "It´s Reyn Time"
$variable3 = 100
${variable 4} = 200
New-Variable -Name variable5 -Value 300
$variable5
$variable1
$variable2
$variable3
${variable 4}
$variable1+$variable2
$variable1 + ' '+ $variable2
$variable3 +${variable 4}
$variable3 - ${variable 4}
$variable1+$variable2
$$
$variable1+ $variable2
$^
$variable1+ $variable2
$?
$Error
Get-Help about_automatic_variables
Get-Help about_preference_variables

#2 Tipos de datos
Write-Output "Tipos de datos datos -----------------------------------------------------------"

[int]$variable6 = 100
[int]$variable7 = "Hola"
$variable6.GetType()

#3 Condiciones y Bucles
Write-Output "Condiciones y bucles -----------------------------------------------------------"

#3.1 Ciclo if
$condicion = $true
if ($condicion)
    {
        Write-Output "La condicion es verdadera"
    }else{
        Write-Output "La condicion es falsa"
    }
#3.2 Ciclo con elseif
$numero = 2
if( $numero -ge 3)
    {
        Write-Output "El numero [$numero] es mayor o igual a 3"
    }elseif ($numero -lt 2){
        Write-Output "El numero [$numero] es menor a 2"
    }else{
        Write-Output "El numero [$numero] es igual a 2"
    }
#3.3 Operador ternario
    #$mensaje = (Test-Path $path) ? "Path existe" : "Path no encontrado"
    #$mensaje
#3.4 Swicth
switch (3)
{
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuatro."}
}

switch (3)
{
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuatro."}
    }
    
switch (4)
{
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuatro."}
    4 {"[$_] es cuatro denuevo."}

}

switch (1, 5)
{
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuatro."}
    5 {"[$_] es cinco."}

}

Write-Output "Sin wilcard"
 switch ("seis")
 {
    1 {"[$_] es uno." ; Break}
    2 {"[$_] es dos." ; Break}
    3 {"[$_] es tres." ; Break}
    4 {"[$_] es cuatro." ; Break}
    5 {"[$_] es cinco." ; Break}
    "se*" {"[$_] coincide con se*." ; Break}
    default {
        "NO hay conincidencias con [$_]"
    }
}

Write-Output "Con wilcard"
 switch -Wildcard ("seis")
 {
    1 {"[$_] es uno." ; Break}
    2 {"[$_] es dos." ; Break}
    3 {"[$_] es tres." ; Break}
    4 {"[$_] es cuatro." ; Break}
    5 {"[$_] es cinco." ; Break}
    "se*" {"[$_] coincide con se*." ; Break}
    default {
        "NO hay conincidencias con [$_]"
    }
}

$email = 'antonio.yanez@udc.es'
$email2 = 'antonio.yanez@usc.gal'
$url = 'https://www.dc.fi.udc.es/~afyanez/Docencia/2023'
switch -Regex ($url, $email, $email2) {
    '^\w+.\w+@(udc|usc|edu)\.(es|gal)$' { "[$_] es una direccion de correo electronico academica" }
    '^ftp:\/\/.*$' { "[$_] es una direccion ftp" }
    '^((http|https):\/\/).*' { "[$_] es una direccion web, que utiliza [${matches[1]}]" }
}

#3.5 Operadores comparativos
Write-Output "Operadores comparativos"
1 -eq "1.0"
"1.0" -eq 1
#3.6 Operadores logicos


#4 Bucles
Write-Output "Bucles -----------------------------------------------------------"
for (($i = 0), ($j = 0);$i -lt 5; $i++)
{
    "`$i:$j"
    "`$j:$i"
}

Write-Output "Bucles -----------------------------------------------------------"
for (($i = 0), ($j = 0);$i -lt 5;$($i++;$j++))
{
    "`$i:$j"
    "`$j:$i"
}

$ssoo = "freebsd", "opensd", "solaris", "fedora", "ubuntu", "netbsd"
foreach ($so in $ssoo)
{
    Write-Host $so
}

foreach($archivo in Get-ChildItem)
{
    if($archivo.length -ge 10KB)
    {
        Write-Host $archivo -> [($archivo.length)]
    }
}

$num = 0

while ($num -ne 3)
{
    $num++
    Write-Host $num
}

$num = 0
while ($num -ne 5)
{
    if($num -eq 1) { $num = $num + 3 ; Continue}
    $num++
    Write-Host $num
}

$valor = 5
$multiplicacion = 1
do
{
    $multiplicacion = $multiplicacion * $valor
    $valor--
}
while($valor -gt 0)

Write-Host $multiplicacion


$valor = 5
$multiplicacion = 1
do
{
    $multiplicacion = $multiplicacion * $valor
    $valor--
}
until($valor -eq 0)

Write-Host $multiplicacion


$num = 10

for($i =  2; $i -lt 10; $i++){
    $num = $num+$i
    if ($i -eq 5){Break}
}

Write-Host $num
Write-Host $i



$cadena = "Hola, buenas tardes"
$cadena2 = "Hola, buenas noches"

switch -Wildcard ($cadena, $cadena2)
{
    "Hola, buenas*" {"[$_] coincide con [Hola, buenas*]"}
    "Hola, bue*" {"[$_] coincide con [Hola nue*]"}
    "Hola, *" {"[$_] coincide con [Hola,  *]"; break} 
    "Hola, buenas tardes" {"[$_] coincide con [Hola, buenas tardes]"}
 }


$num = 10

for($i =  2; $i -lt 10; $i++){
    $num = $num+$i
    if ($i -eq 5){Continue}
}

Write-Host $num
Write-Host $i



$cadena = "Hola, buenas tardes"
$cadena2 = "Hola, buenas noches"

switch -Wildcard ($cadena, $cadena2)
{
    "Hola, buenas*" {"[$_] coincide con [Hola, buenas*]"}
    "Hola, bue*" {"[$_] coincide con [Hola nue*]"}
    "Hola, *" {"[$_] coincide con [Hola,  *]"; Continue} 
    "Hola, buenas tardes" {"[$_] coincide con [Hola, buenas tardes]"}
 }


 #5 cmdlets
 Write-Output "Cmdlets -------------------------------------------------------------------------------"

 Get-Command -Type Cmdlet | Sort-Object -Property Noun | Format-Table -GroupBy Noun

 Get-Command -Name Get-ChildItem -Args Cert: -Syntax

 Get-Command -Name dir

 Get-Command -Noun WSManINstance

 Get-Service -Name "LSM" | Get-Member

 Get-Service -Name "LSM" | Get-Member -MemberType Property

 Get-Item .\test.txt | Get-Member -MemberType Method

 Get-Item .\test.txt | Select-Object Name, Length

 Get-Service | Select-Object -Last 5

 Get-Service | Select-Object -First 5

 Get-Service | Where-Object {$_.Status -eq "Running"}

 (Get-Item .\test.txt).IsReadOnly
 
 (Get-Item .\test.txt).IsReadOnly = 1
 
 Get-ChildItem *.txt

 (Get-Item .\test.txt).CopyTo("C:\Users\Administrador\prueba.txt")

 (Get-Item .\test.txt).Delete()
 Get-ChildItem *.txt


$miObjeto = New-Object PSObject
$miObjeto | Add-Member -MemberType NoteProperty -Name Nombre -Value "Miguel"
$miObjeto | Add-Member -MemberType NoteProperty -Name Edad -Value 23
$miObjeto | Add-Member -MemberType NoteProperty -Name Saludar -Value {Write-Host "Hola mundo"}

$miObjeto2 = New-Object -TypeName PSObject -Property @{
 Nombre = "Miguel"
  Edad  = 23
   }

 $miObjeto2 | Add-Member -MemberType ScriptMethod -Name Saludar -Value {Write-Host "Hola mundo"}
 $miObjeto2 | Get-Member

$miObjeto3 = [PSCustomObject] @{
   Nombre = "Miguel"
   Edad = 23
}

 $miObjeto3 | Add-Member -MemberType ScriptMethod -Name Saludar -Value {Write-Host "Hola mundo"}
 $miObjeto3 | Get-Member

Get-Process -Name Acrobat | Stop-Process

Get-Help -Full Get-Process

Get-Help -Full Stop-Process

Get-Process

Get-Process -Name Acrobat | Stop-Process

Get-Process

Get-Help  -Full Get-ChildItem

Get-Help -Full Get-Clipboard

Get-ChildItem *.txt | Get-Clipboard

Get-Help -Full Stop-Service

Get-Service

Get-Service Soopler | Stop-Service

Get-Service

"Soopler" | Stop-Service

Get-Service 
Get-Service 

Get-Service 

$miObjeto4 = [PSCustomObject] @{
Name = "Spooler"
}

$miObjeto4 | Stop-Service

Get-Service
Get-Service

#6 funciones 
Write-Output "Funciones ------------------------------------------------------------------------"

Get-Verb

function Get-Fecha 
{
Get-Date
}


Get-Fecha

Get-ChildItem -Path Function:\Get-*

Get-ChildItem -Path Function:\Get-Fecha | Remove-Item
Get-ChildItem -Path Function:\Get-*

function Get-Resta {
Param ([int]$num1, [int]$num2)
$resta = $num1-$num2
Write-Host "La resta de los dos parametros es $resta"
}

Get-Resta 10 5

Get-Resta -num2 10 -num1 5

Get-Resta -num2 10

function Get-Resta2 {
Param ([Parameter(Mandatory)][int]$num1, [int]$num2)
$resta = $num1-$num2
Write-Host "La resta de los dos parametros es $resta"
}

Get-Resta2 -num2 10

function Get-Resta3 {
[CmdletBinding()]
Param ([int]$num1, [int]$num2)
$resta=$num1-$num2 #Operacion que realiza la resta
Write-Host "La resta de los parametros es $resta" 
}

Get-Resta3

(Get-Command -Name Get-Resta3).Parameters.Keys

function Get-Resta4 {
[CmdletBinding()]
Param ([int]$num1, [int]$num2)
$resta=$num1-$num2 #Operacion que realiza la resta
Write-Verbose -Message "Operacion que se va a realizar es una resta de $num1  y $num2"
Write-Host "La resta de los parametros es $resta" 
}




#7 MOdulos
Write-Output "Modulos ---------------------------------------------------------------------------------"

Get-Module

Get-Module -ListAvailable

BitsTransfer
Get-Module
Remove-Module BitsTransfer
Get-Module

Get-Command -Module BitsTransfer

Get-Help BitsTransfer

$env:PSModulePath

Import-Module BitsTransfer
Get-Module


#8Scripts
Write-Output "Scripts ---------------------------------------------------------"
try
{
    Start-Process -Path $path -ErrorAction Stop
}
catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException]
{
    Write-Output "EL directiorio o fichero no ha sido encontrado: [$path]"
}
catch [System.IO.IOException]
{
    Write-Output "Error de IO con el archivo: [$path]"
}

throw "NO se puede encontrar la ruta: [$path]"

throw [System.IO.FileNotFoundException] "NO se puede encontrar la ruta: [$path]"

throw [System.IO.FileNotFoundException]::new()

throw [System.IO.FileNotFoundException]::new("NO se puede encontrar la ruta: [$path]")

throw (New-Object -TypeName System.IO.FileNotFoundException )

throw (New-Object -TypeName System.IO.FileNotFoundException -ArgumentList "NO se puede encontrar la ruta: [$path]")
Write-Output "Junaito"

trap
{
    Write-Output $PSItem.ToString()
}
throw [System.Exception]::new('primero')
throw [System.Exception]::new('segundo')
throw [System.Exception]::new('tercero')

function Backup-Registry {
    Param(
    [Parameter(Mandatory = $true)]
    [String]$rutaBackup
    )
    
    if (!(Test-Path -Path $rutaBackup)){
        New-Item -ItemType Directory -Path $rutaBackup | Out-Null
    }

    
    $logDirectory = "$env:C:\Users\Administrador\AppData\RegistryBackup"    
    $logFIle = Join-Path $logDirectory "backup-registry_log.txt"
    $logEntry = "$(Get-Date) -$env:USERNAME - Backup - $backupPath"
    
    if (!(Test-Path -Path $logDirectory)){
        New-Item -ItemType Directory -Path $logDirectory | Out-Null
    }

    Add-Content -Path $logFIle -Value $logEntry

    $nombreArchivo = "Backup-Registry_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")+".reg"
    $rutaArchivo = Join-Path -Path $rutaBackup -ChildPath $nombreArchivo


    $backupCount = 10 
    $backups = Get-ChildItem $backupDirectory -Filter *.reg | Sort-Object LastWriteTime -Descending
    if($backups.Count -gt $backupCount) {
        $backupsToDelete = $backups[$backupCount..($backups.Count -1)]
        $backupsToDelete | Remove Item -Force
    }       
    
    try{
        Write-Host "Realizando backup del registro del sistema en  $rutaArchivo...."
        reg export HKLM $rutaArchivo
        Write-Host "El backup del registro del sistema se ha realizado con éxito."
    }
    catch
    {
        Write-Host "Se ha producido un error al intentantar realizar el backup del registro del sistema: $_"

    }
}

Backup-Registry

#9 Administracion de PowerShell
Write-Output "Administracion de PowerShell ----------------------------------------------------------------------"
Get-Service
Get-Service -Name Spooler
Get-Service -DisplayName Hora*
Get-Service | Where-Object {$_.Status -eq "Running"}
Get-Service | Where-Object {$_.StartType -eq "Automatic"} | Select-Object Name, StartType
Get-Service -DependentServices Spooler
Get-Service -RequiredServices Fax
Stop-Service -Name Spooler -Confirm -PassThru
Start-Service -Name Spooler -Confirm -PassThru
Start-Service -Name StiSvc 
Suspend-Service -Name StiSvc -Confirm -PassThru
Suspend-Service -Name Spooler
Restart-Service -Name StiSvc -Confirm -PassThru
Set-Service -Name sacsvr -DisplayName "Servicio de sacsvr"
Set-Service -Name BITS -StartupType Automatic -Confirm -PassThru | Select-Object Name, StartType
Set-Service -Name BITS -Description "Transferencia de archivos en segundopplano mediante el uso de ancho de banda de red (BITS)"
Get-CimInstance Win32_Service -Filter 'Name = BITS' | Format-List Name, Description
Set-Service -Name Spooler -Status Running -Confirm -PassThru
Set-Service -Name StiSvc -Status Paused -Confirm -PassThru
Set-Service -Name BITS -Status Stopped -Confirm -PassThru

Get-Process
Get-Process -Name Acrobat
Get-Process -Name Search*
Get-Process -Id 1348
Get-Process WINWORD -FileVersionInfo
Get-Process WINWORD -IncludeUserName
Get-Process WinWORD -Module
Stop-Process -Name Acrobat -Confirm -PassThru 
Stop-Process -ID 10940 -Confirm -PassThru 
Get-Process -Name Acrobat | Stop-Process -Confirm -PassThru
Start-Process -FilePath "C:\"
Start-Process -FilePath "C:\Windows\System32\cmd.exe" -ArgumentList "/c mkdir NuevaCarpeta" -WorkingDirectory "C:\" -PassThru
Start-Process -FilePath "C:\Windows\System32\notepad.exe" -WindowStyle "Maximized" -PassThru
Start-Process -FilePath "C:\txt.txt" -Verb Print -PassThru

Get-Process -Name notep*
Wait-Process -Name notepad
Get-Process -Name notep*

Get-Process -Name notepad
Wait-Process -Id 11568
Get-Process -Name notep*

Get-Process -Name notep*
Get-Process -Name notepad | Wait-Process

Get-LocalUser
Get-LocalUser -Name Administrador | Select-Object

Get-LocalGroup 
Get-LocalGroup -Name Administradores
New-LocalUser -Name "Usuario1" -Description "Usuario de prueba 1" -NoPassword

New-LocalUser -Name "Usuario2" -Description "Usuario de prueba 2" -Password (ConvertTo-SecureString -AsPlainText "12345" -Force)
Get-LocalUser -Name "Usuario1"
Remove-LocalUser -Name "Usuario1"
Get-LocalUser -Name "Usuario1"

Get-LocalUser -Name "Usuario2"
Get-LocalUser -Name "Usuario2" | Remove-LocalUser
Get-LocalUser -Name "Usuario2"

New-LocalGroup -Name 'Grupo1' -Description 'Grupo de prueba 1'
Add-LocalGroupMember -Group Grupo1 -Member Usuario2 -Verbose

Get-LocalGroupMember Grupo1

Remove-LocalGroupMember -Group Grupo1 -Member Usuario1
Remove-LocalGroupMember -Group Grupo1 -Member Usuario2
Get-LocalGroupMember Grupo1

Get-LocalGroup -Name "Grupo1"
Remove-LocalGroup -Name "Grupo1"
Get-LocalGroup -Name "Grupo1"
 

