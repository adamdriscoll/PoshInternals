Describe "Interop" {
	. (Join-Path $PSScriptRoot 'InitializeTest.ps1')

	Context "ConvertTo-Object" {
		$time = New-Object System.Runtime.InteropServices.ComTypes.FILETIME
		$time.dwLowDateTime = 100

		$ptr = ConvertTo-Pointer $Time
		$time2 = ConvertTo-Object -Ptr $ptr -Type $Time.GetType()

		It "should marshal correctly" {
			$time2.dwLowDateTime | Should be 100
		}
		
	}
}