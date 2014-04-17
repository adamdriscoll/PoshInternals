$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent
Add-Type -Path (Join-Path $ScriptDirectory "PInvoke.cs")

$EasyHookPath = (Join-Path $ScriptDirectory "EasyHook\EasyHook.dll")

Copy-Item $EasyHookPath (Join-Path ([IO.Path]::GetTempPath()) "EasyHook.dll")

$Random = Get-Random -Minimum 1 -Maximum 1000

$HookPath = (Join-Path ([IO.Path]::GetTempPath()) "HookInject$Random.dll")
Add-Type -Path $EasyHookPath | Out-Null 
Add-Type -Path (Join-Path $ScriptDirectory "HookInject.cs") -OutputAssembly $HookPath -ReferencedAssemblies "System.Runtime.Remoting","System.Management.Automation", $EasyHookPath  | Out-Null 
$HookDll = Add-Type -Path $HookPath -PassThru 
[PoshInternals.HookInterface]::HookDllPath = $HookPath
