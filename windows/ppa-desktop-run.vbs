' Launcher that starts ppa-desktop-run.ps1 without any visible console window.
' Using WScript.Shell.Run with window style 0 (SW_HIDE) avoids the brief
' PowerShell console flash that occurs when using powershell.exe -WindowStyle Hidden.
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)

Dim args
args = ""
If WScript.Arguments.Count > 0 Then
    args = " """ & WScript.Arguments(0) & """"
End If

Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptDir & "\ppa-desktop-run.ps1""" & args, 0, False
