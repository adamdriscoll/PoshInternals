$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent
Add-Type -Path (Join-Path $ScriptDirectory "PInvoke.cs")
