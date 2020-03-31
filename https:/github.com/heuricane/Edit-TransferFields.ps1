<#  Edit-TransferFields.ps1
    Jay Berkovitz 2/27/2020

Takes in HR's spreadsheet from "TASC Report through 02.27.20.csv"
(It takes a little formatting for just the Transfer section and change to CSV)

It pulls out EmployeeID, Name, Company, Department, JobTitle and Manager

Then searches AD for the users from the list and updates their properties.
Outputs the users it couldn't find so they can be updated manually

    Current problems:
    - Only Works for Compass and Security domains (so far)
    - Can't find people with 2 last names (like Daniel Day Lewis)
    - Doesn't add managers if not in same domain (ADManager can't either)
#>

# Opening arrays
$oldData = @()
$naughtyList = @()
$select = @('employee id','team member name','employee email','company','new department','job title','leader')

# Import the Transfers spreadsheet we get from HR
$list = Import-CSV 'C:\temp\TASC Report through 03.22.20.csv' | select $select
 

# Looping for each user
Foreach ($listUser in $list)
{
# Put Firstnames and Lastnames in objects
    $LN = $listUser.'Team Member Name'.split(',')[0]
    $FN = $listUser.'Team Member Name'.split(' ')[1]
    $MLN = $listUser.Leader.split(',')[0]
    $MFN = $listUser.Leader.split(' ')[1]

# Getting User data from COMPASS domain
    $select = @('cn','company','department','EmployeeID','title','Manager')
    $ADuser = Get-ADUser -server compass -filter {(GivenName -eq $FN)-and(Surname -eq $LN)} -pr $select
    $Manager= Get-ADUser -ser compass -f {(GivenName -eq $MFN)-and(Surname -eq $MLN)} | select -exp DistinguishedName

# Save Old data for Audit  
    $oldData += $ADuser | select $select

# Protect Accounts from null source errors
    If ($ADuser -ne $null)
    {
# Setting new user data
        $ADuser.Company = $listUser.Company
        $ADuser.Title = $listUser.'Job Title'
        $teammembername = $listUser.'Team Member Name'
        $ADuser.Department = $listUser.'New Department'
        $ADuser.EmployeeID = $listUser.'Employee ID'.PadLeft(7,'0')
        $ADUser.Manager = $Manager
        Write-Host -ForegroundColor DarkGreen "Updating account information for $teammembername "
        #Set-ADUser -Instance $ADuser                               # < COMPASS DOMAIN safety switch
    }Else
    {
# Getting User data from SECURITY domain
        $d = 'security.tsprc.com'
        $ADuser = Get-ADUser -server $d -filter {(GivenName -eq $FN)-and(Surname -eq $LN)} -pr $select
        $Manager= Get-ADUser -ser $d -f {(GivenName -eq $MFN)-and(Surname -eq $MLN)} | select -exp DistinguishedName
        If ($ADuser -ne $null)
        {   
# Setting new user data
            $ADuser.Company = $listUser.Company
            $ADuser.Title = $listUser.'Job Title'
            $teammembername = $listUser.'Team Member Name'
            $ADuser.Department = $listUser.'New Department'
            $ADuser.EmployeeID = $listUser.'Employee ID'.PadLeft(7,'0')
            $ADUser.Manager = $Manager
            #Set-ADUser -Instance $ADuser                             # < SECURITY DOMAIN safety switch
            Write-Host -ForegroundColor DarkGreen "Updating account information for $teammembername "
        }Else
        {
            $bad = $listUser.'Team Member Name'
            Write-Host -ForegroundColor Red "$bad Not Found"
            $naughtyList += $bad
        }
    }
}

# Updating any Trisepttech accounts.
# Looping for each user
Foreach ($listUser in $list)
{
# Put Firstnames and Lastnames in objects
    $LN = $listUser.'Team Member Name'.split(',')[0]
    $FN = $listUser.'Team Member Name'.split(' ')[1]
# Getting User data from TriseptTech domain
    $d = 'trisepttech.com'
    $ADuser = Get-ADUser -server $d -filter {(GivenName -eq $FN)-and(Surname -eq $LN)} -pr $select
    $Manager= Get-ADUser -ser $d -f {(GivenName -eq $MFN)-and(Surname -eq $MLN)} | select -exp DistinguishedName
     
# Protect Accounts from null source errors
    If ($ADuser -ne $null)
    {
# Setting new user data
        $ADuser.Company = $listUser.Company
        $ADuser.Title = $listUser.'Job Title'
        $ADuser.Department = $listUser.'New Department'
        $ADuser.EmployeeID = $listUser.'Employee ID'.PadLeft(7,'0')
        $ADUser.Manager = $Manager
        Set-ADUser -Instance $ADuser
    }    
}

$x = @()
Foreach ($listUser in $list)
{
    $LN = $listUser.'Team Member Name'.split(',') | select -first 1
    $FN = $listUser.'Team Member Name'.split(' ') | select -skip 1 | select -first 1
    $select = @('cn','company','department','EmployeeID','title','Manager')
    $x += Get-ADUser -server compass -filter {(GivenName -eq $FN)-and(Surname -eq $LN)} -pr $select
}
$x | Out-GridView -Title "New Settings"



# Save the Old Info and Skipped users

$filename = 'C:\temp\MANUAL_' + $(get-date -f yyyy-MM-dd) + '.csv'
$list | where {$naughtylist -contains $_.'team member name'} | Export-Csv -NoTypeInformation -Path $filename
$filename = 'OldData_' + $(get-date -f yyyy-MM-dd) + '.csv'
$olddata | Export-CSV -NoTypeInformation -Path c:\temp\$filename
