function boxGetCurrentUser()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv)
    )

    $method = 'Get'
    $resource = '/users/me'

    $result = boxApiCall -env $env -method $method -resource $resource -Verbose
    return $result
}

function boxGetUser()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$userid,
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$username
    )

    $method = 'Get'

    if ($userid)
    {
        $resource = '/users/' + $userid
    } elseif ($username) {
        $resource = '/users' + '?filter_term=' + $username
    } else {
        $resource = '/users'
    }

    $result = boxApiCall -env $env -method $method -resource $resource -Verbose
    return $result
}

function boxGetAliases()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$userid,
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$username
    )

    if ($userid)
    {
        $resource = '/users/' + $userid + '/email_aliases'
    } elseif ($username)
    {
        $results = boxGetUser -username $username -name $env
    }
    else
    {
        throw ("Must Supply a username or a userid")
    }

    $method = 'Get'
    

    $result = boxApiCall -env $env -method $method -resource $resource -Verbose
    return $result
}