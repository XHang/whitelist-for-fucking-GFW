file description:
# script.ps1:
A PowerShell script can be run directly on Windows 11. 
Input the PAC file path and convert it to a script that can be recognized in Clash Verge.
Save the output in the same folder where the script is run

# clash verge.yaml
Example config file of clash verge

# white_small.pac
Part of the whitelist.pac
# whitelist.pac
Fully whitelist for GFW

# clash_config.yaml

a generated whitelist file for clash verge  
New Changes for whitelist go down here  


# blacklist.ps1

fetch GFW blacklist from a URL and convert it to the config for Clash Berge

# gfwlist_clash_rules.yaml
The output blacklist config for Clash Berge.
I added extra rules to it so if you execute `blacklist.ps1`, the changes will be lost

# problems


.\blacklist.ps1 : File D:\Backup\Documents\fucking GFW\whitelist-for-fucking-GFW\blacklist.ps1 cannot be loaded
because running scripts is disabled on this system. For more information, see about_Execution_Policies at
https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:1
+ .\blacklist.ps1
+ ~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
	

answer: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

