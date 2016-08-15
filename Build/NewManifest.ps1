$FunctionsToExport = @(  'Close-ActivationContext',
						'Close-Handle',
						'ConvertTo-Ast',
						'ConvertTo-Object',
						'ConvertTo-Pointer',
						'ConvertTo-RegularFileName',
						'ConvertTo-String',
						'Enter-Mutex',
						'Exit-Mutex',
						'Get-Ast',
						'Get-ComputerSID',
						'Get-Desktop',
						'Get-Dll',
						'Get-Handle',
						'Get-Hook',
						'Get-LogonSession',
						'Get-Parameter',
						'Get-PendingFileRenameOperation',
						'Get-PipeList',
						'Get-Size',
						'Register-PoshHook',
						'Install-BlueScreenSaver',
						'Move-FileOnReboot',
						'New-ActivationContext',
						'New-MemoryMappedFile',
						'New-Mutex',
						'New-Desktop',
						'Open-ActivationContext',
						'Open-MemoryMappedFile',
						'Out-MemoryMappedFile',
						'Out-MiniDump',
						'Read-MemoryMappedFile',
						'Remove-ActivationContext',
						'Remove-Extent',
						'Remove-FileOnReboot',
						'Remove-Hook',
						'Remove-MemoryMappedFile',
						'Resume-Process',
						'Send-NamedPipeMessage',
						'Set-Hook',
						'Set-Privilege',
						'Set-WorkingSetToMin',
						'Show-Desktop',
						'Start-Process',
						'Start-RemoteProcess',
						'Suspend-Process',
						'Unregister-PoshHook')

$NestedModules = @(
				  ".\Ast.ps1",
                  ".\ActivationContext.ps1", 
                  ".\BlueScreen.ps1", 
                  ".\Desktops.ps1",
                  ".\Get-ComputerSID.ps1", 
                  ".\Handle.ps1",
				  ".\Hooks.ps1",
				  ".\Interop.ps1",
                  ".\ListDlls.ps1", 
				  '.\ListUsers.ps1',
				  ".\Mutex.ps1",
                  ".\MoveFile.ps1", 
				  ".\MemoryMappedFile.ps1", 
                  ".\NamedPipes.ps1",
                  ".\PendMoves.ps1", 
                  ".\PipeList.ps1", 
                  ".\PoshExec.ps1",
                  ".\Procdump.ps1", 
                  ".\privilege.ps1", 
                  ".\Set-WorkingSetToMin.ps1",
				  ".\Suspend.ps1")

$NewModuleManifestParams = @{
	ModuleVersion = $ENV:APPVEYOR_BUILD_VERSION
	Path = (Join-Path $PSScriptRoot '..\PoshInternals.psd1')
	Author = 'Adam Driscoll'
	Company = 'Adam Driscoll'
	Description = 'Collection of system internals tools for PowerShell.'
	FunctionsToExport = $FunctionsToExport
	NestedModules = $NestedModules
	ProjectUri = 'https://github.com/adamdriscoll/poshinternals'
	Tags = @('SysInternals', 'WindowsInternals', 'Windows')
	RequiredAssemblies = 'System.Web'
	Guid = 'e4e6ae5b-ac04-41a3-ac9b-61c52df4a7fe'
	ScriptsToProcess = @(".\Pinvoke.ps1")
}

New-ModuleManifest @NewModuleManifestParams