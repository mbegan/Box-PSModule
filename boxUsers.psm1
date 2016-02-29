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

    $result = boxApiCall -env $env -method $method -resource $resource
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
         [int]$userid,
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

    $result = boxApiCall -env $env -method $method -resource $resource
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
         [int]$userid,
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$username
    )

    if ($userid)
    {
        $resource = '/users/' + $userid + '/email_aliases'
        $method = 'Get'
    

        $result = boxApiCall -env $env -method $method -resource $resource
        return $result
    } elseif ($username)
    {
        $users = boxGetUser -username $username -env $env
        foreach ($user in $users)
        {
            boxGetAliases -env $env -userid $user.id
        }
    }
    else
    {
        throw ("Must Supply a username or a userid")
    }
}

function boxAddAlias()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$true)]
         [int]$userid,
        [parameter(Mandatory=$true)]
         [ValidateLength(1,254)]
         [string]$alias
    )

    $object = @{email = $alias}

    $method = 'Post'
    $resource = $resource = '/users/' + $userid + '/email_aliases'

    $result = boxApiCall -env $env -method $method -resource $resource -body $object

    return $result
}

function boxDeleteAlias()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$true)]
         [int]$userid,
        [parameter(Mandatory=$true)]
         [int]$aliasid,
        [parameter(Mandatory=$false)]
         [ValidateLength(1,254)]
         [string]$alias
    )

    $method = 'DELETE'
    $resource = $resource = '/users/' + $userid + '/email_aliases/' + $aliasid

    $result = boxApiCall -env $env -method $method -resource $resource

    return $result
}

function boxUpdateUser()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$true)]
         [int]$userid,
        [parameter(Mandatory=$true)]
         [ValidateSet('job_title','phone','address','timezone','language','name')]
         [string]$attribute,
        [parameter(Mandatory=$false)]
         [string]$value
    )

    $body = @{$attribute = $value}

    $method = 'Put'
    $resource = '/users/' + $userid

    $result = boxApiCall -env $env -method $method -resource $resource -body $body

    return $result
}