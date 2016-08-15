Describe "ProcdumpTests" {
	BeforeAll {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}

	Context "DumpNotepad" {
		$TempPath = [System.IO.Path]::GetTempPath()

		$NotepadDmp = Join-Path $TempPath "Notepad.dmp"

		$Notepad = Start-Process Notepad -PassThru 
		$Notepad | Out-MiniDump -Path $NotepadDmp -Force

		$Notepad.Kill()

		$NotepadDmp | Should exist
	}
}
