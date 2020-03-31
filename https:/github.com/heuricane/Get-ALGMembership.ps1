function Get-ALGADDomains {
    # Returns some common domains we work with.
    return "TriseptTech", "Security", "Compass", "AppleVac", "LME", "Radix", "SQRL"
}
function Get-ALGADServerUrl {
    param(
        [parameter(Mandatory=$true, HelpMessage="The domain name. See Get-ALGADDomains.")][string]$DomainName
    )
    # Takes the domain name and returns the corresponding AD server url for it.
    switch($DomainName.ToLower()) {
        "trisepttech" { "trisepttech.com" }
        "security" { "security.tsprc.com" }
        "compass" { "compass.local" }
    }
}
function Get-ALGADUser {
    param(
        [parameter(Mandatory=$true, HelpMessage="The domain name. See Get-ALGADDomains.")][string]$DomainName,
        [parameter(Mandatory=$true)][string]$sAMAccountName,
        [string[]]$properties
    )
    # This function is basically Get-ADUser but it allows you to specify the domain name instead of the server url.
    if ($properties -eq $null) {
        #if no properties specified, fall back to "name".
        $properties = "Name"
    }
    Get-ADUser -Server (Get-ALGADServerUrl -DomainName $DomainName) -Identity $sAMAccountName -Properties $properties;
}
function Get-ALGADUserMembership {
    param(
        [parameter(Mandatory=$true, HelpMessage="The domain name. See Get-ALGADDomains.")][string]$DomainName,
        [parameter(Mandatory=$true)][string]$sAMAccountName
    )
    # This function is basically Get-ADUser -properties 'memberof' but it allows you to specify the domain name instead of the server url.
    Get-ALGADUser -DomainName $DomainName -sAMAccountName $sAMAccountName -properties "memberof" -ErrorAction Stop | select -expand memberof;
}
function Compare-ALGADUserMembership {
    param(
        [parameter(Mandatory=$true, HelpMessage="The domain name. See Get-ALGADDomains.")][string]$DomainName,
        [parameter(Mandatory=$true)][Alias("P1","Original")][string]$sAMAccountNameOne,
        [parameter(Mandatory=$true)][Alias("P2","Mirror")][string]$sAMAccountNameTwo
    )
    # This function grabs two users, the "original person" and the "mirror person", and compares them 
    # assuming that you want the original person to have the same permissions as the mirror.
    $personOne = Get-ALGADUser -DomainName $DomainName -sAMAccountName $sAMAccountNameOne -properties "memberof" -ErrorAction Stop;
    $personTwo = Get-ALGADUser -DomainName $DomainName -sAMAccountName $sAMAccountNameTwo -properties "memberof" -ErrorAction Stop;   
    $personOneCurrentGroups = $personOne | select -expand memberof;
    $personTwoCurrentGroups = $personTwo | select -expand memberof;
    $groupsThatPersonOneNeedsFromTwo = @();
    $groupsThatPersonOneNeedsToRemove = @();
    $groupsBothPeopleHave = @();
    foreach($group in $personTwoCurrentGroups) {
        if ($personOneCurrentGroups.Contains($group) -eq $false) {
            $groupsThatPersonOneNeedsFromTwo += ($group);
        } else {
            if ($groupsBothPeopleHave.Contains($group) -eq $false) {
                $groupsBothPeopleHave += ($group);
            }
        }
    }
    foreach($group in $personOneCurrentGroups) {
        if ($personTwoCurrentGroups.Contains($group) -eq $false) {
            $groupsThatPersonOneNeedsToRemove += ($group);
        } else {
            if ($groupsBothPeopleHave.Contains($group) -eq $false) {
                $groupsBothPeopleHave += ($group);
            }
        }
    }
    $details = @{            
        Domain = $DomainName
        OriginalPerson = $personOne
        MirrorPerson = $personTwo
        GroupsThatOriginalPersonNeeds = $groupsThatPersonOneNeedsFromTwo
        GroupsThatOriginalPersonDoesntNeed = $groupsThatPersonOneNeedsToRemove
        GroupsBothPeopleShare = $groupsBothPeopleHave
    };
                        
    return New-Object PSObject -Property $details;
}
function Get-ALGADUserMembershipDiffReport {
    param(
        [parameter(Mandatory=$true, HelpMessage="The domain name. See Get-ALGADDomains.")][string]$DomainName,
        [parameter(Mandatory=$true)][Alias("P1","Original")][string]$sAMAccountNameOne,
        [parameter(Mandatory=$true)][Alias("P2","Mirror")][string]$sAMAccountNameTwo,
        [Switch][boolean]$includeSharedGroups
    )
    # This function takes the same arguments as Compare-ALGADUserMembership and generates a user readable report that could be pasted in a log or a journal.
    $report = Compare-ALGADUserMembership -DomainName $DomainName -sAMAccountNameOne $sAMAccountNameOne -sAMAccountNameTwo $sAMAccountNameTwo -ErrorAction Stop;
    $personOne = $report | select -expand OriginalPerson;
    $personTwo = $report | select -expand  MirrorPerson;
    $personOneName = ($personOne -split ',')[0].Substring(3);
    $personTwoName = ($personTwo -split ',')[0].Substring(3);

    Write-Host "For $($personOneName) to equal $($personTwoName) on the $($report | select -expand Domain) domain, the following changes need to be made:";
    Write-Host;
    $groupsDoNeedCount = $report | select -expand GroupsThatOriginalPersonNeeds | measure | select -expand Count;
    Write-Host "Add $($groupsDoNeedCount) group(s) to $($personOneName):";
    foreach($group in ($report | select -expand GroupsThatOriginalPersonNeeds)) {
        Write-Host $group;
    }
    Write-Host;
    $groupsDoesntNeedCount = $report | select -expand GroupsThatOriginalPersonDoesntNeed | measure | select -expand Count;
    Write-Host "Remove $($groupsDoesntNeedCount ) group(s) from $($personOneName):";
    foreach($group in ($report | select -expand GroupsThatOriginalPersonDoesntNeed)) {
        Write-Host $group;
    }
    if ($includeSharedGroups -eq $true) {
        Write-Host;
        $sharedGroupCount = $report | select -expand GroupsBothPeopleShare | measure | select -expand Count;
        if ($sharedGroupCount -gt 0) {
            Write-Host "The following $($sharedGroupCount) group(s) are shared between both individuals:";
            foreach($group in ($report | select -expand GroupsBothPeopleShare)) {
                Write-Host $group;
            }
        }
    }
}
Export-ModuleMember -Function * -Alias * -Variable *;
