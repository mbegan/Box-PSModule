function boxGetFolder()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$false)]
         [String]$folderid="0"
    )

    $method = 'Get'

    $resource = '/folders/' + $folderid

    $result = boxApiCall -env $env -method $method -resource $resource
    return $result
}


function boxGetFolderItems()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$false)]
         [String]$folderid="0"
    )

    $method = 'Get'

    $resource = '/folders/' + $folderid +'/items'

    $result = boxApiCall -env $env -method $method -resource $resource
    return $result
}

function boxCreateFolder()
{
    param
    (
        [parameter(Mandatory=$false)]
         [ValidateLength(1,100)]
         [String]$env=(boxGetDefaultEnv),
        [parameter(Mandatory=$false)]
         [String]$parentid="0",
        [parameter(Mandatory=$true)]
         [String]$FolderName
    )

    $method = 'Post'

    $resource = '/folders'

    $body = @{ "name" = $FolderName; "parent" = @{ "id" = $parentid }}

    $result = boxApiCall -env $env -method $method -resource $resource -body $body
    return $result
}

function boxUpdateFolder()
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
