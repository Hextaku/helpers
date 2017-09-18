 <#
    .SYNOPSIS
    Get a list of all Sensorhubs for the given customer. 

    .PARAMETER Filter
    Filter the list to show only matching Sensorhubs. Sensorhubs are filterd based on the name of the Sensorhub.

    .PARAMETER CustomerId
    The customer id for which the Sensorhubs will be displayed.

    .PARAMETER SensorhubID
    The Sensorhib with this ID will be displayed.
    
    .PARAMETER AuthToken
    Either a session or an API key. If no AuthToken is provided the global Server-Eye session will be used if available.
    
#>
function Get-Sensorhub {
    [CmdletBinding(DefaultParameterSetName="byCustomer")]
    Param(
        [Parameter(Mandatory=$false,ParameterSetName="byCustomer",Position=0)]
        [string]$Filter,
        [Parameter(Mandatory=$false,ParameterSetName="byCustomer")]
        [string]$FilterByConnector,
        [parameter(ValueFromPipelineByPropertyName,ParameterSetName="byCustomer")]
        $CustomerId,
        [parameter(ValueFromPipelineByPropertyName,ParameterSetName="bySensorhub")]
        $SensorhubId,
        [Parameter(Mandatory=$false,ParameterSetName="byCustomer")]
        [Parameter(Mandatory=$false,ParameterSetName="bySensorhub")]
        $AuthToken
    )

    Begin{
        $AuthToken = Test-Auth -AuthToken $AuthToken
    }
    
    Process {
        if ($CustomerId) {
            getSensorhubByCustomer -customerId $CustomerId -filter $Filter -filterByConnector $FilterByConnector -auth $AuthToken
        } elseif ($SensorhubId) {
            getSensorhubById -sensorhubId $SensorhubId -auth $AuthToken
        } else {
            Write-Error "Please provide a SensorhubId or a CustomerId."
        }
    }

    End {

    }
}


function getSensorhubById($sensorhubId, $auth) {
    $sensorhub = Get-SeApiContainer -CId $sensorhubId -AuthToken $auth
    $occConnector = Get-SeApiContainer -CId $sensorhub.parentId -AuthToken $auth
    $customer = Get-Customer -customerId $sensorhub.customerId

    [PSCustomObject]@{
        Name = $sensorhub.name
        IsServer = $sensorhub.isServer
        'OCC-Connector' = $occConnector.name
        Customer = $customer.name
        SensorhubId = $sensorhub.cId
    }
}

function getSensorhubByCustomer ($customerId, $filter, $filterByConnector, $auth) {
    $containers = Get-SeApiCustomerContainerList -AuthToken $auth -CId $customerId
    foreach ($container in $containers) {
        
        if (($container.subtype -eq "0") -and ((-not $filterByConnector) -or ($container.name -like $filterByConnector))  ){ # OCC-Connector
            $customer = Get-Customer -customerId $container.customerId

            foreach ($sensorhub in $containers) {
                if ($sensorhub.subtype -eq "2" -And $sensorhub.parentId -eq $container.id) {
                    if ((-not $filter) -or ($sensorhub.name -like $filter)) {

                        [PSCustomObject]@{
                            Name = $sensorhub.name
                            IsServer = $sensorhub.isServer
                            'OCC-Connector' = $container.name
                            Customer = $customer.name
                            SensorhubId = $sensorhub.id
                        }
                    }
                }
            }
        }
    }
}

# SIG # Begin signature block
# MIIa0AYJKoZIhvcNAQcCoIIawTCCGr0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiSJEIEYIm4xGO60U2xrWBe8o
# M9OgghW/MIIEmTCCA4GgAwIBAgIPFojwOSVeY45pFDkH5jMLMA0GCSqGSIb3DQEB
# BQUAMIGVMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVVQxFzAVBgNVBAcTDlNhbHQg
# TGFrZSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxITAfBgNV
# BAsTGGh0dHA6Ly93d3cudXNlcnRydXN0LmNvbTEdMBsGA1UEAxMUVVROLVVTRVJG
# aXJzdC1PYmplY3QwHhcNMTUxMjMxMDAwMDAwWhcNMTkwNzA5MTg0MDM2WjCBhDEL
# MAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
# BxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKjAoBgNVBAMT
# IUNPTU9ETyBTSEEtMSBUaW1lIFN0YW1waW5nIFNpZ25lcjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAOnpPd/XNwjJHjiyUlNCbSLxscQGBGue/YJ0UEN9
# xqC7H075AnEmse9D2IOMSPznD5d6muuc3qajDjscRBh1jnilF2n+SRik4rtcTv6O
# KlR6UPDV9syR55l51955lNeWM/4Og74iv2MWLKPdKBuvPavql9LxvwQQ5z1IRf0f
# aGXBf1mZacAiMQxibqdcZQEhsGPEIhgn7ub80gA9Ry6ouIZWXQTcExclbhzfRA8V
# zbfbpVd2Qm8AaIKZ0uPB3vCLlFdM7AiQIiHOIiuYDELmQpOUmJPv/QbZP7xbm1Q8
# ILHuatZHesWrgOkwmt7xpD9VTQoJNIp1KdJprZcPUL/4ygkCAwEAAaOB9DCB8TAf
# BgNVHSMEGDAWgBTa7WR0FJwUPKvdmam9WyhNizzJ2DAdBgNVHQ4EFgQUjmstM2v0
# M6eTsxOapeAK9xI1aogwDgYDVR0PAQH/BAQDAgbAMAwGA1UdEwEB/wQCMAAwFgYD
# VR0lAQH/BAwwCgYIKwYBBQUHAwgwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2Ny
# bC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0LmNybDA1BggrBgEF
# BQcBAQQpMCcwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20w
# DQYJKoZIhvcNAQEFBQADggEBALozJEBAjHzbWJ+zYJiy9cAx/usfblD2CuDk5oGt
# Joei3/2z2vRz8wD7KRuJGxU+22tSkyvErDmB1zxnV5o5NuAoCJrjOU+biQl/e8Vh
# f1mJMiUKaq4aPvCiJ6i2w7iH9xYESEE9XNjsn00gMQTZZaHtzWkHUxY93TYCCojr
# QOUGMAu4Fkvc77xVCf/GPhIudrPczkLv+XZX4bcKBUCYWJpdcRaTcYxlgepv84n3
# +3OttOe/2Y5vqgtPJfO44dXddZhogfiqwNGAwsTEOYnB9smebNd0+dmX+E/CmgrN
# Xo/4GengpZ/E8JIh5i15Jcki+cPwOoRXrToW9GOUEB1d0MYwggVeMIIERqADAgEC
# AhEAr+4nKCTVfrQKuecqlSuCzDANBgkqhkiG9w0BAQsFADB9MQswCQYDVQQGEwJH
# QjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3Jk
# MRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDEjMCEGA1UEAxMaQ09NT0RPIFJT
# QSBDb2RlIFNpZ25pbmcgQ0EwHhcNMTcwMzA2MDAwMDAwWhcNMTkwMzA2MjM1OTU5
# WjCBpzELMAkGA1UEBhMCREUxDjAMBgNVBBEMBTY2NTcxMREwDwYDVQQIDAhTYWFy
# bGFuZDESMBAGA1UEBwwJRXBwZWxib3JuMRkwFwYDVQQJDBBLb3NzbWFuc3RyYXNz
# ZSA3MSIwIAYDVQQKDBlLcsOkbWVyIElUIFNvbHV0aW9ucyBHbWJIMSIwIAYDVQQD
# DBlLcsOkbWVyIElUIFNvbHV0aW9ucyBHbWJIMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAtXAX07uZxJy76BLbjZV1v/5wtXYVFJBY7ZBWl7SyAnX+W6sv
# 8yOD8/3dmnCyMMtiRNxrXUsL86aCN7WaCnZWAHzzTn5Ufh7hhNX0lToZ7vACZPrx
# eC+54gYXRGYOmeAX9RGlLyUiUj7DVeE6wEqIKENh82ZhgSTAgzgz73RZE07NHJPH
# zToJt/lRwFdlqRqljf3m4tYf1kq5Hk0ZhXohhC0uQSVxS41SdrquFkq9u+4of0Iq
# ebk8Mx4HaAW0meq0ZqJOqXIwolDhejRG9r7Jn1M4dNmJoSVT/Q/qUu2Z/zTecEUB
# 3p83994+bpxk9ZrSkIdG45hsWaUqoo5l8SXulwIDAQABo4IBrDCCAagwHwYDVR0j
# BBgwFoAUKZFg/4pN+uv5pmq4z/nmS71JzhIwHQYDVR0OBBYEFG0gXsn66LifYENz
# rQE5f9+KwG+MMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBGBgNVHSAEPzA9MDsGDCsG
# AQQBsjEBAgEDAjArMCkGCCsGAQUFBwIBFh1odHRwczovL3NlY3VyZS5jb21vZG8u
# bmV0L0NQUzBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLmNvbW9kb2NhLmNv
# bS9DT01PRE9SU0FDb2RlU2lnbmluZ0NBLmNybDB0BggrBgEFBQcBAQRoMGYwPgYI
# KwYBBQUHMAKGMmh0dHA6Ly9jcnQuY29tb2RvY2EuY29tL0NPTU9ET1JTQUNvZGVT
# aWduaW5nQ0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5j
# b20wHQYDVR0RBBYwFIESaW5mb0BrcmFlbWVyLWl0LmRlMA0GCSqGSIb3DQEBCwUA
# A4IBAQCFrLIiBF54IWFm3kZhwqucckh4N30X9z8x2hTjdnFZRZXJmtAIRhEfvJ1+
# hV3UTOlFdk1x56AU4PiDY0gHYNaT972OlJQyXn1IAfvtCPaFIALAnYpYJLpwb1pK
# 8aAeX01cpaBIqPP4qPOnf9l4NRTZb4J/TSFM3vG13gGn8NvyBFp8lW2B9jX1Geh6
# xIzA/ehJ3eiaSCNMMeERdrEYf+PWNVVvMuLPqADNbLo1G6AoqNIDATUo94A/BJ3t
# XRw9vh8YBlD1brYtsa1xjelka1Kx191r265dhc4HqeJ9DbB6rw6TwSCARtbqL+6j
# 3p2zZtgBhbbAHRjF3vs8oCri0YjSMIIF2DCCA8CgAwIBAgIQTKr5yttjb+Af907Y
# WwOGnTANBgkqhkiG9w0BAQwFADCBhTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdy
# ZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09N
# T0RPIENBIExpbWl0ZWQxKzApBgNVBAMTIkNPTU9ETyBSU0EgQ2VydGlmaWNhdGlv
# biBBdXRob3JpdHkwHhcNMTAwMTE5MDAwMDAwWhcNMzgwMTE4MjM1OTU5WjCBhTEL
# MAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
# BxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKzApBgNVBAMT
# IkNPTU9ETyBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQCR6FSS0gpWsawNJN3Fz0RndJkrN6N9I3AAcbxT
# 38T6KhKPS38QVr2fcHK3YX/JSw8Xpz3jsARh7v8Rl8f0hj4K+j5c+ZPmNHrZFGvn
# nLOFoIJ6dq9xkNfs/Q36nGz637CC9BR++b7Epi9Pf5l/tfxnQ3K9DADWietrLNPt
# j5gcFKt+5eNu/Nio5JIk2kNrYrhV/erBvGy2i/MOjZrkm2xpmfh4SDBF1a3hDTxF
# YPwyllEnvGfDyi62a+pGx8cgoLEfZd5ICLqkTqnyg0Y3hOvozIFIQ2dOciqbXL1M
# GyiKXCJ7tKuY2e7gUYPDCUZObT6Z+pUX2nwzV0E8jVHtC7ZcryxjGt9XyD+86V3E
# m69FmeKjWiS0uqlWPc9vqv9JWL7wqP/0uK3pN/u6uPQLOvnoQ0IeidiEyxPx2bvh
# iWC4jChWrBQdnArncevPDt09qZahSL0896+1DSJMwBGB7FY79tOi4lu3sgQiUpWA
# k2nojkxl8ZEDLXB0AuqLZxUpaVICu9ffUGpVRr+goyhhf3DQw6KqLCGqR84onAZF
# dr+CGCe01a60y1Dma/RMhnEw6abfFobg2P9A3fvQQoh/ozM6LlweQRGBY84YcWsr
# 7KaKtzFcOmpH4MN5WdYgGq/yapiqcrxXStJLnbsQ/LBMQeXtHT1eKJ2czL+zUdqn
# R+WEUwIDAQABo0IwQDAdBgNVHQ4EFgQUu69+Aj36pvE8hI6t7jiY7NkyMtQwDgYD
# VR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEMBQADggIB
# AArx1UaEt65Ru2yyTUEUAJNMnMvlwFTPoCWOAvn9sKIN9SCYPBMtrFaisNZ+EZLp
# LrqeLppysb0ZRGxhNaKatBYSaVqM4dc+pBroLwP0rmEdEBsqpIt6xf4FpuHA1sj+
# nq6PK7o9mfjYcwlYRm6mnPTXJ9OV2jeDchzTc+CiR5kDOF3VSXkAKRzH7JsgHAck
# aVd4sjn8OoSgtZx8jb8uk2IntznaFxiuvTwJaP+EmzzV1gsD41eeFPfR60/IvYcj
# t7ZJQ3mFXLrrkguhxuhoqEwWsRqZCuhTLJK7oQkYdQxlqHvLI7cawiiFwxv/0Cti
# 76R7CZGYZ4wUAc1oBmpjIXUDgIiKboHGhfKppC3n9KUkEEeDys30jXlYsQab5xoq
# 2Z0B15R97QNKyvDb6KkBPvVWmckejkk9u+UJueBPSZI9FoJAzMxZxuY67RIuaTxs
# lbH9qh17f4a+Hg4yRvv7E491f0yLS0Zj/gA0QHDBw7mh3aZw4gSzQbzpgJHqZJx6
# 4SIDqZxubw5lT2yHh17zbqD5daWbQOhTsiedSrnAdyGN/4fy3ryM7xfft0kL0fJu
# MAsaDk527RH89elWsn2/x20Kk4yl0MC2Hb46TpSi125sC8KKfPog88Tk5c0NqMuR
# krF8hey1FGlmDoLnzc7ILaZRfyHBNVOFBkpdn627G190MIIF4DCCA8igAwIBAgIQ
# LnyHzA6TSlL+lP0ct800rzANBgkqhkiG9w0BAQwFADCBhTELMAkGA1UEBhMCR0Ix
# GzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEa
# MBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKzApBgNVBAMTIkNPTU9ETyBSU0Eg
# Q2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTMwNTA5MDAwMDAwWhcNMjgwNTA4
# MjM1OTU5WjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVz
# dGVyMRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRl
# ZDEjMCEGA1UEAxMaQ09NT0RPIFJTQSBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCmmJBjd5E0f4rR3elnMRHrzB79MR2zuWJX
# P5O8W+OfHiQyESdrvFGRp8+eniWzX4GoGA8dHiAwDvthe4YJs+P9omidHCydv3Lj
# 5HWg5TUjjsmK7hoMZMfYQqF7tVIDSzqwjiNLS2PgIpQ3e9V5kAoUGFEs5v7BEvAc
# P2FhCoyi3PbDMKrNKBh1SMF5WgjNu4xVjPfUdpA6M0ZQc5hc9IVKaw+A3V7Wvf2p
# L8Al9fl4141fEMJEVTyQPDFGy3CuB6kK46/BAW+QGiPiXzjbxghdR7ODQfAuADcU
# uRKqeZJSzYcPe9hiKaR+ML0btYxytEjy4+gh+V5MYnmLAgaff9ULAgMBAAGjggFR
# MIIBTTAfBgNVHSMEGDAWgBS7r34CPfqm8TyEjq3uOJjs2TIy1DAdBgNVHQ4EFgQU
# KZFg/4pN+uv5pmq4z/nmS71JzhIwDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQI
# MAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYDVR0gBAowCDAGBgRVHSAA
# MEwGA1UdHwRFMEMwQaA/oD2GO2h0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0NPTU9E
# T1JTQUNlcnRpZmljYXRpb25BdXRob3JpdHkuY3JsMHEGCCsGAQUFBwEBBGUwYzA7
# BggrBgEFBQcwAoYvaHR0cDovL2NydC5jb21vZG9jYS5jb20vQ09NT0RPUlNBQWRk
# VHJ1c3RDQS5jcnQwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNvbW9kb2NhLmNv
# bTANBgkqhkiG9w0BAQwFAAOCAgEAAj8COcPu+Mo7id4MbU2x8U6ST6/COCwEzMVj
# EasJY6+rotcCP8xvGcM91hoIlP8l2KmIpysQGuCbsQciGlEcOtTh6Qm/5iR0rx57
# FjFuI+9UUS1SAuJ1CAVM8bdR4VEAxof2bO4QRHZXavHfWGshqknUfDdOvf+2dVRA
# GDZXZxHNTwLk/vPa/HUX2+y392UJI0kfQ1eD6n4gd2HITfK7ZU2o94VFB696aSdl
# kClAi997OlE5jKgfcHmtbUIgos8MbAOMTM1zB5TnWo46BLqioXwfy2M6FafUFRun
# UkcyqfS/ZEfRqh9TTjIwc8Jvt3iCnVz/RrtrIh2IC/gbqjSm/Iz13X9ljIwxVzHQ
# NuxHoc/Li6jvHBhYxQZ3ykubUa9MCEp6j+KjUuKOjswm5LLY5TjCqO3GgZw1a6lY
# YUoKl7RLQrZVnb6Z53BtWfhtKgx/GWBfDJqIbDCsUgmQFhv/K53b0CDKieoofjKO
# Gd97SDMe12X4rsn4gxSTdn1k0I7OvjV9/3IxTZ+evR5sL6iPDAZQ+4wns3bJ9ObX
# wzTijIchhmH+v1V04SF3AwpobLvkyanmz1kl63zsRQ55ZmjoIs2475iFTZYRPAmK
# 0H+8KCgT+2rKVI2SXM3CZZgGns5IW9S1N5NGQXwH3c/6Q++6Z2H/fUnguzB9XIDj
# 5hY5S6cxggR7MIIEdwIBATCBkjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3Jl
# YXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01P
# RE8gQ0EgTGltaXRlZDEjMCEGA1UEAxMaQ09NT0RPIFJTQSBDb2RlIFNpZ25pbmcg
# Q0ECEQCv7icoJNV+tAq55yqVK4LMMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBR+ZbMktlZAVV1f
# LVHPefG0IM0ZfzANBgkqhkiG9w0BAQEFAASCAQBSmFKdI6Bcs4g+WZAvssqIj04S
# gwdvZAmHwCWoy2xHQhjDzmGZUWF5FCso9B0EHePIsByU1xOapqZsjueJvpjSaz3J
# jEtbhdlsM6ZFpZAesuEBy0sT1Wr+rtO4XTLMw1bsAQvB9wFaNPaqI+6hgAf4w0Z7
# TaPF275dGx/BVIjhSaR44d0hE07vUEYQoHX/RnX02Kgu9EYs7greb2gt4IWRetl9
# NoXfQqCRcEo6HDVRd/kW/UhbQloj0+PpgOyQXOKZRtsUehOqzRxTMtUbDx6Sp7B+
# yBcvztR07uKBzd/s5kumFgq5+1k7f9yW4bDyokfcsC04hP9/ZLi7hJBWJdEpoYIC
# QzCCAj8GCSqGSIb3DQEJBjGCAjAwggIsAgEBMIGpMIGVMQswCQYDVQQGEwJVUzEL
# MAkGA1UECBMCVVQxFzAVBgNVBAcTDlNhbHQgTGFrZSBDaXR5MR4wHAYDVQQKExVU
# aGUgVVNFUlRSVVNUIE5ldHdvcmsxITAfBgNVBAsTGGh0dHA6Ly93d3cudXNlcnRy
# dXN0LmNvbTEdMBsGA1UEAxMUVVROLVVTRVJGaXJzdC1PYmplY3QCDxaI8DklXmOO
# aRQ5B+YzCzAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMTcwOTE4MTMzNzM4WjAjBgkqhkiG9w0BCQQxFgQUWjIn
# KP/eB1HDajCUYoFDiYylvV4wDQYJKoZIhvcNAQEBBQAEggEAOXMKLpJRqpLSfEez
# O0esLex28tFZ2/2+t/MnNFoTeYUsLTrpAsL1ipPu5ZOSzxfHWRSDOmJTAx1jW/AY
# DpwqZBhaYqWvvEqZ17dhg1gHOUoBi7H/RB2NjZik+SlB3EfizsSDIrXfVWQ8I0jV
# NzhI5gtSclEMGiRlWpOyCtRrSvaP1DYs0p6cRisTICSCsSpePZV8/7Fs/GgZHnMG
# ThXSrM7VwfGuv3hRxDwz1EL+DjpgV/twqlwmOz9n6T91tL/X9cznWrFkl5VdDDCq
# perGN5MRVC9G8ZXvLkLTaCqD70wnnKZwEF2DkVYwSiG8+htNmgiDAEAr/cNv4sYm
# M+Qg4w==
# SIG # End signature block
