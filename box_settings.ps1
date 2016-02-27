$mybox = New-Object System.Collections.Hashtable
$mybox.RegBase = "HKCU:\SOFTWARE\boxAPIPSModule"
$mybox.OAuthBase = 'https://app.box.com/api'
$mybox.ApiBase = 'https://api.box.com/2.0'
$mybox.Env = New-Object System.Collections.Hashtable