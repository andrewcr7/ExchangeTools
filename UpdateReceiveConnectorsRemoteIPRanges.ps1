add-pssnapin Microsoft.Exchange.Management.PowerShell.E2010

Function UpdateReceiveConnectorsRemoteIPRanges {

    Param(
        [Parameter(Mandatory=$True,Position=1)]
            $receiveConnectorIDs,
	
        [Parameter(Mandatory=$False)]
            [string[]]$additionalIPs,

        [Parameter(Mandatory=$False)]
            [string]$outputPath
    )

    $receiveConnectorObjects = @()

    foreach ($r in $receiveConnectorIDs) {
            $receiveConnectorObjects += Get-ReceiveConnector -Identity $r
    }

    if ($outputPath -eq $null) {
        $outputPath = ".\"
    }

    foreach ($r in $receiveConnectorObjects) {
        $FilePath = ($outputPath + $r.server + "-" + $r.Name + "-" + (Get-Date -Format yyyyMMdd\THHmmss) + ".xml")
        Export-Clixml -InputObject $r.RemoteIPRanges -Path $FilePath
    }
    
    foreach ($ip in $additionalIPs) {

        if ($ip -eq "") { 
            continue 
        }
        else {           
            foreach ($r in $receiveConnectorObjects) {
                if ($r.RemoteIPRanges.Contains($ip)) {
                    Write-Host "IP Address " $ip " already exists in connector $r.Identity"
                }
                else {
                    $r.RemoteIPRanges += $ip
                }
                
            }
        }
    }

    foreach ($r in $receiveConnectorObjects) {
        Set-ReceiveConnector $r.Identity -RemoteIPRanges $r.RemoteIPRanges -WhatIf
    }
}