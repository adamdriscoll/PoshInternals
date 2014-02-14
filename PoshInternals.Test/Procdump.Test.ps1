TestFixture "ProcdumpTests" {
	TestSetup {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}

	TestCase "DumpNotepad" {
		$TempPath = [System.IO.Path]::GetTempPath()

		$NotepadDmp = Join-Path $TempPath "Notepad.dmp"

		$Notepad = Start-Process Notepad -PassThru 
		$Notepad | Out-MiniDump -Path $NotepadDmp -Force

		$Notepad.Kill()

		$NotepadDmp | Should exist
	}
}
