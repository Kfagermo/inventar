Option Explicit

Private Sub Workbook_Open()
    Debug.Print "----------------------------------------"
    Debug.Print "Workbook opened at " & Now()
    
    ' First check if server is running
    If Not IsServerRunning Then
        MsgBox "Cannot connect to inventory server. Please ensure it is running before updating.", _
               vbExclamation, _
               "Server Not Available"
        Exit Sub
    End If
    
    ' Ask user if they want to update
    Dim response As VbMsgBoxResult
    response = MsgBox("Would you like to update the inventory data from the server?", _
                     vbQuestion + vbYesNo, _
                     "Update Inventory")
    
    If response = vbYes Then
        ' Show a message to user
        Application.StatusBar = "Updating inventory data..."
        
        ' Try to update inventory
        Call UpdateInventorySafely
        
        ' Clear status bar
        Application.StatusBar = False
    End If
End Sub

' Safe update function that includes pre-sync checks
Private Sub UpdateInventorySafely()
    ' Check data status before fetching
    If Not IsDataPresentInApp() Then
        MsgBox "App database is empty. Sync aborted to prevent data loss.", vbExclamation
        Exit Sub
    End If
    
    ' Proceed with fetching data
    Call UpdateInventory
End Sub

' Function to check if data is present in the app before syncing
Private Function IsDataPresentInApp() As Boolean
    Dim xhr As Object
    Set xhr = CreateObject("MSXML2.XMLHTTP")
    Dim url As String
    url = "https://localhost:5000/data_status"  ' Updated to HTTPS
    
    On Error GoTo ErrorHandler
    
    xhr.Open "GET", url, False
    xhr.setRequestHeader "Content-Type", "application/json"
    xhr.send
    
    If xhr.Status = 200 Then
        Dim json As Object
        Set json = JsonConverter.ParseJson(xhr.responseText)
        
        If json("status") = "data_present" Then
            IsDataPresentInApp = True
        Else
            IsDataPresentInApp = False
        End If
    Else
        MsgBox "Failed to retrieve data status: " & xhr.Status, vbCritical
        IsDataPresentInApp = False
    End If
    
    Exit Function
    
ErrorHandler:
    MsgBox "Error checking data status: " & Err.Description, vbCritical
    IsDataPresentInApp = False
End Function

' Function to check if the server is running
Private Function IsServerRunning() As Boolean
    On Error Resume Next
    
    Dim xhr As Object
    Set xhr = CreateObject("MSXML2.XMLHTTP")
    
    xhr.Open "GET", "https://localhost:5000/test_db", False  ' Updated to HTTPS
    xhr.send
    
    IsServerRunning = (xhr.Status = 200)
    
    On Error GoTo 0
End Function

' Helper function to parse JSON and update worksheet
Private Sub ParseAndUpdateInventory(ws As Worksheet, jsonText As String)
    ' Ensure you have added a reference to VBA-JSON or included the JSON parsing library
    Dim json As Object
    Set json = JsonConverter.ParseJson(jsonText)
    
    Dim inventory As Collection
    Set inventory = json("inventory")
    
    Dim row As Long
    row = 5 ' Starting row for data
    
    Dim item As Object
    For Each item In inventory
        ws.Cells(row, 2).Value = item("el_nummer_id")
        ws.Cells(row, 3).Value = item("beskrivelse")
        ws.Cells(row, 4).Value = item("kategori")
        ws.Cells(row, 5).Value = item("hylle")
        ws.Cells(row, 6).Value = item("enhet")
        ws.Cells(row, 7).Value = item("antall")
        ws.Cells(row, 8).Value = item("anbefalt_minimum")
        ' Add more fields if necessary
        row = row + 1
    Next item
End Sub

' Function to log errors to a hidden "ErrorLogs" sheet
Private Sub LogError(errorMessage As String)
    Dim logSheet As Worksheet
    On Error Resume Next
    Set logSheet = ThisWorkbook.Sheets("ErrorLogs")
    If logSheet Is Nothing Then
        Set logSheet = ThisWorkbook.Sheets.Add(After:=ThisWorkbook.Sheets(ThisWorkbook.Sheets.Count))
        logSheet.Name = "ErrorLogs"
        logSheet.Cells(1, 1).Value = "Timestamp"
        logSheet.Cells(1, 2).Value = "Error Message"
    End If
    On Error GoTo 0
    Dim lastRow As Long
    lastRow = logSheet.Cells(logSheet.Rows.Count, "A").End(xlUp).Row + 1
    logSheet.Cells(lastRow, 1).Value = Now()
    logSheet.Cells(lastRow, 2).Value = errorMessage
End Sub

' Function to backup the current workbook
Private Sub BackupWorkbook()
    Dim backupPath As String
    backupPath = ThisWorkbook.Path & "\Backup_" & Format(Now(), "yyyymmdd_hhnnss") & ".xlsm"
    ThisWorkbook.SaveCopyAs backupPath
    MsgBox "Backup created at " & backupPath, vbInformation
End Sub