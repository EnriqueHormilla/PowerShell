$a = "<style>"
$a = $a + "BODY{background-color:#FFFFFF ;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{color: white;border-width: 1px;padding: 4px;border-style: solid;border-color: black;background-color:#0033FF}"
$a = $a + "TD{border-width: 1px;padding: 15px;border-style: solid;border-color: black;background-color:#D8D8D8}"
$a = $a + "</style>"

$datlog = Get-Date -Format "yyyyMMddTHH:mm"
$computerName = $env:COMPUTERNAME
$logTailName = "$($datlog)-$($computerName)_"

Get-EventLog -LogName System -ComputerName $env:COMPUTERNAME |

where { $_.EventId -eq 1074 } |

ForEach-Object {

    $rv = New-Object PSObject | Select-Object Date, User, Action, process, Reason, ReasonCode, Comment, Message

    if ($_.ReplacementStrings[4]) {

        $rv.Date = $_.TimeGenerated
        $rv.User = $_.ReplacementStrings[6]
        $rv.Process = $_.ReplacementStrings[0]
        $rv.Action = $_.ReplacementStrings[4]
        $rv.Reason = $_.ReplacementStrings[2]
        $rv.ReasonCode = $_.ReplacementStrings[3]
        $rv.Comment = $_.ReplacementStrings[5]
        $rv.Message = $_.Message
        $rv

    }

} | Select-Object Date, Action, Reason, User | ConvertTo-Html -head $a -body "<H2>Shutdown/Reboot  - HOST: $env:COMPUTERNAME</H2>" | Out-File "C:\Users\qlikservice\Desktop\reboot-10-02-2020.html" 