Describe "Out-MiniDump" {
	. (Join-Path $PSScriptRoot 'InitializeTest.ps1')

	Context "notepad running and a dump is collected" {
		$TempPath = [System.IO.Path]::GetTempPath()

		$NotepadDmp = Join-Path $TempPath "Notepad.dmp"

		$Notepad = Start-Process Notepad -PassThru 
		$Notepad | Out-MiniDump -Path $NotepadDmp -Force

		$Notepad.Kill()

		It "Should exist" {
			$NotepadDmp | Should exist
		}
		
	}
}
