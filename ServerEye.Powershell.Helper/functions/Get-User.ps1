 <#
    .SYNOPSIS
    Get a list of all Users. 
    
    .DESCRIPTION
    A list of all User with . 
    
    .PARAMETER AuthToken
    Either a session or an API key. If no AuthToken is provided the global Server-Eye session will be used if available.
    
#>
function Get-User {
    [CmdletBinding(DefaultParameterSetName='byFilter')]
    Param(
        [switch]
        $roles,
        $AuthToken

    )
    Begin{
        Update-SEHelper -Modulename "Servereye.powershell.api"
        Update-SEHelper -Modulename "Servereye.powershell.helper"
        $AuthToken = Test-Auth -AuthToken $AuthToken
    }
    
    Process {
        $users = Get-SeApiUserList -AuthToken $AuthToken
        foreach ($user in $users){

            if ($roles.IsPresent -eq $false){
                formatUser -user $user
            }else{
                formatRoles -user $user
            }
        }
    }        
    
    End {
    }
}

function formatUser($user) {
    [PSCustomObject]@{
        Username = if ($user.isGroup -eq $true) {
            $user.surname
        } else{
            ("$($user.prename) $($user.surname)".Trim()) 
        }
        EMail = $user.email
        Company = $user.companyName
        UserID = if ($user.isGroup -eq $true) {
            $user.gid
        }
        else  {
            $user.uid
        } 
    }
}
function formatRoles($user) {
    [PSCustomObject]@{
        Username = if ($user.isGroup -eq $true) {
            $user.surname
        } else{
            ("$($user.prename) $($user.surname)".Trim()) 
        }
        EMail = $user.email
        Company = $user.companyName
        UserID = if ($user.isGroup -eq $true) {
            $user.gid
        }
        else  {
            $user.uid
        } 
        Roles = $user.roles
    }
}