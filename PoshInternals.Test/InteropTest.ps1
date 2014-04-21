TestFixture "InteropTest" {
	TestSetup {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}

	TestCase "ConvertToObjectTest" {
		$time = New-Object System.Runtime.InteropServices.ComTypes.FILETIME
		$time.dwLowDateTime = 100

		$ptr = ConvertTo-Pointer $Time
		$time2 = ConvertTo-Object -Ptr $ptr -Type $Time.GetType()

		$time2.dwLowDateTime | Should be 100
	}
}