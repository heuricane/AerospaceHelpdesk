$user = "########"
$domain = "DC=SECURITY,DC=TSPRC,DC=com"
$domain = "DC=Trisepttech,DC=com"
#$domain = "DC=compass,DC=local"
$Path = "LDAP://" + $domain
$searcher = New-Object System.DirectoryServices.DirectorySearcher
$searcher.SearchRoot.distinguishedName = $domain
$searcher.SearchRoot.Path = $Path
$searcher.Filter = "(&(objectCategory=User)(sAMAccountname=$user))"
$obj = $searcher.FindOne()
$groups = $obj.Properties.memberof
$list = @()
Foreach ($group in $groups){
    $list += ($group -split 'CN=([^,]*),')[1]}

$list | Where-Object {$_ -like "**"} | sort


