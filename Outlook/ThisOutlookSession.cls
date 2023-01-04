VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisOutlookSession"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit
Private WithEvents inboxItems As Outlook.Items
Attribute inboxItems.VB_VarHelpID = -1
Private Sub Application_Startup()
    Dim outlookApp As Outlook.Application
    Dim objectNS As Outlook.NameSpace
    
    Set outlookApp = Outlook.Application
    Set objectNS = outlookApp.GetNamespace("MAPI")
    Set inboxItems = objectNS.GetDefaultFolder(olFolderInbox).Items
    MsgBox "OOO Work has been registered..."
    Call Sleep.ActivateTimer(1) 'Set timer to go off every 1 minute
End Sub

Private Sub Application_Quit()
  If Sleep.TimerID <> 0 Then Call Sleep.DeactivateTimer 'Turn off timer upon quitting **VERY IMPORTANT**
End Sub


Private Sub inboxItems_ItemAdd(ByVal Item As Object)
On Error GoTo ErrorHandler
    'If Item.Class = OlObjectClass.olMail Then
        Dim savePath As String
        savePath = "C:/OOO/outlookIn/" & Item.EntryID & ".msg"
        Item.SaveAs savePath
        Dim RetVal
        RetVal = Shell("""c:\Program Files\Nuix\Nuix 9.10\nuix_console.exe"" " & _
                "-licencesourcetype " & _
                "cloud-server " & _
                "-licencesourcelocation https://licence-api.nuix.com " & _
                "-licencetype enterprise-reviewer " & _
                """C:\OOO\scanItemWithNLP.rb"" " & _
                savePath, vbMinimizedNoFocus)
    'End If
ExitNewItem:
    Exit Sub
ErrorHandler:
    MsgBox Err.Number & " - " & Err.Description
    Resume ExitNewItem
End Sub
