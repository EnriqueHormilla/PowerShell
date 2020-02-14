#Set-ExecutionPolicy Unrestricted -Force
#Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force
function exportEvent ($server, $cert, $id) {
    #$cert=GetCert -name "ADWINSENSE" -password "password" -certsFolder ".\certs"
    #$cert= gci cert:\currentUser\My | where { $_.subject -like "*QlikClient*" }
    $xrfkey = GetXrfKey;
    $contentType = "application/json";
    $baseURL = "https://$($server):4242/qrs";
    $headers = @{
        "X-Qlik-xrfkey" = $xrfkey;
        "Accept"        = $contentType;
        "X-Qlik-User"   = "UserDirectory=internal;UserId=sa_repository"; `
    
    }
    try {
        add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
          public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
          }
        }
"@
    }
    catch { }
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    #$download = Invoke-RestMethod -Uri "$baseURL/event/full?Xrfkey=$xrfkey" -Method get -Headers $headers -ContentType 'application/json' -Certificate $cert
    $download = Invoke-RestMethod -Uri "$baseURL/event/full?filter=reloadTask.id+eq+$id&Xrfkey=$xrfkey" -Method get -Headers $headers -ContentType 'application/json' -Certificate $cert
    #return $download | where-object {$_.reloadTask.id -eq $id} | ConvertTo-Json -Depth 10
    return $download | ConvertTo-Json -Depth 10
}
function GetXrfKey() {
    $alphabet = $Null; For ($a = 97; $a -le 122; $a++) { $alphabet += , [char][byte]$a }
    For ($loop = 1; $loop -le 16; $loop++) {
        $key += ($alphabet | Get-Random)
    }
    return $key
}
function get_tasks_by_appId ($server, $cert, $id) {
    #$cert=GetCert -name "ADWINSENSE" -password "password" -certsFolder ".\certs"
    #$cert= gci cert:\currentUser\My | where { $_.subject -like "*QlikClient*" }
    $xrfkey = GetXrfKey;
    $contentType = "application/json";
    $baseURL = "https://$($server):4242/qrs";
    $headers = @{
        "X-Qlik-xrfkey" = $xrfkey;
        "Accept"        = $contentType;
        "X-Qlik-User"   = "UserDirectory=internal;UserId=sa_repository"; `
    
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    $triggers = Invoke-RestMethod -Uri "$baseURL/reloadtask/full?Xrfkey=$xrfkey&filter=app.id+eq+$id" -Method get -Headers $headers -ContentType 'application/json' -Certificate $cert
    #https://win-rt3mam3dedt:4242/qrs/reloadtask/full?Xrfkey=1234567890123456&filter=app.id eq 052774d2-fa55-401a-b93d-d606352554af
    return $triggers
}
function get_root_tasks($server, $cert, $id) {
    $pila = new-object system.collections.stack
    #$taskidInicial= $id
    $taskidInicial = Get-QlikTask -filter "id eq $id" -full   
    $pila.push($taskidInicial)
    $return = New-Object System.Collections.ArrayList
    while ($pila.count -gt 0) {
        $tmp = $pila.pop()
        $tmp2 = get_parent_tasks -server $server -Cert $($cert)  -id $($tmp.id)
        $dependencias = $tmp2.compositeRules.reloadTask
        if ($dependencias) {
            foreach ($d in $dependencias) {
                $pila.Push($d)
            }
        }
        else {
            if ($return.Count -eq 0) { $null = $return.add($tmp) }
            if (!($($return.id).Contains($tmp.id))) {
                $null = $return.add($tmp)
            }           
        }
    }
    return $return
}
function get_parent_tasks ($server, $cert, $id) {
    $xrfkey = GetXrfKey;
    $contentType = "application/json";
    $baseURL = "https://$($server):4242/qrs";
    $headers = @{
        "X-Qlik-xrfkey" = $xrfkey;
        "Accept"        = $contentType;
        "X-Qlik-User"   = "UserDirectory=internal;UserId=sa_repository"; `
    
    } 
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    $triggers = Invoke-RestMethod -Uri "$baseURL/event/full?filter=reloadTask.id+eq+$id&Xrfkey=$xrfkey" -Method get -Headers $headers -ContentType 'application/json' -Certificate $cert
    return $triggers
}
function get_task_children ($server, $cert, $id) {
    #$cert=GetCert -name "ADWINSENSE" -password "password" -certsFolder ".\certs"
    #$cert= gci cert:\currentUser\My | where { $_.subject -like "*QlikClient*" }
    $xrfkey = GetXrfKey;
    $contentType = "application/json";
    $baseURL = "https://$($server):4242/qrs";
    $headers = @{
        "X-Qlik-xrfkey" = $xrfkey;
        "Accept"        = $contentType;
        "X-Qlik-User"   = "UserDirectory=internal;UserId=sa_repository"; `
    
    } 
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    $triggers = Invoke-RestMethod -Uri "$baseURL/CompositeEvent/full?Xrfkey=$xrfkey&filter=compositeRules.reloadTask+ne+null+and+compositeRules.reloadTask.id+eq+$id" -Method get -Headers $headers -ContentType 'application/json' -Certificate $cert
    #https://win-rt3mam3dedt:4242/qrs/           CompositeEvent/full?Xrfkey=1234567890123456&filter=compositeRules.reloadTask+ne+null+and+compositeRules.reloadTask.id eq 72216ec8-c05e-43e0-9cbf-73eae48fddeb
    $return = @()
    foreach ($trigger in $($triggers.reloadTask)) {
        $return += Get-QlikTask -filter "id eq $($trigger.id)" -full
    }
    return $return
}
function get_task_tree ($server, $cert, $id) {
    $pila = new-object system.collections.stack
    #$taskidInicial= $id
    $taskidInicial = Get-QlikTask -filter "id eq $id" -full   
    $pila.push($taskidInicial)
    $return = @($pila)
    while ($pila.count -gt 0) {
        $tmp = $pila.pop()
        $dependencias = get_task_children -server $server -Cert $($cert)  -id $($tmp.id)
        if ($dependencias) {
            foreach ($d in $dependencias) {
                if (!$($return.id).Contains($($d.id))) {
                    $pila.Push($d)
                    $return += $d
                }
            }
        }
    }
    return $return
}
<# 
Puedes mirar lo siguiente en el server para ver qué tiene Rugs ahora mismo?

Número de licencias Professional OK
Número de licencias Analyzer OK

Recargas programadas/dia OK
Espacio utilizado en disco 50% (las app si)
Número de streams OK
Numero de aplicaciones OK
#>

#Import-Module Qlik-Cli
Import-Module "C:\Users\qlikservice\Desktop\Platform-QlikCLI\Qlik-Cli\Qlik-Cli.psd1"

$cert = Get-PfxCertificate "C:\Users\qlikservice\Desktop\enriqueRugs\centralnodemcl.sdggroup.com\client.pfx"
$server = "localhost" #$server = "WIN-QLIK"

#Conexion  externa, utilizando el certificado (no me ha funcionado desde local)
Connect-Qlik -Computername $server -Certificate $cert  -TrustAllCerts


#Número de streams asociados a ese cliente
$streams = Get-QlikStream -filter "name so 'rugs'"

Write-Host "Numero de streams asociados a ese nombre " $streams.count

$apps = @()
foreach ($stream in $streams) { 
    $apps += get-Qlikapp -filter "stream.id eq $($stream.id)" -full
}
#Numero de aplicaciones de dicho cliente
 
Write-Host "Numero de aplicaciones totales " $apps.count

#Tamaño total de las aplicaciones
$totalSize = 0
$numeroTasks = 0
#$numeroEvents= [int]0

foreach ($app in $apps) { 
     
    $totalSize += $app.fileSize

    $tasks = get_tasks_by_appId -server $server -cert $cert -id $app.id
    #Write-Host "-----------"
    #@($tasks).count
    #$tasks.name
    $numeroTasks += @($tasks).count

    # foreach($task in $tasks){
    #  $events+=exportEvent -server $server -cert $cert -id $task.id 
    #  $numeroEvents+=$events.Count
    # }
           
}
#$events | ConvertTo-Json -depth 100 | Out-File "C:\Users\qlikservice\Downloads\eventos-file.json"

$events | Out-File -FilePath C:\Users\qlikservice\Downloads\eventos-file.txt
$totalSize = [math]::Round(( $totalSize / 1GB), 2) 
Write-Host "Apps--> " $apps.Count
Write-Host "Tamaño de las apps--> " $totalSize "GB"
Write-Host "Tareas-->" $numeroTasks
Write-Host "Eventos-->" $numeroEvents



#get_tasks_by_appId -server $server -cert $cert -id  d99d8046-4c39-4a91-9c5a-4890bed84732