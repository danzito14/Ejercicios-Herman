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

$miIbjeto3 = [PSCustomObject] @{
   Nombre = "Miguel"
   Edad = 23
}

 $miObjeto2 | Add-Member -MemberType ScriptMethod -Name Saludar -Value {Write-Host "Hola mundo"}
 $miObjeto2 | Get-Member

Get-Process -Name Acrobat | Stop-Process

Get-Help -Full Get-Process

Get-Help -Full Stop-Process

Get-Process

Get-Process -Name Acrobat | Stop-Process

Get-Process

Get-Help  -Full Get-ChildItem

Get-Help -Full Get-Clipboard

Get-ChildItem *.txt | Get-Clipboard