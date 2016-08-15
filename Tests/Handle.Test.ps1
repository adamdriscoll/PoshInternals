Describe "HandleTests" {
	BeforeAll {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}
	 
	Context "Finds Locked File" {
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

	Context "HandleUtil.GetHandles" {
		Measure-Command {  [PoshInternals.HandleUtil]::GetHandles() | Select Name,Type }
	}

	Context "Finds File" {
		Measure-Command { Get-Handle }
	}


}
