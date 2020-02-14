$groupsName = "RugsUsa_Analyzer", "RugsUsa_Professional", "RugsUSA" , "RugsUSA Sales"

foreach($group in $groupsName){
    $miembros=Get-ADGroupMember $group -recursive 
    Write-Host "-------------Miembros de " $group "------------------------"$miembros.count `n
    #Get-ADGroup -Properties * -Identity $group
    $miembros.name
}