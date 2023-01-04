Attribute VB_Name = "AutoResponder"
Public Sub Check()
On Error GoTo ErrorHandler
    Dim oFSO As New FileSystemObject
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFolder = oFSO.GetFolder("C:\OOO\outlookOut")
    Dim outlookApp As Outlook.Application
    Dim objectNS As Outlook.NameSpace
    
    Set outlookApp = Outlook.Application
    Set objectNS = outlookApp.GetNamespace("MAPI")
    Dim oFile As File
    Dim responseType As String
    Dim FileToRead
    For Each oFile In oFolder.Files
        
        responseType = oFSO.GetExtensionName(oFile.Path)
        EntryID = oFSO.GetBaseName(oFile.Name)
        Set FileToRead = oFSO.OpenTextFile(oFile.Path, ForReading)
        htmlText = FileToRead.ReadAll
        FileToRead.Close
        
        
        Dim Item As MailItem
        Set Item = objectNS.GetItemFromID(EntryID)
        Dim olReply As MailItem
        Set olReply = Item.Reply
        Dim count As Integer
        count = olReply.Attachments.count
        Dim fallback As Integer
        fallback = 5
        While (count > 0)
            olReply.Attachments.Remove (1)
            count = olReply.Attachments.count
            
            fallback = fallback - 1
            If (fallback < 0) Then
                count = 0
            End If
            
        Wend
        
        Dim subject As String
        originalSubject = Split(Item.subject, ":")(UBound(Split(Item.subject, ":"))) 'subject without the RE:/FW etc
        If (responseType = "internal") Then
            olReply.subject = "Out Of Office [or am I?]: " & originalSubject
            olReply.HTMLBody = htmlText ' + Item.HTMLBody
        Else
            olReply.subject = "Automatic Reply: " & originalSubject
            olReply.HTMLBody = htmlText
        End If
        If (oFSO.FileExists("C:\OOO\active.txt")) Then
            olReply.Send
        Else
            If (oFSO.FileExists("C:\OOO\display.txt")) Then
                olReply.Display
            Else
                If (oFSO.FileExists("C:\OOO\draft.txt")) Then
                    olReply.Save
                    olReply.Close (olSave)
                End If
            End If
        End If
        oFile.Delete
    Next oFile
    
ExitCheck:
    Exit Sub
ErrorHandler:
    MsgBox Err.Number & " - " & Err.Description
    Exit Sub
End Sub

