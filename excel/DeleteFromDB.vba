Option Explicit

Public Sub DeleteSelectedItem()
    ' Get the button that was clicked
    Dim clickedButton As Object
    Set clickedButton = ActiveSheet.Buttons(Application.Caller)
    
    ' Extract the el_nummer_id from the button name
    Dim el_nummer_id As String
    el_nummer_id = Split(clickedButton.Name, "DeleteBtn_")(1)
    
    ' Find the row with this el_nummer_id
    Dim ws As Worksheet
    Set ws = ActiveSheet
    
    Dim foundCell As Range
    Set foundCell = ws.Range("B:B").Find(What:=el_nummer_id, LookIn:=xlValues, LookAt:=xlWhole)
    
    If foundCell Is Nothing Then
        MsgBox "Could not find item to delete.", vbExclamation
        Exit Sub
    End If
    
    ' Confirm deletion
    Dim response As VbMsgBoxResult
    response = MsgBox("Are you sure you want to delete item with EL number/ID: " & el_nummer_id & "?", _
                     vbQuestion + vbYesNo + vbDefaultButton2, _
                     "Confirm Deletion")
    
    If response = vbNo Then Exit Sub
    
    ' Create HTTP request
    Dim xhr As Object
    Set xhr = CreateObject("WinHttp.WinHttpRequest.5.1")
    
    On Error GoTo ErrorHandler
    
    ' Configure request
    xhr.Option(9) = 2048
    xhr.Option(4) = 13056
    xhr.Option(6) = False
    
    ' Send the delete request
    xhr.Open "POST", "https://152.93.129.206/api/delete_inventory_item", False
    xhr.setRequestHeader "Content-Type", "application/json"
    xhr.setRequestHeader "Accept", "application/json"
    xhr.send "{""el_nummer_id"": """ & el_nummer_id & """}"
    
    ' Debug output
    Debug.Print "Delete request for item: " & el_nummer_id
    Debug.Print "Response Status: " & xhr.Status
    Debug.Print "Response Text: " & xhr.responseText
    
    If xhr.Status = 200 Then
        ' Delete the button
        clickedButton.Delete
        
        ' Delete the row from Excel
        ws.Rows(foundCell.Row).Delete Shift:=xlUp
        MsgBox "Item deleted successfully!", vbInformation
    Else
        MsgBox "Error deleting item. Server response: " & xhr.responseText, vbCritical
    End If
    
    Exit Sub

ErrorHandler:
    MsgBox "Error: " & Err.Description & vbNewLine & _
           "Item ID: " & el_nummer_id, vbCritical
    Debug.Print "Error " & Err.Number & ": " & Err.Description
End Sub

' Helper function to clean JSON strings (copied from fromExceltoDB)
Private Function CleanJSON(Value As Variant) As String
    If IsEmpty(Value) Or IsNull(Value) Then
        CleanJSON = ""
    Else
        Dim cleanValue As String
        cleanValue = CStr(Value)
        cleanValue = Replace(cleanValue, "\", "\\")
        cleanValue = Replace(cleanValue, """", "\""")
        cleanValue = Replace(cleanValue, vbNewLine, " ")
        cleanValue = Replace(cleanValue, vbCr, " ")
        cleanValue = Replace(cleanValue, vbLf, " ")
        CleanJSON = cleanValue
    End If
End Function

' Helper function to clean up all delete buttons
Public Sub CleanupDeleteButtons()
    Dim ws As Worksheet
    Set ws = ActiveSheet
    
    Dim btn As Button
    For Each btn In ws.Buttons
        If Left(btn.Name, 9) = "DeleteBtn_" Then
            btn.Delete
        End If
    Next btn
End Sub