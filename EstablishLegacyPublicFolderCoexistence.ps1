$PFDBs = Get-PublicFolderDatabase

$mailboxes = @()

foreach ($db in $PFDBs)
{

    $server = $db.server | Get-ExchangeServer

    $DiscoveryDBName = "PFDiscoveryDB-" + $server.name
    
    if (!(Get-MailboxDatabase $DiscoveryDBName)) 
    {

        New-MailboxDatabase -Name $DiscoveryDBName -Server $server -IsExcludedFromProvisioning $true 
        Write-Host "Sleeping 15 seconds..."
        Start-Sleep -m 15000
        Set-MailboxDatabase -Identity $DiscoveryDBName -RpcClientAccessServer $server.fqdn 

        $DiscoveryMBName = "PFDiscoveryMB-" + $server.name

        $password = [System.Web.Security.Membership]::GeneratePassword(64,10)

        $UPN = $DiscoveryMBName + "@" + (Get-UserPrincipalNamesSuffix)[0]

        New-Mailbox -Name $DiscoveryMBName -Database $DiscoveryDBName -UserPrincipalName $UPN -Password (ConvertTo-SecureString -String $password -AsPlainText -Force) 
        Write-Host "Sleeping 15 seconds..."
        Start-Sleep -m 15000
        Set-Mailbox -Identity $DiscoveryMBName -HiddenFromAddressListsEnabled $true
    
        $mailboxes += Get-Mailbox $DiscoveryMBName
    }
    
}

$newMailboxList = @()
$newMailboxList = (Get-OrganizationConfig).RemotePublicFolderMailboxes += $mailboxes

Set-OrganizationConfig -RemotePublicFolderMailboxes $newMailboxList
Set-OrganizationConfig -PublicFoldersEnabled Remote
