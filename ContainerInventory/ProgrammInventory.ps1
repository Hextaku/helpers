[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true)]
    [alias("ApiKey","Session")]
    $AuthToken,
    [string]
    $custID
)

# Check if module is installed, if not install it
if (!(Get-Module -ListAvailable -Name "ServerEye.Powershell.Helper")) {
    Write-Host "ServerEye PowerShell Module is not installed. Installing it..." -ForegroundColor Red
    Install-Module "ServerEye.Powershell.Helper" -Scope CurrentUser -Force
}

# Check if module is loaded, if not load it
if (!(Get-Module "ServerEye.Powershell.Helper")) {
    Import-Module ServerEye.Powershell.Helper
}

$AuthToken = Test-SEAuth -AuthToken $AuthToken

#Write-Debug "Customer id "$customers.CustomerId

    $containers = Get-SeApiCustomerContainerList -AuthToken $AuthToken -CId $custID

        foreach ($sensorhub in $containers) {

            if ($sensorhub.subtype -eq "2") {

                 Write-Debug $sensorhub

                    try {

                        $inventory = Get-SeApiContainerInventory -AuthToken $AuthToken -CId $sensorhub.id -ErrorAction Stop -ErrorVariable x

                         Write-Debug $inventory
                            [PSCustomObject]@{
                                Sensorhub = $sensorhub.name
                                Status = "Online"
                                    Software = for ($i = 0; $i -lt $inventory.PROGRAMS.Count; $i++) {
                                        [PSCustomObject]@{
                                        Pos = ($i+1)
                                        Produkt = $inventory.PROGRAMS[$i].Produkt
                                        Version = $inventory.PROGRAMS[$i].SWVERSION
                                        }
                                    }
                            }
                            
                        }
                        catch {
                            if($x[0].ErrorRecord.ErrorDetails.Message -match ('"message":"server_error","error":"not_connected"')  ){
                                [PSCustomObject]@{
                                    Sensorhub = $sensorhub.name
                                    Status = "is Offline."
                                }
                            }
                        }
                    }
                }