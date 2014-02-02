TestFixture "HandleTests" {
	TestSetup {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}

	TestCase "Finds Locked File" {
		$TempFile = [IO.Path]::GetTempPath()
		$TempFile = Join-Path $TempFile "TempFile.txt"
		$File = [IO.File]::Open($TempFile, 'OpenOrCreate', 'Write', 'None')

		$Handle = Get-Handle -Name $TempFile

		$File.Close()
		$File.Dispose()

		Start-Sleep 1

		Remove-Item $TempFile

		$Handle | Should not be $null
	}

	TestCase "Finds File" {
		Get-Handle | Where Type -EQ "File" 
	}
}
