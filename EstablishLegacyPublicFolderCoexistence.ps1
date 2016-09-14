$list = Get-ExchangeServer | ? { $_.AdminDisplayVersion -like "Version 14.3*" -and $_.ServerRole -Contains "Mailbox"}

$mailboxes = @()

foreach ($l in $list)
{

    $DiscoveryDBName = "PFDiscoveryDB-" + $l.name
    
    New-MailboxDatabase -Name $DiscoveryDBName -Server $l.name -IsExcludedFromProvisioning $true
    Write-Host "Sleeping 15 seconds..."
    Start-Sleep -m 15000
    Set-MailboxDatabase -Identity $DiscoveryDBName -RpcClientAccessServer $l.fqdn 

    $DiscoveryMBName = "PFDiscoveryMB-" + $l.name

    $password = [System.Web.Security.Membership]::GeneratePassword(64,10)

    $UPN = $DiscoveryMBName + "@" + (Get-UserPrincipalNamesSuffix)[0]

    New-Mailbox -Name $DiscoveryMBName -Database $DiscoveryDBName -UserPrincipalName $UPN -Password (ConvertTo-SecureString -String $password -AsPlainText -Force) 
    Write-Host "Sleeping 15 seconds..."
    Start-Sleep -m 15000
    Set-Mailbox -Identity $DiscoveryMBName -HiddenFromAddressListsEnabled $true
    
    $mailboxes += Get-Mailbox $DiscoveryMBName
    
}

Set-OrganizationConfig -RemotePublicFolderMailboxes $mailboxes
Set-OrganizationConfig -PublicFoldersEnabled Remote
