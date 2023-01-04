Attribute VB_Name = "Sleep"
Declare PtrSafe Function SetTimer Lib "user32" (ByVal hwnd As LongLong, ByVal nIDEvent As LongLong, ByVal uElapse As LongLong, ByVal lpTimerfunc As LongLong) As LongLong
Declare PtrSafe Function KillTimer Lib "user32" (ByVal hwnd As LongLong, ByVal nIDEvent As LongLong) As LongLong

Public TimerID As LongLong 'Need a timer ID to eventually turn off the timer. If the timer ID <> 0 then the timer is running

Public Sub TriggerTimer(ByVal hwnd As Long, ByVal uMsg As Long, ByVal idevent As Long, ByVal Systime As Long)
  'MsgBox "The TriggerTimer function has been automatically called!"
  Call AutoResponder.Check
End Sub


Public Sub DeactivateTimer()
Dim lSuccess As LongLong
  lSuccess = KillTimer(0, TimerID)
  If lSuccess = 0 Then
    MsgBox "The timer failed to deactivate."
  Else
    TimerID = 0
  End If
End Sub

Public Sub ActivateTimer(ByVal nMinutes As Long)
  nMinutes = nMinutes * 1000 * 60 'The SetTimer call accepts milliseconds, so convert to minutes
  If TimerID <> 0 Then Call DeactivateTimer 'Check to see if timer is running before call to SetTimer
  TimerID = SetTimer(0, 0, nMinutes, AddressOf TriggerTimer)
  If TimerID = 0 Then
    MsgBox "The timer failed to activate."
  End If
End Sub

