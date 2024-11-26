Option Explicit

' Main update function
Sub UpdateInventory()
    Debug.Print "----------------------------------------"
    Debug.Print "Starting UpdateInventory at " & Now()
    
    ' Create HTTP request
    Dim xhr As Object
    Set xhr = CreateObject("MSXML2.XMLHTTP")
    
    On Error GoTo ErrorHandler
    
    Application.StatusBar = "Fetching inventory data..."
    
    ' Add timestamp to URL to prevent caching
    Dim timestamp As String
    timestamp = Format(Now(), "yyyymmddhhnnss")
    xhr.Open "GET", "http://localhost:5000/inventory?t=" & timestamp, False
    xhr.send
    
    Debug.Print "Request URL: " & "http://localhost:5000/inventory?t=" & timestamp
    Debug.Print "Response Status: " & xhr.Status
    
    If xhr.Status = 200 Then
        Dim ws As Worksheet
        Set ws = ActiveSheet
        ws.Range("B5:H" & ws.Rows.Count).ClearContents
        
        Dim jsonText As String
        jsonText = xhr.responseText
        Debug.Print "Raw Response: " & Left(jsonText, 200)
        
        ' Parse JSON
        ParseAndUpdateInventory ws, jsonText
        
        MsgBox "Data updated successfully!", vbInformation
    Else
        MsgBox "Error fetching data: " & xhr.responseText, vbCritical
    End If
    
ExitSub:
    Application.StatusBar = False
    Debug.Print "Finished UpdateInventory at " & Now()
    Debug.Print "----------------------------------------"
    Exit Sub
    
ErrorHandler:
    Debug.Print "ERROR: " & Err.Description
    MsgBox "Error: " & Err.Description, vbCritical
    Resume ExitSub
End Sub

' Helper function to parse JSON and update worksheet
Private Sub ParseAndUpdateInventory(ws As Worksheet, jsonText As String)
    ' Find the inventory array
    Dim startPos As Long
    startPos = InStr(1, jsonText, """inventory"":[") + 11
    
    If startPos > 0 Then
        ' Extract items array
        Dim itemsText As String
        itemsText = Mid(jsonText, startPos)
        itemsText = Mid(itemsText, 2, InStr(1, itemsText, "]") - 2)
        
        ' Split into individual items
        Dim items As Variant
        items = Split(itemsText, "},{")
        
        Dim row As Long
        row = 5
        
        Dim i As Long
        For i = 0 To UBound(items)
            Dim item As String
            item = items(i)
            
            ' Clean up JSON brackets
            item = Replace(item, "[{", "")
            item = Replace(item, "{", "")
            item = Replace(item, "}]", "")
            item = Replace(item, "}", "")
            
            Debug.Print "Processing item " & (i + 1)
            Debug.Print "Raw item data: " & Left(item, 200)
            
            UpdateRowFromItem ws, row, item
            row = row + 1
        Next i
    End If
End Sub

' Helper function to update a single row
Private Sub UpdateRowFromItem(ws As Worksheet, row As Long, item As String)
    ' Extract values
    Dim el_nummer As String
    Dim beskrivelse As String
    Dim kategori As String
    Dim hylle As String
    Dim enhet As String
    Dim antall As Long
    Dim anbefalt As Long
    
    el_nummer = GetJsonValue(item, "el_nummer_id")
    beskrivelse = GetJsonValue(item, "beskrivelse")
    kategori = GetJsonValue(item, "kategori")
    hylle = GetJsonValue(item, "hylle")
    enhet = GetJsonValue(item, "enhet")
    
    ' Handle numeric values
    Dim antallStr As String
    Dim anbefaltStr As String
    antallStr = GetNumericValue(item, "antall")
    anbefaltStr = GetNumericValue(item, "anbefalt_minimum")
    
    Debug.Print "For item " & el_nummer & ":"
    Debug.Print "  Raw antall value: " & antallStr
    Debug.Print "  Raw anbefalt value: " & anbefaltStr
    
    ' Convert to numbers
    If IsNumeric(antallStr) Then antall = CLng(antallStr)
    If IsNumeric(anbefaltStr) Then anbefalt = CLng(anbefaltStr)
    
    ' Write to sheet if we have a valid el_nummer
    If Len(el_nummer) > 0 Then
        ws.Cells(row, 2) = el_nummer
        ws.Cells(row, 3) = beskrivelse
        ws.Cells(row, 4) = kategori
        ws.Cells(row, 5) = hylle
        ws.Cells(row, 6) = enhet
        ws.Cells(row, 7).value = antall
        ws.Cells(row, 8).value = anbefalt
    End If
End Sub

' Helper function to get string values from JSON
Private Function GetJsonValue(jsonString As String, key As String) As String
    On Error GoTo ErrorHandler
    
    Dim startPos As Long
    Dim endPos As Long
    
    ' Look for string value first
    startPos = InStr(1, jsonString, """" & key & """:""")
    If startPos > 0 Then
        ' String value
        startPos = startPos + Len(key) + 4
        endPos = InStr(startPos, jsonString, """")
        If endPos > 0 Then
            GetJsonValue = Mid(jsonString, startPos, endPos - startPos)
        End If
    Else
        ' Look for non-string value
        startPos = InStr(1, jsonString, """" & key & """:")
        If startPos > 0 Then
            startPos = startPos + Len(key) + 3
            endPos = InStr(startPos, jsonString, ",")
            If endPos = 0 Then endPos = Len(jsonString) + 1
            GetJsonValue = Trim(Mid(jsonString, startPos, endPos - startPos))
        End If
    End If
    Exit Function
    
ErrorHandler:
    GetJsonValue = ""
End Function

' Helper function to get numeric values from JSON
Private Function GetNumericValue(jsonString As String, key As String) As String
    On Error GoTo ErrorHandler
    
    Dim startPos As Long
    Dim endPos As Long
    
    startPos = InStr(1, jsonString, """" & key & """:")
    
    If startPos > 0 Then
        startPos = startPos + Len(key) + 3
        endPos = InStr(startPos, jsonString, ",")
        If endPos = 0 Then endPos = Len(jsonString) + 1
        
        Dim value As String
        value = Trim(Mid(jsonString, startPos, endPos - startPos))
        
        ' Clean numeric value
        GetNumericValue = CleanNumericValue(value)
    Else
        GetNumericValue = "0"
    End If
    Exit Function
    
ErrorHandler:
    GetNumericValue = "0"
End Function

' Helper function to clean numeric values
Private Function CleanNumericValue(value As String) As String
    Dim cleanValue As String
    Dim i As Long
    
    For i = 1 To Len(value)
        If IsNumeric(Mid(value, i, 1)) Or Mid(value, i, 1) = "." Then
            cleanValue = cleanValue & Mid(value, i, 1)
        End If
    Next i
    
    If Len(cleanValue) = 0 Then
        CleanNumericValue = "0"
    Else
        CleanNumericValue = cleanValue
    End If
End Function
