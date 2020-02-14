 Param(
 #Para diferenciar los dos distintos parametros de entrada, lo hago con posiciones
 #Por lo tanto el comando se ejecuta indicando el nombre de los parametros servidor y o fichero
    [Parameter(Position=0)]
    [string] $servidor,
    [Parameter(Position=1)]
    [ValidateScript({
    #La validacion de que existe el fichero
        If (Test-Path $_ -PathType 'Leaf') {
            $True
        } Else {
            Throw "$_ En la ruta especificada no existe archivo"           
            Break
        }
    })]
    [ValidateScript({
    #Validacion de que la extension es la deseada
        If ((Get-Item $_ | select -Expand Extension) -eq ".csv") {
            $True
        } Else {
           Throw "$_ la extension del archivo no es .csv"          
           Break
        }
    })]
    [string]$fichero
)
Function checkStatusDisk([string]$arg) {

##Comprobar que es alcanzable con un unico ping de 16 bytes y que devuelva Booleano, sin devolver errores adicionales
    if(Test-Connection -Cn $arg -BufferSize 16 -Count 1 -ErrorAction 0 -quiet){ 
    #Obtener datos de los discos por host        
        $disks = Get-WmiObject -ComputerName $arg -Class Win32_LogicalDisk -Filter "DriveType = 3";
        #Genero vacio mi array, para desde del bucle mostrarlo
        $discos= @()

         foreach($disk in $disks){ 
            
            $deviceID = $disk.DeviceID;
	        [float]$espacioTotal = [Math]::Round($disk.Size/1gb, 2);
	        [float]$espacioLibre = [Math]::Round($disk.FreeSpace/1gb, 2);
            [float]$espacioOcupado = [Math]::Round(($espacioTotal-$espacioLibre), 2);

            ##Para dar el format-table he tenido que crear un array de objetos tipo disco                        
             $disco = [PSCustomObject]@{
                    NombreHost     = $arg
                    NumeroDiscos = $disks.Count
                    IdDispositivo    = $deviceID
                    espacioTotal    = $espacioTotal
                    espacioLibre    = $espacioLibre
                    espacioOcupado    = $espacioOcupado
             }
             $discos += $disco

           ##Si no se necesita format table con un wirte-host seria suficiente
           # Write-Host "`t NombreHost="$arg
           # Write-Host "`t Numeros de discos="$disks.Count
           # Write-Host "`t Nombre disco="$deviceID
           # Write-Host "`t `t Espacio libre="$espacioLibre
           # Write-Host "`t `t Espacio Ocupado="$espacioOcupado
           # Write-Host "`t `t Espacio Total="$espacioTotal
            
            }
        #Muestro los datos de mi array con formato tabla.
        $discos | format-table
    }else{     
        Write-Host "El servidor con nombre $arg no es accesible" -BackgroundColor red -ForegroundColor yellow        
    }
}

if ($fichero){
    if ($servidor) { 
       checkStatusDisk($servidor)
    }

    #leer CSV delimitado por ; y indicando que la cabezera no esta en el archivo y es hots
    $ficheroAux = import-csv $fichero -Header hots -Delimiter ";"

    #Recorro cada lina de fichero y por cada una ejecuto mi funcion
    foreach($line in $ficheroAux.hots) { 
        checkStatusDisk($line)

    }
}ElseIf($servidor){
    checkStatusDisk($servidor)
}else{
    checkStatusDisk("localhost")
}
