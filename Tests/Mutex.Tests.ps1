Describe "Mutex" {
	. (Join-Path $PSScriptRoot 'InitializeTest.ps1')

	Context "Enter-Mutex" {
		$Mutex = New-Mutex -Name "MyMutex" -InitialOwner $true

		try {
			Enter-Mutex $Mutex 

			Exit-Mutex $Mutex 
		}
		finally {
			$Mutex.Dispose()
		}
	}
}

