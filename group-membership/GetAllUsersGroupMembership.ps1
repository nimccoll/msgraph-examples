#===============================================================================
# Microsoft FastTrack for Azure
# List all users in the directory and their associated group membership
#===============================================================================
# Copyright © Microsoft Corporation.  All rights reserved.
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY
# OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE.
#===============================================================================
param(
    [Parameter(Mandatory)]$outputFilePath
)

Connect-MgGraph -Scopes "User.Read.All","Group.Read.All"
$userGroups = @()
$users = Invoke-MgGraphRequest -Method GET 'https://graph.microsoft.com/v1.0/users?$select=id,userPrincipalName,displayName,givenName,surname'
$users.value | ForEach-Object {
    $user = New-Object -TypeName PSObject -Property @{
        UserObjectId = $_.id
        UserPrincipalName = $_.userPrincipalName
        DisplayName = $_.displayName
        GivenName = $_.givenName
        Surname = $_.surname
    }
    $groupUrl = 'https://graph.microsoft.com/v1.0/users/' + $_.id + '/memberOf?$select=id,displayName,description'
    $groups = Invoke-MgGraphRequest -Method GET $groupUrl
    $groups.value | ForEach-Object {
        # Ignore groups that do not have a displayName as these are administrative directory roles
        if ($_.displayName) {
            $userGroups += New-Object -TypeName PSObject -Property @{
                UserObjectId = $user.UserObjectId
                UserPrincipalName = $user.UserPrincipalName
                UserDisplayName = $user.DisplayName
                GivenName = $user.GivenName
                Surname = $user.Surname
                GroupObjectId = $_.id
                GroupDisplayName = $_.displayName
                Description = $_.description
            }
        }
    }
}
# Write output to CSV file
if ($userGroups.Count -gt 0) {
    $userGroups | Select-Object -Property UserObjectId, UserPrincipalName, UserDisplayName, GivenName, Surname, GroupObjectId, GroupDisplayName, Description | Export-Csv -Path $outputFilePath -NoTypeInformation
}