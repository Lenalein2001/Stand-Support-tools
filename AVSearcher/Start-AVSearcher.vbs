Set oShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptPath = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "AVSearcher.ps1")
If Not fso.FileExists(scriptPath) Then
  WScript.Echo "AVSearcher.ps1 not found next to this launcher (" & scriptPath & ")."
  WScript.Quit 1
End If
cmd = "powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """"
oShell.Run cmd, 0, False  ' 0 = hidden window, False = don't wait
