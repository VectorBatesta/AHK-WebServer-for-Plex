#Requires AutoHotkey v2.0
#SingleInstance Force

; Initialize Winsock
wsaData := Buffer(394)
if (DllCall("Ws2_32\WSAStartup", "ushort", 0x202, "ptr", wsaData)) {
    MsgBox "WSAStartup failed. Error: " A_LastError
    ExitApp
}

; Create socket
s := DllCall("Ws2_32\socket", "int", 2, "int", 1, "int", 6, "ptr")
if (s = -1) {
    MsgBox "Socket creation failed. Error: " DllCall("Ws2_32\WSAGetLastError")
    ExitApp
}

; Bind to port 8080
addr := Buffer(16)
NumPut("ushort", 2, addr, 0)                     ; AF_INET
NumPut("ushort", DllCall("Ws2_32\htons", "ushort", 8080, "ushort"), addr, 2)
NumPut("uint", 0, addr, 4)                       ; INADDR_ANY

if (DllCall("Ws2_32\bind", "ptr", s, "ptr", addr, "int", 16, "int")) {
    MsgBox "Bind failed. Error: " DllCall("Ws2_32\WSAGetLastError")
    ExitApp
}

; Listen for connections
if (DllCall("Ws2_32\listen", "ptr", s, "int", 5)) {
    MsgBox "Listen failed. Error: " DllCall("Ws2_32\WSAGetLastError")
    ExitApp
}

TrayTip "Web Remote Ready", "Listening on port 8080", 1

Loop {
    ; Accept connection
    clientAddr := Buffer(16)
    addrLen := 16
    clientSocket := DllCall("Ws2_32\accept", "ptr", s, "ptr", clientAddr, "ptr", addrLen, "ptr")
    if (clientSocket = -1)
        continue
    
    ; Read request
    buffer := Buffer(4096)
    bytesRead := DllCall("Ws2_32\recv", "ptr", clientSocket, "ptr", buffer.Ptr, "int", buffer.Size, "int", 0)
    if (bytesRead > 0) {
        ; Use buffer.Ptr with StrGet to read from the buffer memory
        request := StrGet(buffer.Ptr, bytesRead, "UTF-8")
        
        ; Parse path
        path := ""
        if (RegExMatch(request, "GET (/\w+)", &match))
            path := match[1]
        
        ; Execute corresponding action
        switch path {
            case "/left":   Send "{Left}"
            case "/right":  Send "{Right}"
            case "/prev":   Send "{PgUp}"
            case "/next":   Send "{PgDn}"
            case "/pause":  Send "{Space}"
        }
    }
    
    ; Send response
    response := "HTTP/1.1 200 OK`r`n"
              . "Content-Type: text/plain`r`n"
              . "Connection: close`r`n`r`n"
              . "OK"
    DllCall("Ws2_32\send", "ptr", clientSocket, "astr", response, "int", StrLen(response), "int", 0)
    DllCall("Ws2_32\closesocket", "ptr", clientSocket)
}

OnExit(*) {
    DllCall("Ws2_32\closesocket", "ptr", s)
    DllCall("Ws2_32\WSACleanup")
}