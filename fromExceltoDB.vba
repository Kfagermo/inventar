Sub SendInventoryToApp()
    Debug.Print "----------------------------------------"
    Debug.Print "Starting SendInventoryToApp at " & Now()
    
    ' First check if server is running
    If Not IsServerRunning Then
        MsgBox "Cannot connect to inventory server. Please ensure it is running before updating.", _
               vbExclamation, _
               "Server Not Available"
        Exit Sub
    End If
    
    ' Create HTTP request
    Dim xhr As Object
    Set xhr = CreateObject("MSXML2.XMLHTTP")
    
    On Error GoTo ErrorHandler
    
    ' Get the active worksheet
    Dim ws As Worksheet
    Set ws = ActiveSheet
    
    ' Find the last row with data
    Dim lastRow As Long
    lastRow = ws.Cells(ws.Rows.Count, "B").End(xlUp).row
    
    ' Check if there's any data to send
    If lastRow < 5 Then
        MsgBox "No inventory data found to send.", vbExclamation
        Exit Sub
    End If
    
    ' Ask for confirmation before sending
    Dim response As VbMsgBoxResult
    response = MsgBox("Are you sure you want to send inventory updates to the server?" & vbNewLine & _
                     "This will update " & (lastRow - 4) & " items.", _
                     vbQuestion + vbYesNo, _
                     "Confirm Update")
    
    If response = vbNo Then
        Exit Sub
    End If
    
    ' Show progress bar
    Application.StatusBar = "Preparing inventory data..."
    
    ' Create JSON array of inventory items
    Dim jsonData As String
    jsonData = "{""inventory"": ["
    
    ' Variables for validation warnings
    Dim warningMessages As String
    Dim warningCount As Long
    warningCount = 0
    
    ' Loop through rows starting from row 5 (assuming header is above)
    Dim i As Long
    For i = 5 To lastRow
        ' Update status bar
        Application.StatusBar = "Processing row " & i & " of " & lastRow & "..."
        
        ' Skip empty rows
        If Len(Trim(ws.Cells(i, 2).value)) > 0 Then
            ' Validate data before adding
            Dim rowWarning As String
            rowWarning = ValidateRow(ws, i)
            
            If Len(rowWarning) > 0 Then
                warningMessages = warningMessages & "Row " & i & ": " & rowWarning & vbNewLine
                warningCount = warningCount + 1
            End If
            
            If i > 5 Then jsonData = jsonData & ","
            
            ' Ensure numeric values are properly formatted
            Dim antall As Long
            Dim anbefalt As Long
            antall = IIf(IsNumeric(ws.Cells(i, 7).value), CLng(ws.Cells(i, 7).value), 0)
            anbefalt = IIf(IsNumeric(ws.Cells(i, 8).value), CLng(ws.Cells(i, 8).value), 0)
            
            jsonData = jsonData & "{"
            jsonData = jsonData & """el_nummer_id"":""" & CleanJSON(ws.Cells(i, 2).value) & """"
            jsonData = jsonData & ",""beskrivelse"":""" & CleanJSON(ws.Cells(i, 3).value) & """"
            jsonData = jsonData & ",""kategori"":""" & CleanJSON(ws.Cells(i, 4).value) & """"
            jsonData = jsonData & ",""hylle"":""" & CleanJSON(ws.Cells(i, 5).value) & """"
            jsonData = jsonData & ",""enhet"":""" & CleanJSON(ws.Cells(i, 6).value) & """"
            jsonData = jsonData & ",""antall"":" & antall
            jsonData = jsonData & ",""anbefalt_minimum"":" & anbefalt
            jsonData = jsonData & "}"
        End If
    Next i
    
    jsonData = jsonData & "]}"
    
    ' Show warnings if any
    If warningCount > 0 Then
        Dim warningResponse As VbMsgBoxResult
        warningResponse = MsgBox("Found " & warningCount & " warning(s):" & vbNewLine & vbNewLine & _
                               Left(warningMessages, 1000) & IIf(Len(warningMessages) > 1000, "...", "") & vbNewLine & vbNewLine & _
                               "Do you want to continue with the update?", _
                               vbExclamation + vbYesNo, _
                               "Data Validation Warnings")
        
        If warningResponse = vbNo Then
            Application.StatusBar = False
            Exit Sub
        End If
    End If
    
    ' Debug output
    Debug.Print "Sending JSON data:"
    Debug.Print Left(jsonData, 500) ' Print first 500 chars for debugging
    
    ' Update status
    Application.StatusBar = "Sending data to server..."
    
    ' Send the request
    xhr.Open "POST", "http://localhost:5000/update_inventory", False
    xhr.setRequestHeader "Content-Type", "application/json"
    xhr.send jsonData
    
    Debug.Print "Response Status: " & xhr.Status
    Debug.Print "Response Text: " & xhr.responseText
    
    If xhr.Status = 200 Then
        MsgBox "Inventory data sent successfully!" & vbNewLine & _
               "Updated " & (lastRow - 4) & " items.", vbInformation
    Else
        MsgBox "Error sending data: " & xhr.responseText, vbCritical
    End If
    
ExitSub:
    Application.StatusBar = False
    Exit Sub
    
ErrorHandler:
    Debug.Print "ERROR: " & Err.Description
    MsgBox "Error: " & Err.Description, vbCritical
    Resume ExitSub
End Sub

Private Function ValidateRow(ws As Worksheet, row As Long) As String
    Dim warnings As String
    
    ' Check for empty required fields
    If Len(Trim(ws.Cells(row, 2).value)) = 0 Then
        warnings = warnings & "Missing EL Nummer/ID. "
    End If
    If Len(Trim(ws.Cells(row, 3).value)) = 0 Then
        warnings = warnings & "Missing Beskrivelse. "
    End If
    
    ' Check for invalid numeric values
    If Not IsNumeric(ws.Cells(row, 7).value) Then
        warnings = warnings & "Invalid Antall value. "
    ElseIf ws.Cells(row, 7).value < 0 Then
        warnings = warnings & "Negative Antall value. "
    End If
    
    If Not IsNumeric(ws.Cells(row, 8).value) Then
        warnings = warnings & "Invalid Anbefalt Minimum value. "
    ElseIf ws.Cells(row, 8).value < 0 Then
        warnings = warnings & "Negative Anbefalt Minimum value. "
    End If
    
    ValidateRow = warnings
End Function

Private Function IsServerRunning() As Boolean
    On Error Resume Next
    
    Dim xhr As Object
    Set xhr = CreateObject("MSXML2.XMLHTTP")
    
    xhr.Open "GET", "http://localhost:5000/test_db", False
    xhr.send
    
    IsServerRunning = (xhr.Status = 200)
    
    On Error GoTo 0
End Function

Private Function CleanJSON(value As Variant) As String
    If IsEmpty(value) Or IsNull(value) Then
        CleanJSON = ""
    Else
        ' Clean and escape the string for JSON
        Dim cleanValue As String
        cleanValue = CStr(value)
        cleanValue = Replace(cleanValue, "\", "\\")
        cleanValue = Replace(cleanValue, """", "\""")
        cleanValue = Replace(cleanValue, vbNewLine, " ")
        cleanValue = Replace(cleanValue, vbCr, " ")
        cleanValue = Replace(cleanValue, vbLf, " ")
        CleanJSON = cleanValue
    End If
End Function

