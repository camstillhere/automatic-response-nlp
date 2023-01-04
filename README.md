# Automatic Responder/Mail Scanner
A little email monitor that will respond with the results of NLP analysis

# Warning
This project was made in less than 10 hours. It was more fun then production to show that it could work. Don't expect the code to be perfect, resilient or heavily documented.

# Usage
Yeah, probably don't go and use this for reals ;) It's a project to show how it all can work not to flesh out every possible scenario.

If you really want to enter the world of Automatic Responders:
## Create a folder to hold the OOO
```
C:\OOO
```
Place in all the files in the ruby directory here.

## Ensure Nuix is installed
Currently this script expects Nuix to be installed here:
```
c:\Program Files\Nuix\Nuix 9.10\nuix_console.exe
```

## Adjust the shell command
if the path is different OR you need to adjust licensing options.

This is in Outlook -> Developer Tab -> ThisOutlookSession -> inboxItems_ItemAdd


## Enable Developer tab in 
Once done open the developer tab and restore the various files found in the Outlook folder.
Save restart Outlook or hit the Run on the Application_Startup() method.
