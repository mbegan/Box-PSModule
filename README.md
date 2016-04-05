# Box-PSModule Documentation
======================

This is a basic Box API Powershell Wrapper Module intended to expose the capabilities of the Box Content API in a secure way.  The module includes basic Oauth2 handlers including initial authorization mechanism as well as refresh and access token managment. Read the Box Contenet API [here] (https://box-content.readme.io/reference).

--------

### Getting Started
#Installation:
1. Download the module (git clone or download the zip)
2. Place the module in your PSModulePath hint [Read more about PSModulePath Here] (https://msdn.microsoft.com/en-us/library/dd878324%28v=vs.85%29.aspx)

   ``` powershell
Write-Host $env:PSModulePath
    ```
3. Create your App in box (details fourthcoming)
4. Import the module

   ``` powershell
Import-Module Box
   ```
6. Run the boxCreateEnv cmdlet (see cmdlet documentation for more detail)

   ``` powershell
boxCreateEnv -name <name> -client_id <your_clientid> -client_secret <your_client_secret>
   ```
    a. asdf
    b. xyz
    c.
7. then do
8. 
