<#  Check-EpiserverUsers.ps1
   Jay Berkovitz 03.05.2020

Since we have a restricted script execution policy, it needs to be opened
in Powershell_ISE copy and pasted to the shell window. and line 36 needs 
to be imcremented by 1 each iteration of the script.

#>

# Set these variables 

# Where you saved the list of names to search
$namestoSearch = Get-Content C:\temp\searchthese.txt

# Login information
$password = '###########'
$username = '###########'


# Don't need to touch these.
$nameDB = @{}
$webSites = @(
'www.vaxvacationaccess',
'dev.vaxvacationaccess',
'alpha.vaxvacationaccess',
'beta.vaxvacationaccess',
'dev.applevacations',
'alpha.applevacations',
'beta.applevacations',
'www.applevacations',
'dev.sunscaperesorts',
'alpha.sunscaperesorts',
'beta.sunscaperesorts',
'stage.sunscaperesorts')

# The number in the line brackets below needs to be incremented by 1 each run to do the next site.
Foreach ($webSite in $webSites[0])
{
    $results = $null
    $siteBase = 'https://'+$webSite+'.com/EPiServer/CMS/Admin/SearchUsers.aspx'

# Create an Internet Explorer object
#
    $ie = New-Object -ComObject 'internetExplorer.Application'
    $ie.Visible = $true
    $ie.Navigate($siteBase)
    while($ie.Busy -eq $true){Start-Sleep -seconds 10}

# Feed in your credentials to input fields on the web page
#
    $ie.Document.getElementByID("LoginControl_UserName").value = $username
    $ie.Document.getElementByID("LoginControl_Password").value = $password
    $ie.Document.getElementByID("LoginControl_Button1").click()
    while ($ie.Busy -eq $true){Start-Sleep -seconds 15}

# Enter the user to search and click search
#
    Foreach ($nametoSearch in $namestoSearch)
    {
        $ie.Document.getElementByID("FullRegion_MainRegion_FirstName").value = $nametoSearch
        $ie.Document.getElementByID("FullRegion_MainRegion_SearchButton").click()
        while ($ie.Busy -eq $true){Start-Sleep -seconds 5}
        $results = $ie.Document.getElementByID("FullRegion_MainRegion_Grid").innertext
    
    # Display and record the results
    #    
        $key = $webSite+'\'+$nametoSearch
        If ($results -match '@'){
            Write-Host -fore Red "$nametoSearch has been found on $siteBase"
            $mySwitch = "1"
            }
        Else{Write-Host -fore Green "$siteBase is Clear of $nametoSearch"
            $mySwitch = "0"
            }
        $nameDB.Add($key,$mySwitch)
    }
}
