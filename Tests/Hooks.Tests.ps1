Describe "HooksTest"  {
	. (Join-Path $PSScriptRoot 'InitializeTest.ps1')

	Register-PoshHook 

	Context "Local hooked beep set to return true" {
		
		It "redirects the call" -Skip {
			Set-Hook -Dll "Kernel32.dll" -ReturnType "bool" -EntryPoint "Beep" -ScriptBlock {
				param([int]$Freq, [int]$Duration)
				return $true
			}

			Get-Hook | Remove-Hook
		}
	}

	Context "remote process hooked and beep set to return true"  {
		$Posh = Start-Process PowerShell -ArgumentList " -noexit '& [Console]::Beep()'" -PassThru

		It "redirects the call" -Skip {
			Set-Hook -ProcessId $Posh.ProcessId -Dll "Kernel32.dll" -ReturnType "bool" -EntryPoint "Beep" -ScriptBlock {
				param([int]$Freq, [int]$Duration)
				
				return $true
			}
		}
		
		$Posh | Stop-Process
		
	}
}
