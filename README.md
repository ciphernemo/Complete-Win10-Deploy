# Complete-Win10-Deploy

A thorough, anti-telemetry, anti-bloatware Windows 10 deployment for business and power users. This is currently in use at my workplace as we are doing a late Windows 7 to 10 transition. We wanted to a smooth deployment that doesn't require the latest version of Windows 10 ADK so that it can be edited and maintained from a Windows 7 system (any ADK after Win 10 version 1511 is incompatible with Windows 7 when updating Media Content).

Most of the work for this project is done in the Scripts\FinalizeWin10.ps1 script file. Other smaller, but key changes are made in other files.

This project was created and shared with the world because too often IT Techs, System Admins, and DevOps responsible for deployments do not share their entire deployment solution. Many of us are forced to learn through trial & error, with a generous helping troubleshooting and searching online. We'll run into common issues the majority also faces, yet only a handful will choose to share their solutions online. At best it's a piecemeal scattering we'll be forced to cobble together on our own.

For those familiar with deploying via MDT, perhaps some of these files will help solve issues they've faced in their deployments. If this "Complete-Win10-Deploy" project helps at least one IT person, then it was all worth it.

## Getting Started

### Prerequisites and their Installation

1. [Windows 10 version 1803 or later](https://support.microsoft.com/en-us/help/4099479) -- This project currently tested with Windows 10 Pro 64-bit 1803 from an Windows 10 Education source media that includes all Windows 10 editions.
2. [Microsoft Deployment Toolkit](https://www.microsoft.com/en-us/download/details.aspx?id=54259)
3. If you are working in a Windows 7 environment, you'll want [Windows Assessment and Deployment Toolkit for Win10 version 1511](http://renshollanders.nl/2016/12/download-windows-adk-the-numerous-versions-of-microsoft-windows-adk-assessment-and-planning-toolkit-and-where-to-find-them/). Otherwise if your working evnrionment is a Windows 10 system (possibly 8.1 also?), you'll want the latest [Windows ADK for Win10](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install).

For a complete guide on installing both ADK and MDT, [TechRepublic has thorough step-by-step instructions](https://www.techrepublic.com/article/how-to-set-up-microsoft-deployment-toolkit-step-by-step/)

### Using This Project

#### For those new to MDT:
1. You will need to download and install Windows 10 Assessment and Deployment Toolkit (ADK) and Microsoft Deployment Toolkit (MDT), in that order.
2. Launch MDT and create a new deployment share. For network shares and deploying across a network, [Microsoft's MDT Guide](https://docs.microsoft.com/en-us/windows/deployment/deploy-windows-mdt/get-started-with-the-microsoft-deployment-toolkit) is a thorough, well-written guide. If you don't want to use a network share, saving it locally in a new folder will work just fine. For local deployment shares, you can later copy them to a flash drive or other portable storage for hands-on deployments. At my workplace we prefer to keep things simple since we support less than 50 systems, and thus our deployments are small batches of a few at one time. If you need to deploy to dozens and dozens of systems at once, a network deployment would be ideal.
3. Save your new deployment share and note its location. The new share will contain common folders such as "Control" and "Scripts".
4. Create a default [Task Sequence](https://web.sas.upenn.edu/jasonrw/2016/10/20/creating-task-sequences-for-mdt/) and note its name.
5. As per MDT practices, add your desired [source Windows media](https://web.sas.upenn.edu/jasonrw/2015/11/02/mdt-importing-an-operating-system/), [drivers](https://web.sas.upenn.edu/jasonrw/2016/09/25/mdt-and-drivers/), and [applications](https://www.techrepublic.com/article/how-to-deploy-applications-with-microsoft-deployment-toolkit/).
6. Exit MDT.
7. Continue with steps below... 
#### For those with Existing MDT Deployment Shares:
1. Download all all files included within this project and copy over A SELECT FEW of them to the respective folders of your deployment share. For example, if your deployment share is "D:\Deploy", then everything in the "Scripts" folder for this project should be copied over to D:\Deploy\Scripts. For files that already exist, I'd encourage you to make a backup of your version before copying this project's version. To do so, simply either rename the file (eg: "CustomSettings.ini" to "CustomSettings.original.ini") or copy it to another location. Note the following files and their usage:
    * Scripts folder: every file in this folder is safe to copy, as no stock files overwritten.
    * Control folder: CustomSettings.ini overwrites existing file. Please edit this file as appropriate for your own settings.
    * Control\MY_TASK_SEQ: This folder's name will reflect your own Task Sequence name. Use the Unattend.xml as a reference for changes you can make to your own Unattend.xml file. Do not copy this file. Instead reference it and make changes accordingly The entire oobeSystem section should be tweaked to your own settings.
2. Launch MDT and confirm that your saved deployment share loads without any errors.
3. Optional: change MDT's branding to reflect your organization or desired branding. This includes the following files:
    * Deploy\Scripts\LiteTouch.wsf -- replace organization name for _SMTSPAckageName
    * Deploy\Scripts\UDIWizard_Config.xml -- change welcome text
    * Deploy\Control\CustomSettings.ini -- add organization's name to a new variable _SMSTSORGNAME
    * Deploy\Control\MY_TASK_SEQ -- Your Task Sequence name will appear as a folder under the Control folder. Change the XML item "RegisteredOrganization" to your organization's name.
    * %PROGRAMFILES%\Microsoft Deployment Toolkit\Samples\Background.bmp -- You can edit this image to add your own branding. Make sure you do not change the image dimensions or format. Note that this image will be stretched to fill your Windows PE boot environment's screen.

## References

* [PSWindowsUpdate 2.0.0.4](https://www.powershellgallery.com/packages/PSWindowsUpdate/2.0.0.4) -- Amazing Powershell module to get reliable control over updating Windows.
* [Windows 10 Environment Variables](https://pureinfotech.com/list-environment-variables-windows-10/) -- My go-to list that is much easier to reference than Microsoft's documentation.
* [BcdEdit error with new ADK](https://social.technet.microsoft.com/Forums/en-US/60d86683-68e2-4a93-838b-231d61854804/bcdedit-returned-an-error-when-generating-an-media-iso-in-mdt?forum=mdt) -- Confirmation that Win10 ADK versions after 1511 do not work in Windows 7. Also [referenced here](https://forum.bigfix.com/t/deploy-mdt-bundle-creator-wadk-10-version-1607-mdt-build-8443-task-fails-to-validate-endpoint/20997/5) as well.
* [Windows 10 Default Services](http://servicedefaults.com/10/) -- Services included with a fresh install of Windows 10, along with their default Startup types.
* [Registry Keys to Remove Win10 Telemetry](https://michlstechblog.info/blog/windows-10-powershell-script-to-protect-your-privacy/) -- A good list of registry keys for Windows 10 telemetry to protect privacy on clients. This person put them all in a Powershell script to disable telemetry.
* [Group Policy Templates/Exports](https://getadmx.com/) -- A great site for viewing all of Microsoft's documentation on Group Policy, including the [associated registry keys](https://getadmx.com/HKLM/) in which you can drill down to individual keys.
* [MDT Variables](http://www.hayesjupe.com/sccm-and-mdt-list-of-variables/) -- A good listing of MDT variables you can reference in your own scripts.
* [Disable Win10 Animation & First Run Screens](https://blogs.technet.microsoft.com/mniehaus/2015/08/23/windows-10-mdt-2013-update-1-and-hideshell/) -- One of the most valuable changes to make to your deployment: eliminate first-run screens, animation, etc.
* [Unwanted Scheduled Tasks in Win10](https://github.com/W4RH4WK/Debloat-Windows-10/issues/22) -- Lots of telemetry to remove.

## Contributing

Feel free to submit any corrections to the scripting code or other files and I'll review them to include within the project. From my own deployment, I've removed organizational-specific code and settings. Therefore this public project is free to evolve over time on its own if anyone is interested in helping.

## Authors

* **"cipher nemo"** - *Initial work* - [ciphernemo](https://github.com/ciphernemo)

See also the list of [contributors](https://github.com/ciphernemo/Complete-Win10-Deploy/contributors) who participated in this project.

## License

This project is licensed under GNU GPL 3.0

## Acknowledgments

* Kudos to Michal Gajda for amazing work on his [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate/2.0.0.4) Powershell module. Without this, Windows update would be a royal PITA. For anyone who's tried to slipstream in their own updates with DISM/WSUS or Powershell, use another offline 3rd party utility, or just add packages inside MDT, you may know all too well the kludge-fest that is Windows update. Microsoft improved with Windows 10 updates thanks to cumulative patches and regular, updated RTMs, but patching in the smaller updates in-between is still a frustrating, sometimes broken experience.
* Thanks to ALL_FRONT_RANDOM for his [script to turn off WiFi](https://www.reddit.com/r/sysadmin/comments/9az53e/need_help_controlling_wifi/e502prt/?context=3), which is an adaptation from Ben N's [script to turn off Bluetooth]([Turn off WiFi Script](https://www.reddit.com/r/sysadmin/comments/9az53e/need_help_controlling_wifi/e502prt/?context=3) -- ALL_FRONT_RANDOM's).
