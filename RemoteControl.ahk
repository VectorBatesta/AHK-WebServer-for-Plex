// AHK v2 script using .NET’s HttpListener for a simple HTTP server
// This script binds to the IP 192.168.200.100 on port 8080

listener := ComObjCreate("System.Net.HttpListener")
listener.Prefixes.Add("http://192.168.200.100:8080/")
listener.Start()
MsgBox("HTTP server started on http://192.168.200.100:8080/")

encoding := ComObjCall("System.Text.Encoding", "UTF8")

while true {
    context := listener.GetContext()  ; Wait for a request
    req := context.Request
    res := context.Response
    path := req.Url.AbsolutePath
    responseText := ""

    if (path = "/left") {
         Send("{Left}")
         responseText := "Left key sent"
    } else if (path = "/right") {
         Send("{Right}")
         responseText := "Right key sent"
    } else if (path = "/prev") {
         Send("{PgUp}")
         responseText := "Previous Episode (Page Up) sent"
    } else if (path = "/next") {
         Send("{PgDn}")
         responseText := "Next Episode (Page Down) sent"
    } else if (path = "/pause") {
         Send("{Space}")
         responseText := "Pause (Space) sent"
    } else {
         responseText := "Unknown command"
    }

    buffer := encoding.GetBytes(responseText)
    res.ContentLength64 := buffer.Length
    stream := res.OutputStream
    stream.Write(buffer, 0, buffer.Length)
    stream.Close()
}
