Describe "HooksTest" {
	. (Join-Path $PSScriptRoot 'InitializeTest.ps1')

	Register-PoshHook 

	Context "Local hooked beep set to return false" {
		Set-Hook -Dll "Kernel32.dll" -ReturnType "bool" -EntryPoint "Beep" -ScriptBlock {
			param([int]$Freq, [int]$Duration)
			throw "Exception"
		}

		It "should return false" {
			[Console]::Beep(1000, 1000) | Should be $false
		}
		
		Get-Hook | Remove-Hook
	}

	Context "RemoteHookTest" {
		$Posh = Start-Process PowerShell -ArgumentList " -noexit '& [Console]::Beep()'" -PassThru

		Set-Hook -ProcessId $Posh.ProcessId -Dll "Kernel32.dll" -ReturnType "bool" -EntryPoint "Beep" -ScriptBlock {
			param([int]$Freq, [int]$Duration)
			"Frequency was ($Freq) and duration was ($Duration)" | Out-File C:\users\adriscoll\desktop\test.txt
			return $true
		}
	}
}
