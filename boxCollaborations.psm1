function boxGetCollaboration()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$false)]
         [String]$collabid="0"
    )

    $method = 'GET'

    $resource = '/collaborations/' + $collabid

    $result = boxApiCall -env $env -method $method -resource $resource
    return $result
}

function boxCreateCollaboration()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$true)]
         [String]$collabon,
        [parameter(Mandatory=$true)]
         [String]$collabto,
        [parameter(Mandatory=$false)]
         [ValidateSet('user','group')]
         [String]$collabtoType='user',
        [parameter(Mandatory=$false)]
         [bool]$notify=$true,
        [parameter(Mandatory=$false)]
         [String]$login,
        [parameter(Mandatory=$false)]
         [ValidateSet('editor','viewer','previewer','uploader','previewer uploader','viewer uploader','co-owner','owner')]
         [string]$role='co-owner',
        [parameter(Mandatory=$false)]
         [string]$fields='Please enjoy our collaboration together...'
    )

    $method = 'POST'

    $resource = '/collaborations'

    $body = @{ "notify" = $notify
               "item" = @{ "id" = $collabon; "type" = "folder" }
               "accessible_by" = @{ "id" = $collabto; "type" = $collabtoType }
               "role" = $role
               "fields" = $fields
             }

    $result = boxApiCall -env $env -method $method -resource $resource -body $body
    return $result
}

function boxDeleteCollaboration()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$true)]
         [String]$collabid
    )

    $method = 'DELETE'

    $resource = '/collaborations/' + $collabid

    $result = boxApiCall -env $env -method $method -resource $resource
    return $result
}

function zzzboxUpdateFolder()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$true)]
         [string]$folderid,
        [parameter(Mandatory=$false)]
         [String]$name,
        [parameter(Mandatory=$false)]
         [String]$tags,
        [parameter(Mandatory=$false)]
         [String]$description
    )

    $method = 'Put'
    $resource = '/folders/' + $folderid

    [string[]]$param = "name","tags","description"

    $body = New-Object psobject
    foreach ($p in $param)
    {
        if (Get-Variable -Name $p -ErrorAction SilentlyContinue) 
        {
            if ((Get-Variable -Name $p -ValueOnly) -ne "")
            {
                Add-Member -InputObject $body -Name $p -Value (Get-Variable -Name $p -ValueOnly) -MemberType NoteProperty
                Write-Verbose ("Setting " + $p + " to " + (Get-Variable -Name $p -ValueOnly))
            }
        }
    }

    Write-Verbose ($body)

    $result = boxApiCall -env $env -method $method -resource $resource -body $body
    return $result
}
