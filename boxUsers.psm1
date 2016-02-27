function boxGetCurrentUser()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$name=(boxGetDefaultEnv)
    )

    $method = 'Get'
    $access_token = boxGetAccessToken -name $name
    $resource = '/users/me'
    $uri = $mybox.ApiBase + $resource
    $header = New-Object System.Collections.Hashtable
    $_c = $header.add('Authorization',('Bearer ' + ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($access_token )))))

    Write-Verbose ($header.Authorization)

    $json = Invoke-RestMethod -Method $method -Uri $uri -Headers $header -Verbose -ContentType "application/x-www-form-urlencoded"

    return $json
}

function boxGetUser()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$name=(boxGetDefaultEnv),
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$userid,
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$username
    )

    $method = 'Get'
    $access_token = boxGetAccessToken -name $name
    if ($userid)
    {
        $resource = '/users/' + $userid
    } elseif ($username) {
        $resource = '/users' + '?filter_term=' + $username
    } else {
        $resource = '/users'
    }
    $uri = $mybox.ApiBase + $resource
    $header = New-Object System.Collections.Hashtable
    $_c = $header.add('Authorization',('Bearer ' + ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($access_token )))))

    Write-Verbose ($header.Authorization)

    $json = Invoke-RestMethod -Method $method -Uri $uri -Headers $header -Verbose -ContentType "application/x-www-form-urlencoded"

    return $json
}

function boxGetAliases()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$name=(boxGetDefaultEnv),
        [parameter(Mandatory=$true)]
         [ValidateLength(1,100)]
         [String]$userid
    )

    $method = 'Get'
    $access_token = boxGetAccessToken -name $name

    $resource = '/users/' + $userid + '/email_aliases'

    $uri = $mybox.ApiBase + $resource
    $header = New-Object System.Collections.Hashtable
    $_c = $header.add('Authorization',('Bearer ' + ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($access_token )))))

    Write-Verbose ($header.Authorization)

    $json = Invoke-RestMethod -Method $method -Uri $uri -Headers $header -Verbose -ContentType "application/x-www-form-urlencoded"

    return $json
}