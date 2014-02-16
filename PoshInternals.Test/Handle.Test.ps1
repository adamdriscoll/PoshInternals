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

		sleep 1

		remove-item $TempFile

		$Handle | Should not be $null
	}

	TestCase "HandleUtil.GetHandles" {
		Measure-Command {  [PoshInternals.HandleUtil]::GetHandles() | Select Name,Type }
	}

	TestCase "Finds File" {
		Measure-Command { Get-Handle }
	}


}
