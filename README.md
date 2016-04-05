# Box-PSModule Documentation
======================

This is a basic Box API Powershell Wrapper Module intended to expose the capabilities of the Box Content API in a secure way.  The module includes basic Oauth2 handlers including initial authorization mechanism as well as refresh and access token managment. Read the Box Contenet API [here] (https://box-content.readme.io/reference).

--------

# Getting Started
##Installation:
1. Download the module (git clone or download the zip)
2. Place the module in your PSModulePath hint [Read more about PSModulePath Here] (https://msdn.microsoft.com/en-us/library/dd878324%28v=vs.85%29.aspx)

   ``` powershell
Write-Host $env:PSModulePath
    ```
3. Register your App in box, [read great details on this step here] (https://box-content.readme.io/docs/oauth-20)

    #####If your box org has restricted apps make sure your allow your app!

4. Import the module

   ``` powershell
Import-Module Box
   ```
6. Run the boxCreateEnv cmdlet (see cmdlet documentation for more detail)
    #####It is important to note: The access code generated in this process is only valid for 30 seconds

   ``` powershell
boxCreateEnv -name <name> -client_id <your_clientid> -client_secret <your_client_secret>

1 - Open a browser
2 - Login to Box as the user you want to make API calls as
3 - Paste the following URL into that browser window
4 - Click 'Grant Access to Box'
5 - Paste the resulting URL into the powershell prompt
Visit: https://app.box.com/api/oauth2/authorize?response_type=code&client_id=<your_clientid>&state=<arbitrary_guid>
Paste the resulting URL here: http://localhost/?state=<arbitrary_guid>&code=<your_access_code>
   ```

After the initial setup a registry key will be created in the invoking users reg hive (not HKLM but HKCU:\Software\boxAPIPSModule) as such no elevated privs are required. Sensitive values are encrypted using the DPAPI, if you are especially security conscious create the env and include the -thumbprint directive along with a thumbprint for your favorite personal asymetric keypair.

I've only wrapped user and group endpoints thus far, i'll add more as i need more, if you have a specific need request away.

#Usage
##Get A user

    ``` powershell
    these are powershell commands
    ```
