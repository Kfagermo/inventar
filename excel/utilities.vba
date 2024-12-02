Option Explicit

' Function to check if the server is running by accessing the test CSV endpoint
Public Function IsServerRunning() As Boolean
    On Error Resume Next
    
    Debug.Print "Testing server connection..."
    
    Dim xhr As Object
    Set xhr = CreateObject("WinHttp.WinHttpRequest.5.1")
    
    ' Configure SSL/TLS settings
    xhr.Option(9) = 2048        ' Enable all security protocols
    xhr.Option(4) = 13056       ' Ignore certificate errors
    xhr.Option(6) = False       ' Don't follow redirects
    
    xhr.Open "GET", "https://152.93.129.206/api/test_db", False
    xhr.setRequestHeader "Content-Type", "application/json"
    xhr.setRequestHeader "Accept", "application/json"
    
    Debug.Print "Sending test request to server..."
    xhr.send
    
    Dim errNum As Long
    errNum = Err.Number
    
    If errNum <> 0 Then
        Debug.Print "Connection Error: " & Err.Description
        Debug.Print "Error Number: " & errNum
        IsServerRunning = False
        Exit Function
    End If
    
    Debug.Print "Server Response Status: " & xhr.Status
    Debug.Print "Server Response: " & Left(xhr.responseText, 200)
    
    IsServerRunning = (xhr.Status = 200)
    
    On Error GoTo 0
End Function

' Subroutine to log errors into an "ErrorLogs" worksheet
Public Sub LogError(errorMessage As String)
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