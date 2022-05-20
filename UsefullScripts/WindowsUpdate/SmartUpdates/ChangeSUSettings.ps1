#Requires -Module ServerEye.PowerShell.helper
<#
    .SYNOPSIS
    Setzt die Einstellungen f�r die Verz�gerung und die Installation Tage im Smart Updates
    
    .DESCRIPTION
     Setzt die Einstellungen f�r die Verz�gerung und die Installation Tage im Smart Updates

    .PARAMETER CustomerId
    ID des Kunden bei dem die Einstellungen ge�ndert werden sollen.

    .PARAMETER ViewfilterName
    Name der Gruppe die ge�ndert werden soll

    .PARAMETER UpdateDelay
    Tage f�r die Update Verz�gerung.

    .PARAMETER installDelay
    Tage f�r die Installation

    .PARAMETER categories
    Kategorie die in einer Gruppe enthalten sein soll
    
    .PARAMETER AuthToken
    Either a session or an API key. If no AuthToken is provided the global Server-Eye session will be used if available.

    .EXAMPLE 
    .\ChangeSUSettings.ps1 -AuthToken "ApiKey" -CustomerId "ID des Kunden" -UpdateDelay "Tage f�r die Verz�gerung" -installDelay "Tage f�r die Installation"
    
    .EXAMPLE
    .\ChangeSUSettings.ps1 -AuthToken "ApiKey" -CustomerId "ID des Kunden" -UpdateDelay "Tage f�r die Verz�gerung" -installDelay "Tage f�r die Installation" -categories MICROSOFT
    
    .EXAMPLE
    .\ChangeSUSettings.ps1 -AuthToken "ApiKey" -CustomerId "ID des Kunden" -UpdateDelay "Tage f�r die Verz�gerung" -installDelay "Tage f�r die Installation" -ViewfilterName "Name einer Gruppe"
    
    .EXAMPLE 
    Get-SECustomer -AuthToken $authtoken| %{.\ChangeSUSettings.ps1 -AuthToken $authtoken -CustomerId $_.CustomerID -ViewfilterName "ThirdParty Server" -UpdateDelay 30 -installDelay 7}
#>



Param ( 
    [Parameter(Mandatory = $true)]
    [alias("ApiKey", "Session")]
    $AuthToken,
    [parameter(ValueFromPipelineByPropertyName, Mandatory = $true)]
    $CustomerId,
    [Parameter(Mandatory = $false)]
    $ViewfilterName,
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 30)]
    $UpdateDelay,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 60)]
    $installDelay,
    [Parameter(Mandatory = $false)]
    [ArgumentCompleter(
            {
                Get-SESUCategories 
            }
        )]
    [ValidateScript(
            {
                $categories = Get-SESUCategories
                $_ -in $categories
            }
        )]
    $categories
)

function Get-SEViewFilters {
    param (
        $AuthToken,
        $CustomerID
    )
    $CustomerViewFilterURL = "https://pm.server-eye.de/patch/$($CustomerID)/viewFilters"
                    
    if ($authtoken -is [string]) {
        try {
            $ViewFilters = Invoke-RestMethod -Uri $CustomerViewFilterURL -Method Get -Headers @{"x-api-key" = $authtoken } | Where-Object { $_.vfId -ne "all" }
            $ViewFilters = $ViewFilters | Where-Object { $_.vfId -ne "all" }
            return $ViewFilters 
        }
        catch {
            Write-Error "$_"
        }
                        
    }
    else {
        try {
            $ViewFilters = Invoke-RestMethod -Uri $CustomerViewFilterURL -Method Get -WebSession $authtoken
            $ViewFilters = $ViewFilters | Where-Object { $_.vfId -ne "all" }
            return $ViewFilters 
                            
                            
        }
        catch {
            Write-Error "$_"
        }
    }
}

function Get-SEViewFilterSettings {
    param (
        $AuthToken,
        $CustomerID,
        $ViewFilter
    )
    $GetCustomerViewFilterSettingURL = "https://pm.server-eye.de/patch/$($customerId)/viewFilter/$($ViewFilter.vfId)/settings"
    if ($authtoken -is [string]) {
        try {
            $ViewFilterSettings = Invoke-RestMethod -Uri $GetCustomerViewFilterSettingURL -Method Get -Headers @{"x-api-key" = $authtoken }
            Return $ViewFilterSettings
        }
        catch {
            Write-Error "$_"
        }
    
    }
    else {
        try {
            $ViewFilterSettings = Invoke-RestMethod -Uri $GetCustomerViewFilterSettingURL -Method Get -WebSession $authtoken
            Return $ViewFilterSettings

        }
        catch {
            Write-Error "$_"
        }
    }
}

function Set-SEViewFilterSetting {
    param (
        $AuthToken,
        $ViewFilterSetting,
        $UpdateDelay,
        $installDelay
    )
    if ($installDelay) {
        $ViewFilterSetting.installWindowInDays = $installDelay
    }
    else {
        $ViewFilterSetting.installWindowInDays = $ViewFilterSetting.installWindowInDays
    }
    if ($UpdateDelay) {
        $ViewFilterSetting.delayInstallByDays = $UpdateDelay
    }
    else {
        $ViewFilterSetting.delayInstallByDays = $ViewFilterSetting.delayInstallByDays
    }
    $body = $ViewFilterSetting | Select-Object -Property installWindowInDays, delayInstallByDays, categories, downloadStrategy, maxScanAgeInDays, enableRebootNotify, maxRebootNotifyIntervalInHours | ConvertTo-Json

    $SetCustomerViewFilterSettingURL = "https://pm.server-eye.de/patch/$($ViewFilterSetting.customerId)/viewFilter/$($ViewFilterSetting.vfId)/settings"
    if ($authtoken -is [string]) {
        try {
            Invoke-RestMethod -Uri $SetCustomerViewFilterSettingURL -Method Post -Body $body -ContentType "application/json"  -Headers @{"x-api-key" = $authtoken } | Out-Null
            Write-Output "Alle Einstellungen erfogreich gesetzt."
        }
        catch {
            Write-Error "$_"
        }
    
    }
    else {
        try {
            Invoke-RestMethod -Uri $SetCustomerViewFilterSettingURL -Method Post -Body $body -ContentType "application/json" -WebSession $authtoken | Out-Null
            Write-Output "Alle Einstellungen erfogreich gesetzt."
        }
        catch {
            Write-Error "$_"
        }
    }
}

$AuthToken = Test-SEAuth -AuthToken $AuthToken

if ($ViewfilterName) {
    $Groups = Get-SEViewFilters -AuthToken $AuthToken -CustomerID $CustomerID | Where-Object { $_.name -eq $ViewfilterName }
}
else {
    $Groups = Get-SEViewFilters -AuthToken $AuthToken -CustomerID $CustomerID
}


foreach ($Group in $Groups) {
    Write-Debug "$categories before If"
    if ($categories) {
        Write-Debug "$categories in IF"
        $GroupSettings = Get-SEViewFilterSettings -AuthToken $AuthToken -CustomerID $CustomerID -ViewFilter $Group | Where-Object { $_.categories.ID -contains $categories }
        Write-Debug "$GroupSettings categories"
    }
    else {
        $GroupSettings = Get-SEViewFilterSettings -AuthToken $AuthToken -CustomerID $CustomerID -ViewFilter $Group
        Write-Debug "$GroupSettings not categories"
    }
    
    foreach ($GroupSetting in $GroupSettings) {

        Set-SEViewFilterSetting -AuthToken $AuthToken -ViewFilterSetting $GroupSetting -UpdateDelay $UpdateDelay -installDelay $installDelay
  
    }
}