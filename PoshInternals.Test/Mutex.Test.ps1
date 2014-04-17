TestFixture "MutexTest" {
	TestSetup {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}

	TestCase "Lock Mutex" {
		$Mutex = New-Mutex -Name "MyMutex" -InitialOwner $true

		try {
			Enter-Mutex $Mutex 

			Write-Host 'Ok'

			Exit-Mutex $Mutex 
		}
		finally {
			$Mutex.Dispose()
		}
	}
}

