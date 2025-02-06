function Backup-Registry {
    Param(
    
    [String]$rutaBackup = "c:\"
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
    
    $time = New-ScheduledTaskTrigger -At 20:14 -Daily
    
    $PS =  New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-Command `"Import-Module Backup-Registry -Force; Backup-Registry-rutaBackup 'c:\'`""
    
    Register-ScheduledTask -TaskName "Ejecutar Backup del registro del sistema" -Trigger $time -Action $PS     
    
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