# android-debloat-poco
Android ADB debloat script ( especially for Xiaomi/Poco phones) 
## Tested on Poco X7 Pro
this picture is just for visualization, I have not used adbappcontrol.com for debloating ( 1.3 GB RAM saved)
<img width="1192" height="836" alt="image" src="https://github.com/user-attachments/assets/a46ed2a4-ded9-4aa6-aca3-f3c6901c4eae" />

# Usage
- it Requires `adb`
- you can get adb with `winget` on windows or from https://developer.android.com/tools/releases/platform-tools
- Adb should be in PATH ( so you can call it with just adb) otherwise update the script to include full path to `adb`
- Here is guide for adb setup ( or just search it in your favourite web search): https://www.xda-developers.com/install-adb-windows-macos-linux/
  
```powershell
.\debloater.ps1
```
## Notes
- it will remove all apps it can, including Google apps, so you will need to install what you need after
- Check the script and remove any apps from those lists you do not wish to remove
- there is note about `com.xiaomi.xmsf` if you get boot loop after running this and restart, you should remove it from the list ( it worked ok on Poco X7 Pro)
- you will be asked couple questions:
  1. important is if you want remove the File manager (on poco/xiaomi device) this requires you to download another file mager as you may be unable access files without it. -> if you chooe No, then it just continues with debloating, it is optional but recommended.
  2. on the end there will be prompt if you want to install 3 apps from F-Droid, Phone - Messages - Contacts
     - I had to install the Phone app from Fdroid, as the APK install did not have all permissions by look of it.
- On the end it also creates `dns.txt` file with url `no-malware-typo-ads.freedns.controld.com`
  -> you can use it for Secure DNS (Private DNS) - this will use DNS over TLS, if you ever have no internet with this especially on some Wifi networks, disable it temporary, as it is possible the wifi is blocking port 843
  -> this should provide some basic AD block and more importantly blocking malicious urls using https://controld.com/features/malware-blocking
  -> you can find this by searching for `DNS` in settings or it may be in `More connectivity Options` > `Private DNS`
<img width="243" height="288" alt="image" src="https://github.com/user-attachments/assets/f393e15d-e068-4ae8-ac87-d27061c86440" />


# Photos from phone:
- Final look
<img width="358" height="798" alt="image" src="https://github.com/user-attachments/assets/8a184192-3551-41a6-ac2b-f948c120e6f8" />
<img width="256" height="809" alt="image" src="https://github.com/user-attachments/assets/c5380b2b-5f58-4d6d-a0ab-9872169c343d" />

- Before installing Fossify app replacements:
<img width="362" height="810" alt="image" src="https://github.com/user-attachments/assets/21d3f910-85ef-49c7-9be2-af46f56d2df3" />

- After the debloating, some apps were disabled, as they could not be deleted - red circle
- you can delete them from `Settings` > `Apps` click on each and `Uninstall`
<img width="auto" height="5435" alt="image" src="https://github.com/user-attachments/assets/c9b0050f-c629-4c39-9f6e-98565e59275a" />

