$ExecutionContext.SessionState.Module.OnRemove = {
    #Remove-Variable -name mybox -Force
    Remove-Module box_settings
}

function boxCheckandCreateReg()
{
    param
    (
        [string]$reg_key
    )

    if(!(Test-Path $reg_key))
    {
        Write-Verbose ("Registry key " + $reg_key + "does not exist creating it now")
        try
        {
            $reg = New-Item $reg_key -ItemType Registry -Force
        }
        catch
        {
            throw ($_.Exception.Message)
        }
    } else {
        try
        {
            $reg = Get-Item -Path $reg_key
        }
        catch
        {
            throw ($_.Exception.Message)
        }
    }
    return $reg
}

function boxGetDefaultEnv()
{
    $myBoxReg = boxCheckandCreateReg -reg_key $mybox.RegBase
    if ($default = $myBoxReg.GetValue("boxEnvDefault"))
    {
        return $default
    }
    return $false
}

function boxGetOAuthGrantCode()
{
    <# 
     .Synopsis
      Used to get a short lived (30 second) OAuth2 grant code

     .Description
      Generates a specailly formed URL for us to visit in an authenticated browser session
      Requests the resulting URL to be pasted
      Validates the input and returns a code that must be exchanged for a Refresh Token within 30 seconds

     .Parameter client_id
      Required string of the client_id of your registered app
     
     .Example
      boxGetOauthGrantCode -client_id abcd123456789
      
      Generates a URL, prompts you to paste it in a browser and in turn submit the resulting URL
      Parses the 'code' and validates the 'state'
      Returns the code
           
     .LINK
      https://box-content.readme.io/docs/oauth-20
    #>
    param
    (
        [parameter(Mandatory=$true)]
            [alias('cid','c_id')]
            [ValidateLength(32,32)]
            [String]$client_id
    )

    $state = [guid]::NewGuid()

    $goto = $mybox.OAuthBase + "/oauth2/authorize?response_type=code&client_id=" + $client_id + "&state=" + $state.Guid
    $instructions  = "1 - Open a browser`n"
    $instructions += "2 - Login to Box as the user you want to make API calls as`n"
    $instructions += "3 - Paste the following URL into that browser window`n"
    $instructions +="4 - Click 'Grant Access to Box'`n"
    $instructions +="5 - Paste the resulting URL into the powershell prompt"
    Write-Host($instructions) -BackgroundColor Green -ForegroundColor White
    Write-Host("Visit: `n`t" + $goto)

    $resp = Read-Host -Prompt ("Paste the resulting URL here")
    $split = $resp.Split("?")
    $results = New-Object System.Collections.Hashtable
    foreach ($param in $split[1].Split("&"))
    {
        $pieces = $param.Split("=")
        $results.Add($pieces[0], $pieces[1])    
    }

    if ($results.state -ne $state.Guid)
    {
        Write-Warning("Somehow You've been had by a CSRF attack `
         which is impossible we aren't a web app...`n `
         The returned state "+ $results.state +" doesn't match our validation "+ $state +"!" )
        throw("OAuth Code validation failure")
    }

    if ($results.error)
    {
        Write-Warning("Somehow we encountered an error`
         is there a chance you clicked no?`n"`
         + ( $results.error_description.replace("+"," ") ) )
        throw(($results.error_description.replace("+"," ")))
    }
    if ($results.code)
    {
        return $results.code
    } else {
        throw("We didn't receive a code... did you remember to Click 'Grant Access to Box'?" )
    }
}

function boxNewOAuthAccessToken()
{
    <# 
     .Synopsis
      Used to get an Access token from the /oauth2/token endpoint

     .Description
      Provide a code or refresh_token to exchange for a new or fresh access_token

     .Parameter client_id
      Required string of the client_id from your registered app

     .Parameter client_secret
      Required string of the client_secret from your registered app

     .Parameter refresh_token
      Required string of the client_secret from your registered app

     .Parameter code
      Required string of the client_secret from your registered app
     
     .Example
      boxNewOAuthAccessToken -client_id 1..32 -client_secret 1..32 -code 1..32

     .Example
      boxNewOAuthAccessToken -client_id 1..32 -client_secret 1..32 -refresh_token 1..64
             
     .LINK
      https://box-content.readme.io/docs/oauth-20
    #>
    param
    (
        [parameter(Mandatory=$true)]
            [alias('cid','c_id')]
            [ValidateLength(32,32)]
            [String]$client_id,
        [parameter(Mandatory=$true)]
            [alias('cse','c_sec')]
            [ValidateLength(32,32)]
            [String]$client_secret,
        [parameter(Mandatory=$false)]
            [ValidateLength(32,32)]
            [String]$code,
        [parameter(Mandatory=$false)]
            [ValidateLength(64,64)]
            [String]$refresh_token
    )

    $resource = "/oauth2/token"
    $method = "Post"
    $uri = $mybox.OAuthBase + $resource

    if ( ($code) -and ($refresh_token) )
    {
        throw ("providing both code and refresh_token is invalid, use one or the other not both")
    }

    if ($code)
    {
        $data = "grant_type=authorization_code&code=" + $code + "&client_id=" + $client_id + "&client_secret=" + $client_secret
        Write-Verbose ('Swapping a code ' + $code + ' for a token with a secret of ' + $client_secret)
    } elseif ($refresh_token) {
        $data = "grant_type=refresh_token&refresh_token=" + $refresh_token + "&client_id=" + $client_id + "&client_secret=" + $client_secret
        Write-Verbose ('Refreshing access token with refresh token ' + $refresh_token + ' and a secret of ' + $client_secret)
    } else {
        throw ("Either a code or a refresh_token must be suplied")
    }

    try
    {
        $json = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/x-www-form-urlencoded" -Body $data
    }
    catch
    {
        $errMessage = ConvertFrom-Json ($_.ErrorDetails.Message) -ErrorAction SilentlyContinue
        if ($errMessage.error = 'invalid_grant')
        {
            throw ($errMessage.error + ": " + $errMessage.error_description)
        } else {
            throw ($_.ErrorDetails.Message)
        }
    }
    finally
    {
        Remove-Variable -Name refresh_token
        Remove-Variable -Name client_secret
    }
    return $json
}

function boxCreateEnv()
{
    <# 
     .Synopsis
      Used to get setup the initial environment

     .Description
      Provide a client_id, client_secret, reference 'name' an optional asymetric key thumbprint
      for additional security to create the initial registry keys for future use.

     .Parameter client_id
      Required string of the client_id from your registered app

     .Parameter client_secret
      Required string of the client_secret from your registered app

     .Parameter name
      Required string an arbitrary name used to retrieve values later (prod, username, etc)

     .Parameter thumbPrint
      Optional string the thumbprint of an RSA keypair that will be used to encrypt the data stored in the registry
     
     .Example
      boxCreateEnv -client_id 1..32 -client_secret 1..32 -name highval -thumbPrint 8A0ECA6C79BE0A2F543905BDC557F53F0429D4F3 -default

      Creates an 'environment' called highval, encrypts sensitive values with the public key of keypair 8A0ECA6C79BE0A2F543905BDC557F53F0429D4F3
      and also sets it as the default environment

     .Example
      boxCreateEnv -client_id 1..32 -client_secret 1..32 -name lowval

      Creates an 'environment' called lowval, encrypts sensitive values with a default user specific symetric key
             
     .LINK
      https://box-content.readme.io/docs/oauth-20
    #>
    param
    (
        [parameter(Mandatory=$true)]
            [alias('cid','c_id')]
            [ValidateLength(32,32)]
            [String]$client_id,
        [parameter(Mandatory=$true)]
            [alias('cse','c_sec')]
            [ValidateLength(32,32)]
            [String]$client_secret,
        [parameter(Mandatory=$true)]
            [ValidateLength(1,100)]
            [String]$name,
        [parameter(Mandatory=$false)]
            [ValidateLength(40,40)]
            [String]$thumbPrint,
        [parameter(Mandatory=$false)]
            [switch]$default
    )

    $name = $name.ToLowerInvariant()

    $myBoxReg = boxCheckandCreateReg -reg_key $mybox.RegBase
    $myBoxReg = $myBoxReg.OpenSubKey($_,$true)
    $rvk = [Microsoft.Win32.RegistryValueKind]
    
    if ($myBoxReg.GetSubKeyNames().Contains($name) )
    {
        $envBoxReg = $myBoxReg.OpenSubKey($name,$true)
    } else {
        #Create a then open a writeable subkey
        $envBoxReg = $myBoxReg.CreateSubKey($name)
        $envBoxReg = $envBoxReg.OpenSubKey($_,$true)
    }

    try
    {
        $code = boxGetOauthGrantCode -client_id $client_id
    }
    catch
    {
        throw($_.Exception.Message)
    }

    $ts = Get-Date

    try
    {
        $refresh = boxNewOAuthAccessToken -client_id $client_id -client_secret $client_secret -code $code
    }
    catch
    {
        throw($_.Exception.Message)
    }

    if ($default)
    {
        Write-Verbose("Setting default box env to: " + $name)
        $myBoxReg.SetValue('boxEnvDefault',$name,$rvk::String)
    }

    $envBoxReg.SetValue('name', $name, $rvk::String)
    $envBoxReg.SetValue('refresh_ticks', $ts.Ticks, $rvk::String)
    $envBoxReg.SetValue('access_ticks', $ts.Ticks, $rvk::String)
    $envBoxReg.SetValue('client_id', $client_id, $rvk::String)
    $envBoxReg.SetValue('token_type', $refresh.token_type, $rvk::String)
    $envBoxReg.SetValue('expires_in', $refresh.expires_in, $rvk::String)
    
    if ($thumbPrint)
    {
        Write-Verbose("Setting rsaTp for: " + $name + " env to " + $thumbPrint)
        $envBoxReg.SetValue('rsaTp',$thumbPrint,$rvk::String)
    }

    #because it gives me a clean loop
    Add-Member -InputObject $refresh -MemberType NoteProperty -Name client_secret -Value $client_secret -Force
    
    #Encrypt these
    foreach ( $s in @('access_token','refresh_token','client_secret') )
    {
        $encSecret = boxEncryptSecrets -plainSecret $refresh.$s -envBoxReg $envBoxReg -SecretName $s
        $envBoxReg.SetValue($s, $encSecret, $rvk::String)
    }
    
    $envBoxReg.Close()
    $myBoxReg.Close()

    return $name
}

function boxEncryptSecrets()
{
    param
    (
        [parameter(Mandatory=$true)]
         [ValidateLength(1,512)]
         [String]$plainSecret,
        [parameter(Mandatory=$true)]
         [ValidateSet('access_token','refresh_token','client_secret')]
         [String]$SecretName,
        [parameter(Mandatory=$true)]
            $envBoxReg
    )
    $rsaAble = @('refresh_token','client_secret')

    if ( ($thumbPrint = $envBoxReg.GetValue('rsaTp')) -and ($rsaAble.Contains($SecretName)) )
    {
        $cert = Get-Item -Path Cert:\CurrentUser\My\$thumbPrint -ErrorAction Stop
        $bytes = [system.Text.Encoding]::UTF8.GetBytes($plainSecret)
        if (!($cert.HasPrivateKey))
        {
            throw("You don't have the private key for this Cert!")
        }
        $encBytes = $cert.PublicKey.Key.Encrypt($bytes, $true)
        $encSecret = [System.Convert]::ToBase64String($encBytes)
    } else {
        $encSecret = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -AsPlainText -Force -String $plainSecret)
    }
    return $encSecret
}

function boxDecrpytSecrets()
{
    param
    (
        [parameter(Mandatory=$true)]
         [ValidateSet('access_token','refresh_token','client_secret')]
         [String]$SecretName,
        [parameter(Mandatory=$true)]
         $envBoxReg
    )
    $rsaAble = @('refresh_token','client_secret')

    $envBoxReg = $envBoxReg.OpenSubKey($_,$true)

    if ( ($thumbPrint = $envBoxReg.GetValue('rsaTp')) -and ($rsaAble.Contains($SecretName)) )
    {
        Write-Verbose ('rsa decrpytion of ' + $SecretName + ' In progress..')
        try
        {
            $cert = Get-Item -Path Cert:\CurrentUser\My\$thumbPrint -ErrorAction Stop
        }
        catch
        {
            throw($_.Exception.Message)
        }
        $encSecret = $envBoxReg.GetValue($SecretName)
        $encBytes = [System.Convert]::FromBase64String($encSecret)
        try
        {
            $bytes = $cert.PrivateKey.Decrypt($encBytes,$true)
        }
        catch
        {
            throw($_.Exception.Message)
        }
        Write-Verbose ('Fetch of secure string ' + $SecretName + ' from rsa encrypted Reg key in progress..')
        $secSecret = ConvertTo-SecureString -AsPlainText -Force -String ([system.Text.Encoding]::UTF8.GetString($bytes))
        [array]::Clear($bytes, 0, $bytes.Length)
        Remove-Variable -Name bytes -Force
    } elseif ( ($SecretName -eq 'access_token') -and ($mybox.Env[($envBoxReg.GetValue('name'))]) )
    {
        Write-Verbose ('Fetch of secure string ' + $SecretName + ' from stash in progress..')
        #$secSecret = ($mybox.Env[($envBoxReg.GetValue('name'))].$SecretName)
        $secSecret = ConvertTo-SecureString -string ($mybox.Env[($envBoxReg.GetValue('name'))].$SecretName)
    } else {
        Write-Verbose ('Fetch of secure string ' + $SecretName + ' from Reg key in progress..')
        #$secSecret = ($envBoxReg.GetValue($SecretName))
        $secSecret = ConvertTo-SecureString -string ($envBoxReg.GetValue($SecretName))
    }

    return $secSecret
}

function boxGetEnv()
{
    param
    (
    [parameter(Mandatory=$false)]
     [ValidateLength(1,100)]
     [String]$name=(boxGetDefaultEnv)
    )

    $name = $name.ToLowerInvariant()

    $myBoxReg = boxCheckandCreateReg -reg_key $mybox.RegBase
    $myBoxReg = $myBoxReg.OpenSubKey($_,$true)
    $rvk = [Microsoft.Win32.RegistryValueKind]
    
    if (! ($myBoxReg.GetSubKeyNames().Contains($name)) )
    {
        throw ("No env by the name of: " + $name)
    }

    if (! ($mybox.Env[$name]) )
    {
        $mybox.Env.Add($name,(New-Object System.Collections.Hashtable))
    }
    

    $envBoxReg = $myBoxReg.OpenSubKey($name,$true)
    $envBoxReg = $envBoxReg.OpenSubKey($_,$true)
    $myBox.Env[$name]['access_ticks'] = $envBoxReg.GetValue('access_ticks')
    $myBox.Env[$name]['expires_in'] = $envBoxReg.GetValue('expires_in')
    $myBox.Env[$name]['access_token'] = $envBoxReg.GetValue('access_token')
    
    return $envBoxReg
}

function boxGetAccessToken()
{
    <# 
     .Synopsis
      Returns a secure string version of the current Access token.
      If the current access token is expired the refresh_token is fetched and the access token renewed.
      If the refresh_token is expired this fails and a new auth code will need to be generated

     .Description
      Returns a secure string version of the current Access token

     .Parameter name
      Optional string of the desired name of your environment configuration, default used if empty
     
     .Example
      boxGetAccessToken -env highvalue
                   
     .LINK
      https://box-content.readme.io/docs/oauth-20
    #>
    param
    (
    [parameter(Mandatory=$false)]
     [ValidateLength(1,100)]
     [String]$env=(boxGetDefaultEnv)
    )
    
    $envBoxReg = boxGetEnv -name $env
    $rvk = [Microsoft.Win32.RegistryValueKind]
    $envName = ($envBoxReg.GetValue('name'))

    $lastRefresh = Get-Date ([convert]::ToInt64( $envBoxReg.GetValue('refresh_ticks'), 10 ))
    $span = New-TimeSpan -Start $lastRefresh -End (Get-Date)
    if ( $span.TotalDays -gt 60 )
    {
        throw ('Your Refresh Token has expired!...')
    }

    if ( $mybox.Env[$envName] )
    {
        $ts = Get-Date ([convert]::ToInt64( $mybox.Env[$envName].access_ticks, 10 ))
        $expires_in = ([convert]::ToInt32($mybox.Env[$envName].expires_in, 10))
    } else {
        $ts = Get-Date ([convert]::ToInt64( $envBoxReg.GetValue('access_ticks'), 10 ))
        $expires_in = ([convert]::ToInt32( $envBoxReg.GetValue('expires_in'), 10 ))
    }

    $span = New-TimeSpan -Start $ts -End (Get-Date)

    if ($span.TotalSeconds.ToInt32($_) -lt ($expires_in - 5))
    {
        $access_token = boxDecrpytSecrets -SecretName access_token -envBoxReg $envBoxReg
    } else {
        try
        {
            $refresh_token = boxDecrpytSecrets -SecretName refresh_token -envBoxReg $envBoxReg
            $client_secret = boxDecrpytSecrets -SecretName client_secret -envBoxReg $envBoxReg
            $ts = Get-Date
            try
            {
                $refresh = boxNewOAuthAccessToken -client_id $envBoxReg.GetValue('client_id') `
                -client_secret ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($client_secret))) `
                -refresh_token ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($refresh_token)))
            }
            catch
            {
                throw ($_.Exception.Message)
            }
            finally
            {
                Remove-Variable -Name client_secret
                Remove-Variable -Name refresh_token
            }

            #update access key in the reg and stash
            $access_token = boxEncryptSecrets -plainSecret $refresh.access_token -envBoxReg $envBoxReg -SecretName access_token
            $refresh_token = boxEncryptSecrets -plainSecret $refresh.refresh_token -envBoxReg $envBoxReg -SecretName refresh_token

            $envBoxReg.SetValue('access_token', $access_token, $rvk::String)
            $access_token = ""
            $envBoxReg.SetValue('access_ticks', $ts.Ticks, $rvk::String)
            $envBoxReg.SetValue('expires_in', $refresh.expires_in, $rvk::String)
            #update the refresh ticks value to
            $envBoxReg.SetValue('refresh_token', $refresh_token, $rvk::String)
            $envBoxReg.SetValue('refresh_ticks', $ts.Ticks, $rvk::String)
            
            $envBoxReg.Close()
            Remove-Variable -Name envBoxReg -ErrorAction SilentlyContinue -Force
            $envBoxReg = boxGetEnv -name $envName

            $access_token = boxDecrpytSecrets -SecretName access_token -envBoxReg $envBoxReg
        }
        catch
        {
            throw ($_.Exception.Message)
        }
        finally
        {
            Remove-Variable -Name refresh_token -ErrorAction SilentlyContinue -Force
            Remove-Variable -Name client_secret -ErrorAction SilentlyContinue -Force
        }
    }

    return $access_token
}

function boxApiCall()
{
    param
    (
        [parameter(Mandatory=$false)]
         [string]$env = (boxGetDefaultEnv),
        [parameter(Mandatory=$true)]
         [String]$method,
        [parameter(Mandatory=$true)]
         [String]$resource,
        [parameter(Mandatory=$false)]
         [Object]$body = @{},
        [parameter(Mandatory=$false)]
         [int]$limit = 250,
        [parameter(Mandatory=$false)]
         [int]$offset = 0,
        [parameter(Mandatory=$false)]
         [array]$priors = (New-Object System.Collections.ArrayList)
    )

    $headers = New-Object System.Collections.Hashtable
    $access_token = boxGetAccessToken -env $env
    $_c = $headers.add('Authorization',('Bearer ' + ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($access_token )))))
    
    $_c = $headers.add('Accept-Charset','ISO-8859-1,utf-8')
    $_c = $headers.add('Accept-Language','en-US')
    $_c = $headers.add('Accept-Encoding','deflate,gzip')

    foreach ($alt in $altHeaders.Keys)
    {
        $_c = $headers.Add($alt,$altHeaders[$alt])
    }

    #ContentType "application/x-www-form-urlencoded"
    [string]$encoding = "application/json"

    if ($method.ToLower() -eq 'get')
    {
        $rParts = $resource.Split("?")
        if ($rParts.Count -eq 1)
        {
            $joiner = "?"
        } else {
            $joiner = "&"
        }
        if (! ($resource.Contains("limit=")) )
        {
            $resource = $resource + $joiner + "limit=" + $limit + "&offset=" + $offset
        }
    }
    

    $URI = $mybox.ApiBase + $resource
    $request = [System.Net.HttpWebRequest]::CreateHttp($URI)
    $request.Method = $method
    Write-Verbose ('[' + $request.Method + " " + $request.RequestUri + ']')

    $request.Accept = $encoding
    $request.UserAgent = "Box-PSModule/1.0"

    $request.AutomaticDecompression = @([System.Net.DecompressionMethods]::Deflate, [System.Net.DecompressionMethods]::GZip)
    
    foreach($key in $headers.keys)
    {
        $request.Headers.Add($key, $headers[$key])
    }
 
    if ( ($method -eq "POST") -or ($method -eq "PUT") )
    {
        $postData = ConvertTo-Json $body -Compress -Depth 10
        Write-Verbose ( $postData )
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($postData)
        $request.ContentType = $encoding
        $request.ContentLength = $bytes.Length
                 
        [System.IO.Stream]$outputStream = [System.IO.Stream]$request.GetRequestStream()
        $outputStream.Write($bytes,0,$bytes.Length)
        $outputStream.Close()
        Remove-Variable -Name outputStream
    }
 
    try
    {
        [System.Net.HttpWebResponse]$response = $request.GetResponse()

        $sr = New-Object System.IO.StreamReader($response.GetResponseStream())
        $txt = $sr.ReadToEnd()
        $sr.Close()
        
        try
        {
            $psobj = ConvertFrom-Json -InputObject $txt
        }
        catch
        {
            Write-Error $txt
            throw "Json Exception"
        }
    }
    catch [Net.WebException]
    { 
        [System.Net.HttpWebResponse]$response = $_.Exception.Response
        $sr = New-Object System.IO.StreamReader($response.GetResponseStream())
        $txt = $sr.ReadToEnd()
        $sr.Close()
        Write-Warning ($txt)
        throw ($_.Exception.Message)
    }
    catch
    {
        throw ($_.Exception.Message)
    }
    finally
    {
        $response.Close()
        $response.Dispose()
    }

    #paged response?
    if ($psobj.limit)
    {
        Write-Verbose ("We've recieved a potentially paged result")
        Write-Verbose ("We got total count: " + $psobj.total_count.ToString())
        Write-Verbose ("our limit was: " + $psobj.limit.ToString())
        Write-Verbose ("our offset was: " + $psobj.offset.ToString())
        Write-Verbose ("our count this itiration was: " + $psobj.entries.Count.ToString())

        #stuff what we just got into our priors container
        $priors = $priors + $psobj.entries
        #is there more left?
        if ( $psobj.total_count -gt ($psobj.limit + $psobj.offset))
        {
            Write-Verbose ($psobj.total_count.ToString() + " is greater than what we've got so far " +  ($psobj.limit + $psobj.offset).ToString())
            $newOffset = $limit + $offset
            Write-Verbose ("Fetch another: " + $limit + " Starting at " + $newOffset)
            $resource = $resource.Replace(("limit=" + $offset),("limit=" + $newOffset))
            boxApiCall -env $env -method $method -resource $resource -limit $limit -offset $newOffset
        }
        $results = $priors
    } else {
        $results = $psobj.entries
    }

    return $results
}