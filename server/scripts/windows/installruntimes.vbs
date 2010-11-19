On Error Resume Next

' PostgreSQL VC++ runtime installation script for Windows
' Dave Page, EnterpriseDB

' Check the command line
If WScript.Arguments.Count <> 1 Then
 Wscript.Echo "Usage: installruntimes.vbs <Runtime package>"
 Wscript.Quit 127
End If

strPackage = WScript.Arguments.Item(0)

Dim objShell
Set objShell = WScript.CreateObject("WScript.Shell")
WScript.Echo "Executing the runtime installer: " & strPackage
Set WshSysEnv = WshShell.Environment("PROCESS")
strSystemRoot = WshSysEnv("COMSPEC")
iRet = objShell.Run(strSystemRoot & " /c "  & """" & strPackage & """ /q:a /c:""msiexec /i vcredist.msi /qb!""", 0, True)

If iRet <> 0 Then
    WScript.Echo "The runtime package exited with error code: " & iRet
    WScript.Quit iRet
End If

WScript.Echo "installruntimes.vbs ran to completion"
WScript.Quit 0
