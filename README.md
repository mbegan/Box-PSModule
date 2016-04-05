# Box-PSModule Documentation
======================

This is a basic Box API Powershell Wrapper Module intended to expose the capabilities of the Box Content API in a secure way.  The module includes basic Oauth2 handlers including initial authorization mechanism as well as refresh and access token managment. Read the Box Contenet API [here] (https://box-content.readme.io/reference).

--------

# Getting Started
##Installation/Configuration:
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
boxCreateEnv -name <env_name> -client_id <your_clientid> -client_secret <your_client_secret>

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
##Getting users

####Search for users based on a username pattern
   ``` powershell
boxGetUser -username jdoe
   ```
This will return an array of box user objects that match a username of jdoe (jdoe, jdoe2 and jdoe3)

```
type            : user
id              : 900000001
name            : John Doe
login           : jdoe@your.tld
created_at      : 2016-03-17T12:11:05-07:00
modified_at     : 2016-04-04T15:03:37-07:00
language        : en
timezone        : America/Los_Angeles
space_amount    : 1E+15
space_used      : 94223
max_upload_size : 16106127360
status          : active
job_title       : Chief Lacky Officer
phone           : 
address         : 
avatar_url      : https://your.app.box.com/api/avatar/large/900000001

type            : user
id              : 900000002
name            : Jane Doe
login           : jdoe2@your.com
created_at      : 2016-03-09T18:21:46-08:00
modified_at     : 2016-03-16T14:19:53-07:00
language        : en
timezone        : America/Los_Angeles
space_amount    : 1E+15
space_used      : 0
max_upload_size : 16106127360
status          : active
job_title       : VP of Slacken
phone           : 
address         : 
avatar_url      : https://varian.app.box.com/api/avatar/large/900000002

type            : user
id              : 900000003
name            : Jade Doe
login           : jdoe2@your.com
created_at      : 2016-01-05T15:37:59-08:00
modified_at     : 2016-04-04T16:02:38-07:00
language        : en
timezone        : America/Los_Angeles
space_amount    : 1E+15
space_used      : 836170585
max_upload_size : 16106127360
status          : active
job_title       : Maven of Mystery
phone           : +1 800 876 5353
address         : 
avatar_url      : https://varian.app.box.com/api/avatar/large/900000003
```

####Get a single user based on box user id
``` powershell
boxGetUser -userid 262115333
```
This will return a singular user based on the id provided, exception thrown if userid isn't found

```
type            : user
id              : 900000003
name            : Jade Doe
login           : jdoe2@your.com
created_at      : 2016-01-05T15:37:59-08:00
modified_at     : 2016-04-04T16:02:38-07:00
language        : en
timezone        : America/Los_Angeles
space_amount    : 1E+15
space_used      : 836170585
max_upload_size : 16106127360
status          : active
job_title       : Maven of Mystery
phone           : +1 800 876 5353
address         : 
avatar_url      : https://varian.app.box.com/api/avatar/large/900000003
```
