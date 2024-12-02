Option Explicit

' Main subroutine to fetch inventory data from the server
Public Sub ImportInventoryFromDB()
    Debug.Print "----------------------------------------"
    Debug.Print "Starting ImportInventoryFromDB at " & Now()
    
    ' First check if server is running
    If Not Utilities.IsServerRunning Then
        MsgBox "Cannot connect to inventory server. Please ensure it is running before updating.", _
               vbExclamation, _
               "Server Not Available"
        Exit Sub
    End If
    
    ' Ask for confirmation
    Dim response As VbMsgBoxResult
    response = MsgBox("This will update the inventory data from the server. Continue?", _
                     vbQuestion + vbYesNo, _
                     "Confirm Import")
    
    If response = vbNo Then Exit Sub
    
    ' Create HTTP request
    Dim xhr As Object
    Set xhr = CreateObject("WinHttp.WinHttpRequest.5.1")
    
    On Error GoTo ErrorHandler
    
    ' Get the active worksheet
    Dim ws As Worksheet
    Set ws = ActiveSheet
    
    ' Show status
    Application.StatusBar = "Fetching inventory data..."
    Application.ScreenUpdating = False
    
    ' Configure request
    xhr.Option(9) = 2048        ' Enable all security protocols
    xhr.Option(4) = 13056       ' Ignore certificate errors
    xhr.Option(6) = False       ' Don't follow redirects
    
    ' Make the request
    xhr.Open "GET", "https://152.93.129.206/api/inventory", False
    xhr.setRequestHeader "Content-Type", "application/json"
    xhr.send
    
    ' Check response
    If xhr.Status <> 200 Then
        MsgBox "Error fetching data: " & xhr.responseText, vbCritical
        Exit Sub
    End If
    
    ' Clean up any existing delete buttons
    CleanupDeleteButtons
    
    ' Clear existing data (keeping headers)
    Dim lastRow As Long
    lastRow = ws.Cells(ws.Rows.Count, "B").End(xlUp).Row
    If lastRow > 4 Then
        ws.Range("B5:H" & lastRow).ClearContents
    End If
    
    ' Parse JSON response
    Dim jsonText As String
    jsonText = xhr.responseText
    
    ' Start row for data
    Dim row As Long
    row = 5
    
    ' Extract values between [ and ] to get the array of items
    Dim startPos As Long, endPos As Long
    startPos = InStr(1, jsonText, "[") + 1
    endPos = InStrRev(jsonText, "]") - 1
    
    If startPos > 0 And endPos > 0 Then
        jsonText = Mid(jsonText, startPos, endPos - startPos + 1)
        
        ' Split into individual objects
        Dim items() As String
        items = SplitJsonObjects(jsonText)
        
        ' Process each item
        Dim i As Long
        For i = LBound(items) To UBound(items)
            ' Get values using helper function
            Dim el_nummer_id As String: el_nummer_id = GetJsonValue(items(i), "el_nummer_id")
            Dim beskrivelse As String: beskrivelse = GetJsonValue(items(i), "beskrivelse")
            Dim kategori As String: kategori = GetJsonValue(items(i), "kategori")
            Dim hylle As String: hylle = GetJsonValue(items(i), "hylle")
            Dim enhet As String: enhet = GetJsonValue(items(i), "enhet")
            Dim antall As String: antall = GetJsonValue(items(i), "antall")
            Dim anbefalt_minimum As String: anbefalt_minimum = GetJsonValue(items(i), "anbefalt_minimum")
            
            ' Write values
            ws.Cells(row, "B").Value2 = el_nummer_id
            ws.Cells(row, "C").Value2 = beskrivelse
            ws.Cells(row, "D").Value2 = kategori
            ws.Cells(row, "E").Value2 = hylle
            ws.Cells(row, "F").Value2 = enhet
            ws.Cells(row, "G").Value2 = antall
            ws.Cells(row, "H").Value2 = anbefalt_minimum
            
            ' Add delete button
            Dim btn As Button
            Set btn = ws.Buttons.Add(ws.Cells(row, "A").Left, ws.Cells(row, "A").Top, _
                                    ws.Cells(row, "A").Width, ws.Cells(row, "A").Height)
            With btn
                .OnAction = "DeleteSelectedItem"
                .Caption = "X"
                .Name = "DeleteBtn_" & el_nummer_id
            End With
            
            row = row + 1
        Next i
    End If
    
    Application.StatusBar = False
    Application.ScreenUpdating = True
    
    MsgBox "Inventory data updated successfully!", vbInformation
    Exit Sub

ErrorHandler:
    Application.StatusBar = False
    Application.ScreenUpdating = True
    MsgBox "Error: " & Err.Description, vbCritical
    Debug.Print "Error " & Err.Number & ": " & Err.Description
End Sub

Private Function SplitJsonObjects(jsonText As String) As String()
    Dim result() As String
    ReDim result(0)
    
    Dim objCount As Long: objCount = -1
    Dim bracketCount As Long: bracketCount = 0
    Dim startPos As Long: startPos = 1
    Dim i As Long, char As String
    
    For i = 1 To Len(jsonText)
        char = Mid(jsonText, i, 1)
        Select Case char
            Case "{"
                bracketCount = bracketCount + 1
                If bracketCount = 1 Then startPos = i
            Case "}"
                bracketCount = bracketCount - 1
                If bracketCount = 0 Then
                    objCount = objCount + 1
                    ReDim Preserve result(objCount)
                    result(objCount) = Mid(jsonText, startPos, i - startPos + 1)
                End If
        End Select
    Next i
    
    SplitJsonObjects = result
End Function

Private Function GetJsonValue(jsonObj As String, key As String) As String
    Dim searchKey As String: searchKey = """" & key & """:"
    Dim startPos As Long: startPos = InStr(1, jsonObj, searchKey)
    
    If startPos = 0 Then
        GetJsonValue = ""
        Exit Function
    End If
    
    startPos = startPos + Len(searchKey)
    Dim valueStart As Long: valueStart = startPos
    
    ' Skip whitespace
    While Mid(jsonObj, valueStart, 1) = " "
        valueStart = valueStart + 1
    Wend
    
    Dim value As String
    If Mid(jsonObj, valueStart, 1) = """" Then
        ' String value
        valueStart = valueStart + 1
        Dim valueEnd As Long: valueEnd = InStr(valueStart, jsonObj, """")
        value = Mid(jsonObj, valueStart, valueEnd - valueStart)
    Else
        ' Number value
        Dim commaPos As Long: commaPos = InStr(valueStart, jsonObj, ",")
        Dim bracePos As Long: bracePos = InStr(valueStart, jsonObj, "}")
        If commaPos = 0 Then commaPos = bracePos
        If commaPos < bracePos Or bracePos = 0 Then
            value = Mid(jsonObj, valueStart, commaPos - valueStart)
        Else
            value = Mid(jsonObj, valueStart, bracePos - valueStart)
        End If
    End If
    
    GetJsonValue = Trim(value)
End Function