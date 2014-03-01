TestFixture "HooksTest" {
	TestSetup {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}

	TestCase "LocalHookTest" {
		Set-Hook -Local -Dll "Kernel32.dll" -ReturnType "bool" -EntryPoint "Beep" -ScriptBlock {
			param([int]$Freq, [int]$Duration)
			Write-Host "Frequency was ($Freq) and duration was ($Duration)"
			return $true
		}

		[Console]::Beep(1000, 1000)
	}
}
