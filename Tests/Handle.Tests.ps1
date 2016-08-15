Describe "Get-Handle"  {
	. (Join-Path $PSScriptRoot 'InitializeTest.ps1')
	 
	Context "File is locked" {
		$TempFile = [IO.Path]::GetTempFileName()
		$File = [IO.File]::Open($TempFile, 'OpenOrCreate', 'Write', 'None')

		try 
		{
			$Handle = Get-Handle -Name $TempFile
		}
		finally 
		{
			$File.Close()
			$File.Dispose()
		}
		
		sleep 10

		remove-item $TempFile -Force

		It "Finds open handle for file" {
			$Handle | Should not be $null
		}

		
	}

	Context "HandleUtil.GetHandles"  {
		#Measure-Command {  [PoshInternals.HandleUtil]::GetHandles() | Select Name,Type }
	}

	Context "Finds File" {
		#Measure-Command { Get-Handle }
	}


}
