$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent
Add-Type -Path (Join-Path $ScriptDirectory "PInvoke.cs")

$HookInject = (Get-Process -Id $PID).Modules | Where { $_.ModuleName -eq "HookInject.dll" }
if ($HookInject -eq $null)
{
	$EasyHookPath = (Join-Path $ScriptDirectory "EasyHook\EasyHook.dll")

	Copy-Item $EasyHookPath (Join-Path ([IO.Path]::GetTempPath()) "EasyHook.dll")

	$HookPath = (Join-Path ([IO.Path]::GetTempPath()) "HookInject.dll")
	Add-Type -Path $EasyHookPath
	Add-Type -Path (Join-Path $ScriptDirectory "HookInject.cs") -OutputAssembly $HookPath -ReferencedAssemblies "System.Runtime.Remoting","System.Management.Automation", $EasyHookPath -PassThru
	[Reflection.Assembly]::LoadFrom($HookPath)
}




